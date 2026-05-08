-- WezTerm の API を読み込みます。
local wezterm = require("wezterm")
local act = wezterm.action

local ai_cli = require("ai_cli")
local clipboard = require("clipboard")
local launcher = require("launcher")
local session = require("session")
local title = require("title")

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
local wsl_domains, launch_menu = launcher.build(is_windows, is_macos)

----------------------------------------------------
-- Events
----------------------------------------------------

title.apply()

-- 前回保存された tab / cwd だけを GUI 起動時に復元します。
-- コマンドや実行中プロセスは再実行しません。
wezterm.on("gui-startup", function(cmd)
    if not session.restore_on_startup(wezterm, cmd) then
        wezterm.mux.spawn_window(cmd or {})
    end
end)

-- 終了直前イベントに依存せず、定期的に軽量 snapshot を保存します。
wezterm.on("update-status", function()
    session.save_periodically(wezterm)
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

-- ウィンドウを閉じる際の確認ダイアログを表示しません。
config.window_close_confirmation = "NeverPrompt"

-- Windows では OpenSSH の ssh-agent を使うため、WezTerm 側の
-- SSH_AUTH_SOCK 注入を止めます。
if is_windows then
    config.mux_enable_ssh_agent = false
end

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
    -- Ctrl+Enter は、Codex の時だけ F12 として送ります。
    -- それ以外では Ctrl+Enter をそのままアプリケーションへ渡します。
    {
        key = "Enter",
        mods = "CTRL",
        action = wezterm.action_callback(function(window, pane)
            ai_cli.send_key_for_current_process(window, pane, {
                codex = { key = "F12", mods = "NONE" },
                claude = { key = "Enter", mods = "NONE" },
            }, "Enter", "CTRL")
        end),
    },
    -- F3 でタブ、ワークスペース、ドメイン、起動メニューを横断検索します。
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
        action = wezterm.action_callback(clipboard.copy_if_selected_or_send_ctrl_c),
    },
    { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

-- macOS では IME の変換確定 Enter と通常 Enter の区別が難しいため、
-- Enter 単体は WezTerm 側で捕まえず、アプリケーションへ直接渡します。
-- Windows では従来どおり Claude Code 向けの Enter 入れ替えを維持します。
if not is_macos then
    table.insert(config.keys, 3, {
        key = "Enter",
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            ai_cli.send_key_for_current_process(window, pane, {
                claude = { key = "j", mods = "CTRL" },
            }, "Enter", "NONE")
        end),
    })
end

-- 右クリックの Down では何もせず、Up のタイミングでコピー/貼り付けを判定します。
-- Down で処理すると選択操作と衝突しやすいためです。
config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = act.Nop,
    },
    {
        event = { Up = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = wezterm.action_callback(clipboard.copy_if_selected_or_paste),
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
