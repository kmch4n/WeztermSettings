-- 前回の tab / cwd だけを軽く保存・復元します。
-- 実行中プロセス、pane 分割、scrollback は復元対象にしません。
local M = {}

local STATE_VERSION = 1
local SAVE_INTERVAL_SECONDS = 15
local MAX_RESTORED_TABS_PER_WINDOW = 20

local last_save_at = 0
local restore_attempted = false

local function is_windows(wezterm)
    return wezterm.target_triple:find("windows", 1, true) ~= nil
end

local function state_directory(wezterm)
    if is_windows(wezterm) then
        local local_app_data = os.getenv("LOCALAPPDATA")
        if local_app_data and local_app_data ~= "" then
            return local_app_data .. "\\wezterm"
        end
    end

    local xdg_state_home = os.getenv("XDG_STATE_HOME")
    if xdg_state_home and xdg_state_home ~= "" then
        return xdg_state_home .. "/wezterm"
    end

    return wezterm.home_dir .. "/.local/state/wezterm"
end

local function state_path(wezterm)
    local separator = is_windows(wezterm) and "\\" or "/"
    return state_directory(wezterm) .. separator .. "session-state.json"
end

local function legacy_state_path(wezterm)
    return wezterm.config_dir .. "/session-state.json"
end

local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

local function write_file(path, content)
    local file = io.open(path, "w")
    if not file then
        return false
    end

    file:write(content)
    file:write("\n")
    file:close()
    return true
end

local function decode_uri_component(value)
    return value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

local function normalize_cwd_path(wezterm, path)
    if not path or path == "" then
        return nil
    end

    path = decode_uri_component(path)

    if is_windows(wezterm) then
        if path:match("^file:///[A-Za-z]:") then
            path = path:sub(9)
        elseif path:match("^file:/[A-Za-z]:") then
            path = path:sub(7)
        end

        if path:match("^/[A-Za-z]:[/\\]") then
            path = path:sub(2)
        end
    end

    return path
end

local function directory_exists(wezterm, path)
    path = normalize_cwd_path(wezterm, path)
    if not path then
        return false
    end

    local ok = pcall(function()
        wezterm.read_dir(path)
    end)

    return ok
end

local function cwd_to_path(wezterm, cwd)
    if not cwd then
        return nil
    end

    local ok, file_path = pcall(function()
        return cwd.file_path
    end)
    if ok and type(file_path) == "string" and file_path ~= "" then
        return normalize_cwd_path(wezterm, file_path)
    end

    local cwd_text = tostring(cwd)
    if not cwd_text or cwd_text == "" then
        return nil
    end

    if cwd_text:find("file:", 1, true) == 1 and wezterm.url and wezterm.url.parse then
        local parse_ok, parsed = pcall(wezterm.url.parse, cwd_text)
        if parse_ok and parsed and parsed.file_path and parsed.file_path ~= "" then
            return normalize_cwd_path(wezterm, parsed.file_path)
        end
    end

    return normalize_cwd_path(wezterm, cwd_text)
end

local function active_pane_for_tab(tab)
    for _, pane_info in ipairs(tab:panes_with_info()) do
        if pane_info.is_active then
            return pane_info.pane
        end
    end

    return tab:active_pane()
end

local function tab_state(wezterm, tab, index)
    local pane = active_pane_for_tab(tab)
    if not pane then
        return nil
    end

    local cwd = cwd_to_path(wezterm, pane:get_current_working_dir())
    if not directory_exists(wezterm, cwd) then
        return nil
    end

    local title = tab:get_title()
    if title == "" then
        title = nil
    end

    return {
        index = index,
        cwd = cwd,
        title = title,
    }
end

local function collect_session_state(wezterm)
    local windows = {}

    for _, mux_window in ipairs(wezterm.mux.all_windows()) do
        local tabs = {}
        local active_tab_index = 0

        for _, tab_info in ipairs(mux_window:tabs_with_info()) do
            if tab_info.is_active then
                active_tab_index = tab_info.index
            end

            local state = tab_state(wezterm, tab_info.tab, tab_info.index)
            if state then
                table.insert(tabs, state)
            end
        end

        if #tabs > 0 then
            table.insert(windows, {
                workspace = mux_window:get_workspace(),
                active_tab_index = active_tab_index,
                tabs = tabs,
            })
        end
    end

    if #windows == 0 then
        return nil
    end

    return {
        version = STATE_VERSION,
        saved_at = os.time(),
        windows = windows,
    }
end

local function load_state(wezterm)
    local content = read_file(state_path(wezterm))
    if not content or content == "" then
        content = read_file(legacy_state_path(wezterm))
    end

    if not content or content == "" then
        return nil
    end

    local ok, state = pcall(wezterm.json_parse, content)
    if not ok or type(state) ~= "table" or state.version ~= STATE_VERSION then
        return nil
    end

    if type(state.windows) ~= "table" or #state.windows == 0 then
        return nil
    end

    return state
end

function M.save(wezterm)
    local state = collect_session_state(wezterm)
    if not state then
        return false
    end

    local ok, json = pcall(wezterm.json_encode, state)
    if not ok or not json then
        return false
    end

    return write_file(state_path(wezterm), json)
end

local function restorable_tabs(wezterm, window_state)
    local tabs = {}

    if type(window_state.tabs) ~= "table" then
        return tabs
    end

    for _, tab in ipairs(window_state.tabs) do
        if #tabs >= MAX_RESTORED_TABS_PER_WINDOW then
            break
        end

        local cwd = nil
        if type(tab) == "table" then
            cwd = normalize_cwd_path(wezterm, tab.cwd)
        end

        if cwd and directory_exists(wezterm, cwd) then
            table.insert(tabs, {
                cwd = cwd,
                title = tab.title,
                index = tab.index,
            })
        end
    end

    table.sort(tabs, function(left, right)
        return (left.index or 0) < (right.index or 0)
    end)

    return tabs
end

local function set_tab_title(tab, title)
    if type(title) == "string" and title ~= "" then
        tab:set_title(title)
    end
end

local function restore_window(wezterm, mux, window_state)
    local tabs = restorable_tabs(wezterm, window_state)
    if #tabs == 0 then
        return false
    end

    local workspace = window_state.workspace or "default"
    local first_tab, _, mux_window = mux.spawn_window({
        workspace = workspace,
        cwd = tabs[1].cwd,
    })
    set_tab_title(first_tab, tabs[1].title)

    local restored_tabs = { first_tab }
    for index = 2, #tabs do
        local tab = mux_window:spawn_tab({
            cwd = tabs[index].cwd,
        })
        set_tab_title(tab, tabs[index].title)
        table.insert(restored_tabs, tab)
    end

    local active_tab = nil
    for index, tab_state_entry in ipairs(tabs) do
        if tab_state_entry.index == window_state.active_tab_index then
            active_tab = restored_tabs[index]
            break
        end
    end

    if active_tab then
        active_tab:activate()
    end

    return true
end

function M.restore_on_startup(wezterm, cmd)
    if restore_attempted then
        return false
    end
    restore_attempted = true

    if cmd and ((cmd.args and #cmd.args > 0) or cmd.cwd) then
        return false
    end

    local state = load_state(wezterm)
    if not state then
        return false
    end

    local restored = false
    local mux = wezterm.mux
    for _, window_state in ipairs(state.windows) do
        if restore_window(wezterm, mux, window_state) then
            restored = true
        end
    end

    if restored then
        M.save(wezterm)
    end

    return restored
end

function M.save_periodically(wezterm)
    local now = os.time()
    if now - last_save_at < SAVE_INTERVAL_SECONDS then
        return false
    end

    last_save_at = now
    return M.save(wezterm)
end

function M.path(wezterm)
    return state_path(wezterm)
end

return M
