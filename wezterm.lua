-- WezTerm の API を読み込みます。
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

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

    if title == "powershell.exe" or title == "pwsh.exe" or title == "Windows PowerShell" then
        return "Terminal"
    end

    return title
end

-- タブバーの表示名を整えます。
wezterm.on("format-tab-title", function(tab)
    return get_tab_title(tab)
end)

local function build_startup_spawn_command(cmd, cwd)
    local spawn = {
        cwd = cwd,
    }

    if cmd and cmd.args then
        spawn.args = cmd.args
    end

    return spawn
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

-- WezTerm を起動したとき、最初のウィンドウに 2 つのタブを開きます。
-- 1 つ目のタブ名は Dev、2 つ目のタブ名は Agent に固定します。
wezterm.on("gui-startup", function(cmd)
    local spawn = build_startup_spawn_command(cmd, config.default_cwd)
    local dev_tab, _, window = mux.spawn_window(spawn)
    dev_tab:set_title("Dev")

    local agent_tab, _, _ = window:spawn_tab({
        cwd = config.default_cwd,
    })
    agent_tab:set_title("Agent")
end)

----------------------------------------------------
-- Reference
----------------------------------------------------

-- docs/README.md に、このリポジトリの設定方針と公式リファレンスへの導線をまとめています。

----------------------------------------------------
-- Startup
----------------------------------------------------

-- 設定ファイルを保存したら、自動で再読み込みします。
config.automatically_reload_config = true

-- 新しく開くターミナルでは Windows PowerShell を起動し、起動バナーは表示しません。
config.default_prog = { "pwsh.exe", "-NoLogo" }

-- 起動時の作業ディレクトリは local.lua 側で上書きできます。
if not config.default_cwd then
    config.default_cwd = wezterm.home_dir
end

-- タブ番号の接頭辞を消し、名前だけをタブバーに表示します。
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
        key = "c",
        mods = "CTRL",
        action = wezterm.action_callback(copy_if_selected_or_send_ctrl_c),
    },
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
