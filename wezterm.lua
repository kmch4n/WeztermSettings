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

local ai_cli_display_names = {
    codex = "Codex",
    claude = "ClaudeCode",
}

local ai_cli_user_vars = {
    ["codex"] = "codex",
    ["claude"] = "claude",
    ["claude-code"] = "claude",
}

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

local function get_tab_title(tab_info)
    local title = tab_info.tab_title

    if title and #title > 0 then
        return title
    end

    local ai_cli_name = user_vars_ai_cli_name(tab_info.active_pane.user_vars)
    if ai_cli_name then
        return ai_cli_display_names[ai_cli_name] or "Terminal"
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
        return cli_title_names[normalized_title]
    end

    return title
end

-- タブバーの表示名を整えます。
wezterm.on("format-tab-title", function(tab)
    return get_tab_title(tab)
end)

-- F3 ランチャーに表示する起動候補を作ります。
-- Windows では PowerShell / cmd / WSL をまとめて選べるようにします。
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

    -- WezTerm が検出した WSL distro も同じランチャーに追加します。
    for _, domain in ipairs(wsl_domains) do
        table.insert(launch_menu, {
            label = domain.name,
            domain = { DomainName = domain.name },
        })
    end

    return launch_menu
end

-- Ctrl + C は、選択範囲がある時だけコピーとして扱います。
-- 選択がない時は通常通りターミナルへ Ctrl+C を送ります。
local function copy_if_selected_or_send_ctrl_c(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ""

    if has_selection then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
        return
    end

    window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
end

-- 右クリックは、選択中ならコピー、未選択なら貼り付けにします。
-- Windows Terminal に近い操作感に寄せるための補助関数です。
local function copy_if_selected_or_paste(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ""

    if has_selection then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
        return
    end

    window:perform_action(act.PasteFrom("Clipboard"), pane)
end

-- 実行ファイルのパスからファイル名だけを取り出します。
-- Windows と POSIX の両方の区切り文字に対応します。
local function basename(path)
    if not path or path == "" then
        return nil
    end

    return path:match("([^/\\]+)$")
end

-- macOS / Linux の shell 候補をランチャーに出す前に、
-- 実際にそのファイルが存在するかを確認します。
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

-- macOS / Linux では SHELL と代表的な shell をランチャーへ追加します。
-- 同じ起動コマンドが重複しないように seen_args で管理します。
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

-- process info から、Codex / Claude Code のどちらが実行中か判定します。
-- 実行ファイル名だけでなく、Node.js 経由の argv も見ます。
local function process_ai_cli_name(info)
    local exe = basename(info.executable)
    if exe then
        exe = exe:lower()
        if exe == "codex" or exe == "codex.exe" then
            return "codex"
        end
        if exe == "claude" or exe == "claude.exe" then
            return "claude"
        end
    end

    -- npm CLI は node 経由で起動される場合があるため、
    -- argv 側の package path も見て判定する。
    if info.argv then
        for _, arg in ipairs(info.argv) do
            local lower = arg:lower()
            if lower:find("@openai/codex", 1, true)
                or lower:find("codex.js", 1, true) then
                return "codex"
            end
            if lower:find("claude-code", 1, true)
                or lower:find("@anthropic-ai", 1, true) then
                return "claude"
            end
        end
    end

    return nil
end

-- PowerShell profile などから AI_CLI user var が設定されている場合は、
-- process tree よりもその明示的な状態を優先します。
local function user_var_ai_cli_name(pane)
    return user_vars_ai_cli_name(pane:get_user_vars())
end

-- 判定結果を pane 単位で短時間だけキャッシュし、
-- Windows ConPTY 側で foreground や祖先の取得が一時的に失敗したときに、
-- 直前の確定結果をフォールバックとして再利用するための入れ物です。
local ai_cli_detection_cache = {}
local AI_CLI_DETECTION_TTL_SECONDS = 2

local function remember_ai_cli_detection(pane_id, result)
    ai_cli_detection_cache[pane_id] = {
        result = result,
        at = os.time(),
    }
end

local function recall_ai_cli_detection(pane_id)
    local entry = ai_cli_detection_cache[pane_id]
    if not entry then
        return nil
    end
    if os.time() - entry.at > AI_CLI_DETECTION_TTL_SECONDS then
        return nil
    end
    return entry.result
end

-- AI CLI は MCP サーバーなど複数の子プロセスを同時に抱える。
-- Windows の ConPTY には tty foreground の概念がないため、
-- pane:get_foreground_process_info() は一番奥の子孫 (= MCP サーバー)
-- を返すことがある。ppid を辿り、祖先に Codex / Claude Code があれば
-- AI CLI が動いているとみなす。
-- 祖先取得や foreground 取得が失敗した場合は、直近 2 秒以内に得た
-- 確定結果を再利用することで、一過性の取得失敗による誤判定を防ぐ。
local function current_ai_cli_name(pane)
    local pane_id = pane:pane_id()
    local user_var_cli = user_var_ai_cli_name(pane)

    if user_var_cli then
        remember_ai_cli_detection(pane_id, user_var_cli)
        return user_var_cli
    end

    local info = pane:get_foreground_process_info()

    if info == nil then
        local cached = recall_ai_cli_detection(pane_id)
        if cached ~= nil then
            return cached
        end
        return nil
    end

    local depth = 0
    while info and depth < 16 do
        local cli_name = process_ai_cli_name(info)
        if cli_name then
            remember_ai_cli_detection(pane_id, cli_name)
            return cli_name
        end
        if not info.ppid or info.ppid <= 0 then
            remember_ai_cli_detection(pane_id, false)
            return nil
        end
        local parent = wezterm.procinfo.get_info_for_pid(info.ppid)
        if parent == nil then
            -- 祖先取得の失敗は不確定として扱い、直近の判定があればそれを優先する。
            local cached = recall_ai_cli_detection(pane_id)
            if cached ~= nil then
                return cached
            end
            return nil
        end
        info = parent
        depth = depth + 1
    end

    -- depth 上限に到達した場合も不確定として扱う。
    local cached = recall_ai_cli_detection(pane_id)
    if cached ~= nil then
        return cached
    end
    return nil
end

-- 現在の pane が AI CLI なら CLI ごとの専用入力を送り、
-- それ以外なら通常キーを送ります。
-- Enter と Ctrl+Enter の入れ替えをこの関数に集約しています。
local function send_key_for_current_process(window, pane, cli_keys, default_key, default_mods)
    local cli_name = current_ai_cli_name(pane)
    local cli_key = cli_name and cli_keys[cli_name] or nil

    if cli_key then
        if cli_key.action then
            window:perform_action(cli_key.action, pane)
            return
        end

        window:perform_action(act.SendKey({
            key = cli_key.key,
            mods = cli_key.mods,
        }), pane)
        return
    end

    window:perform_action(act.SendKey({
        key = default_key,
        mods = default_mods,
    }), pane)
end

-- OS ごとにランチャー候補を組み立てます。
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
    -- Enter は、Codex では通常の Enter のまま送ります。
    -- Claude Code では Ctrl+J として送ります。
    {
        key = "Enter",
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            send_key_for_current_process(window, pane, {
                claude = { key = "j", mods = "CTRL" },
            }, "Enter", "NONE")
        end),
    },
    -- Ctrl+Enter は、Codex の時だけ F12 として送ります。
    -- それ以外では Ctrl+Enter をそのままアプリケーションへ渡します。
    {
        key = "Enter",
        mods = "CTRL",
        action = wezterm.action_callback(function(window, pane)
            send_key_for_current_process(window, pane, {
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
        action = wezterm.action_callback(copy_if_selected_or_send_ctrl_c),
    },
    { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

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
