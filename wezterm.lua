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

----------------------------------------------------
-- Events
----------------------------------------------------

-- タブに明示的な名前が付いていればそれを優先し、
-- 付いていないタブで PowerShell 系の既定タイトルが見えている場合は
-- タブバー上では Terminal という名前に置き換えます。
local function get_tab_title(tab_info)
    local title = tab_info.tab_title

    if title and #title > 0 then
        return title
    end

    title = tab_info.active_pane.title

    local normalized_title = title:lower()

    if normalized_title == "windows powershell"
        or normalized_title:find("powershell.exe", 1, true)
        or normalized_title:find("pwsh.exe", 1, true)
        or normalized_title:find("cmd.exe", 1, true)
        or normalized_title:find("codex.exe", 1, true)
    then
        return "Terminal"
    end

    return title
end

-- タブバーの表示名を整えます。
wezterm.on("format-tab-title", function(tab)
    return get_tab_title(tab)
end)

local function build_launch_menu(wsl_domains)
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

local wsl_domains = wezterm.default_wsl_domains()

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

-- 新しく開くターミナルでは Windows PowerShell を起動し、起動バナーは表示しません。
config.default_prog = { "pwsh.exe", "-NoLogo" }

-- 起動時の作業ディレクトリは local.lua 側で上書きできます。
if not config.default_cwd then
    config.default_cwd = wezterm.home_dir
end

-- タブ番号の接頭辞を消し、名前だけをタブバーに表示します。
config.wsl_domains = wsl_domains
config.launch_menu = build_launch_menu(wsl_domains)
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

-- 新しく開くウィンドウの初期横幅を、文字数ベースで 120 桁にします。
config.initial_cols = 120

-- 新しく開くウィンドウの初期高さを、文字数ベースで 28 行にします。
config.initial_rows = 28

-- タイトルバーを消し、ウィンドウ操作ボタンはタブバー側へ統合します。
-- これにより、上部の「cmd.exe」表示をなくしつつ、閉じる・最小化・最大化は維持します。
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- タイトルバー上のボタンは Windows 風の見た目を使います。
config.integrated_title_button_style = "Windows"

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
