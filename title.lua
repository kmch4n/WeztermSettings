-- Tab title formatting and process/context display helpers.
local wezterm = require("wezterm")

local M = {}

-- タブに明示的な名前が付いていればそれを優先し、
-- 付いていないタブで OS ごとの既定 shell 名が見えている場合は
-- タブバー上では Terminal という名前に置き換えます。
-- AI CLI が動いている場合は、その CLI 名を表示します。
local generic_shell_titles = {
    ["windows powershell"] = true,
    ["powershell.exe"] = true,
    ["pwsh.exe"] = true,
    ["cmd.exe"] = true,
    ["zsh"] = true,
    ["-zsh"] = true,
    ["bash"] = true,
    ["-bash"] = true,
    ["sh"] = true,
    ["-sh"] = true,
    ["fish"] = true,
    ["-fish"] = true,
}

local cli_title_names = {
    ["codex"] = "Codex",
    ["codex.exe"] = "Codex",
    ["claude"] = "ClaudeCode",
    ["claude.exe"] = "ClaudeCode",
}

local cli_title_ai_cli_names = {
    ["codex"] = "codex",
    ["codex.exe"] = "codex",
    ["claude"] = "claude",
    ["claude.exe"] = "claude",
}

local ai_cli_display_names = {
    codex = "Codex",
    claude = "ClaudeCode",
}

local ai_cli_user_vars = {
    ["codex"] = "codex",
    ["claude"] = "claude",
    ["claude-code"] = "claude",
}

local tab_context_display_names = {
    expo = "Expo",
}

local tab_context_user_vars = {
    ["expo"] = "expo",
}

local MAX_TAB_CWD_COLUMNS = 24

local function user_vars_ai_cli_name(vars)
    if not vars then
        return nil
    end

    local ai_cli = vars.AI_CLI
    if not ai_cli or ai_cli == "" then
        return nil
    end

    return ai_cli_user_vars[ai_cli:lower()]
end

local function user_vars_tab_context_name(vars)
    if not vars then
        return nil
    end

    local tab_context = vars.TAB_CONTEXT
    if not tab_context or tab_context == "" then
        return nil
    end

    return tab_context_user_vars[tab_context:lower()]
end

local function decode_uri_component(value)
    return value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

local function cwd_basename(cwd)
    if not cwd then
        return nil
    end

    local path = nil
    local ok, file_path = pcall(function()
        return cwd.file_path
    end)

    if ok and type(file_path) == "string" and file_path ~= "" then
        path = file_path
    else
        path = tostring(cwd)
    end

    if not path or path == "" then
        return nil
    end

    path = decode_uri_component(path)
    path = path:gsub("[/\\]+$", "")

    local name = path:match("([^/\\]+)$")
    if not name or name == "" then
        return nil
    end

    return wezterm.truncate_right(name, MAX_TAB_CWD_COLUMNS)
end

local function tab_context_cwd_name(vars)
    if not vars then
        return nil
    end

    local cwd_name = vars.TAB_CONTEXT_CWD_NAME
    if not cwd_name or cwd_name == "" then
        return nil
    end

    return wezterm.truncate_right(cwd_name, MAX_TAB_CWD_COLUMNS)
end

local function titled_context_tab_title(display_name, active_pane, cwd_name)
    if not cwd_name then
        cwd_name = cwd_basename(active_pane.current_working_dir)
    end

    if not cwd_name then
        return display_name
    end

    return display_name .. " - " .. cwd_name
end

local function ai_cli_tab_title(ai_cli_name, active_pane)
    local display_name = ai_cli_display_names[ai_cli_name] or "Terminal"
    return titled_context_tab_title(display_name, active_pane)
end

local function tab_context_title(tab_context_name, active_pane)
    local display_name = tab_context_display_names[tab_context_name] or "Terminal"
    local cwd_name = tab_context_cwd_name(active_pane.user_vars)
    return titled_context_tab_title(display_name, active_pane, cwd_name)
end

function M.get(tab_info)
    local title = tab_info.tab_title

    if title and #title > 0 then
        return title
    end

    local ai_cli_name = user_vars_ai_cli_name(tab_info.active_pane.user_vars)
    if ai_cli_name then
        return ai_cli_tab_title(ai_cli_name, tab_info.active_pane)
    end

    local tab_context_name = user_vars_tab_context_name(tab_info.active_pane.user_vars)
    if tab_context_name then
        return tab_context_title(tab_context_name, tab_info.active_pane)
    end

    title = tab_info.active_pane.title
    if not title or title == "" then
        return "Terminal"
    end

    local normalized_title = title:lower()

    if generic_shell_titles[normalized_title] then
        return "Terminal"
    end

    if cli_title_names[normalized_title] then
        local title_ai_cli_name = cli_title_ai_cli_names[normalized_title]
        if title_ai_cli_name then
            return ai_cli_tab_title(title_ai_cli_name, tab_info.active_pane)
        end
        return cli_title_names[normalized_title]
    end

    return title
end

function M.apply()
    -- タブバーの表示名を整えます。
    wezterm.on("format-tab-title", function(tab)
        return M.get(tab)
    end)
end

return M
