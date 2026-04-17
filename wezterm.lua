-- WezTerm の API を読み込みます。
local wezterm = require("wezterm")
local act = wezterm.action

-- 設定を書き込むためのオブジェクトを作成します。
local config = wezterm.config_builder()

-- local.lua が存在する場合は、環境依存の設定で上書きします。
local ok, local_config = pcall(require, "local")
if ok and type(local_config) == "table" then
    for key, value in pairs(local_config) do
        config[key] = value
    end
end

local target_triple = wezterm.target_triple
local is_windows = target_triple:find("windows", 1, true) ~= nil
local is_macos = target_triple:find("darwin", 1, true) ~= nil

----------------------------------------------------
-- Events
----------------------------------------------------

-- タブに明示的な名前が付いていればそれを優先し、
-- 付いていないタブで OS ごとの既定 shell 名が見えている場合は
-- タブバー上では Terminal という名前に置き換えます。
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

local generic_cli_titles = {
    ["codex"] = true,
    ["codex.exe"] = true,
    ["claude"] = true,
    ["claude.exe"] = true,
}

local function get_tab_title(tab_info)
    local title = tab_info.tab_title

    if title and #title > 0 then
        return title
    end

    title = tab_info.active_pane.title
    if not title or title == "" then
        return "Terminal"
    end

    local normalized_title = title:lower()

    if generic_shell_titles[normalized_title] or generic_cli_titles[normalized_title] then
        return "Terminal"
    end

    return title
end

-- タブバーの表示名を整えます。
wezterm.on("format-tab-title", function(tab)
    return get_tab_title(tab)
end)

local function build_launch_menu(wsl_domains)
    if not is_windows then
        return {}
    end

    local launch_menu = {
        {
            label = "PowerShell 7",
            domain = { DomainName = "local" },
            args = { "pwsh.exe", "-NoLogo" },
        },
        {
            label = "Windows PowerShell",
            domain = { DomainName = "local" },
            args = { "powershell.exe", "-NoLogo" },
        },
        {
            label = "Command Prompt",
            domain = { DomainName = "local" },
            args = { "cmd.exe" },
        },
    }

    for _, domain in ipairs(wsl_domains) do
        table.insert(launch_menu, {
            label = domain.name,
            domain = { DomainName = domain.name },
        })
    end

    return launch_menu
end

local function copy_if_selected_or_send_ctrl_c(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ""

    if has_selection then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
        return
    end

    window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
end

local function copy_if_selected_or_paste(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ""

    if has_selection then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
        return
    end

    window:perform_action(act.PasteFrom("Clipboard"), pane)
end

local function basename(path)
    if not path or path == "" then
        return nil
    end

    return path:match("([^/\\]+)$")
end

local function file_exists(path)
    if not path or path == "" then
        return false
    end

    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end

    return false
end

local function append_posix_shell_launchers(launch_menu)
    local login_shell = os.getenv("SHELL")
    local seen_args = {}

    local function add_shell(path, label)
        if not file_exists(path) then
            return
        end

        local key = path .. "\0-l"
        if seen_args[key] then
            return
        end

        seen_args[key] = true
        table.insert(launch_menu, {
            label = label,
            args = { path, "-l" },
        })
    end

    if login_shell and login_shell ~= "" then
        local shell_name = basename(login_shell) or "Login Shell"
        add_shell(login_shell, shell_name .. " (login)")
    end

    add_shell("/bin/zsh", "zsh")
    add_shell("/bin/bash", "bash")
    add_shell("/bin/sh", "sh")
end

local function is_ai_cli_process(pane)
    local process_name = basename(pane:get_foreground_process_name())
    if not process_name then
        return false
    end

    process_name = process_name:lower()

    return process_name == "codex"
        or process_name == "codex.exe"
        or process_name == "claude"
        or process_name == "claude.exe"
end

local function send_key_for_current_process(window, pane, ai_key, ai_mods, default_key, default_mods)
    local target_key = default_key
    local target_mods = default_mods

    if is_ai_cli_process(pane) then
        target_key = ai_key
        target_mods = ai_mods
    end

    window:perform_action(act.SendKey({
        key = target_key,
        mods = target_mods,
    }), pane)
end

local wsl_domains = {}
local launch_menu = {}

if is_windows then
    wsl_domains = wezterm.default_wsl_domains()
    launch_menu = build_launch_menu(wsl_domains)
elseif is_macos then
    append_posix_shell_launchers(launch_menu)
end

----------------------------------------------------
-- Reference
----------------------------------------------------

-- docs/README.md に、このリポジトリの設定方針と公式リファレンスへの導線をまとめています。

----------------------------------------------------
-- Startup
----------------------------------------------------

-- 設定ファイルを保存したら、自動で再読み込みします。
config.automatically_reload_config = true

-- ウィンドウを閉じる際の確認ダイアログを表示しません。
config.window_close_confirmation = "NeverPrompt"

-- Windows では新しく開くターミナルに PowerShell 7 を使います。
-- macOS では WezTerm 既定の login shell 起動に任せます。
if is_windows then
    config.default_prog = { "pwsh.exe", "-NoLogo" }
end

-- 起動時の作業ディレクトリは local.lua 側で上書きできます。
if not config.default_cwd then
    config.default_cwd = wezterm.home_dir
end

-- タブ番号の接頭辞を消し、名前だけをタブバーに表示します。
if is_windows then
    config.wsl_domains = wsl_domains
end
config.launch_menu = launch_menu
config.scrollback_lines = 10000
config.switch_to_last_active_tab_when_closing_tab = true
config.show_tab_index_in_tab_bar = false

----------------------------------------------------
-- Keys
----------------------------------------------------

-- Ctrl + 左矢印で左隣のタブへ移動します。
-- Ctrl + 右矢印で右隣のタブへ移動します。
config.keys = {
    { key = "LeftArrow", mods = "CTRL", action = act.ActivateTabRelative(-1) },
    { key = "RightArrow", mods = "CTRL", action = act.ActivateTabRelative(1) },
    {
        key = "Enter",
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            send_key_for_current_process(window, pane, "j", "CTRL", "Enter", "NONE")
        end),
    },
    {
        key = "Enter",
        mods = "CTRL",
        action = wezterm.action_callback(function(window, pane)
            send_key_for_current_process(window, pane, "Enter", "NONE", "Enter", "CTRL")
        end),
    },
    {
        key = "F3",
        mods = "NONE",
        action = act.ShowLauncherArgs({
            flags = "FUZZY|LAUNCH_MENU_ITEMS|TABS|WORKSPACES|DOMAINS",
        }),
    },
    {
        key = "c",
        mods = "CTRL",
        action = wezterm.action_callback(copy_if_selected_or_send_ctrl_c),
    },
    { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = act.Nop,
    },
    {
        event = { Up = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = wezterm.action_callback(copy_if_selected_or_paste),
    },
}

----------------------------------------------------
-- Window
----------------------------------------------------

-- 新しく開くウィンドウの初期横幅は local.lua 側で上書きできます。
if not config.initial_cols then
    config.initial_cols = 120
end

-- 新しく開くウィンドウの初期高さは local.lua 側で上書きできます。
if not config.initial_rows then
    config.initial_rows = 28
end

-- タイトルバーを消し、ウィンドウ操作ボタンはタブバー側へ統合します。
-- これにより、上部の「cmd.exe」表示をなくしつつ、閉じる・最小化・最大化は維持します。
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- タイトルバー上のボタンは OS に合わせた見た目を使います。
if is_macos then
    config.integrated_title_button_alignment = "Left"
    config.integrated_title_button_style = "MacOsNative"
else
    config.integrated_title_button_style = "Windows"
end

----------------------------------------------------
-- Appearance
----------------------------------------------------

-- ターミナルで使うフォントサイズを 10 に設定します。
config.font_size = 10

-- 背景を少しだけ透過し、うっすら背後が見えるようにします。
config.window_background_opacity = 0.96

-- カラースキームに Tokyo Night を使用します。
config.color_scheme = "Tokyo Night"

-- 定義した設定を WezTerm に返します。
return config
