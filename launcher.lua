-- OS-aware launcher menu construction.
local wezterm = require("wezterm")

local M = {}

-- WSL distro の検出結果を保存するキャッシュファイル名です。
local WSL_CACHE_FILENAME = "wsl-domains.json"

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

-- キャッシュの置き場所は session.lua と同じ規約に揃えます。
local function state_directory()
    if wezterm.target_triple:find("windows", 1, true) ~= nil then
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

local function wsl_cache_path()
    local separator = wezterm.target_triple:find("windows", 1, true) ~= nil and "\\" or "/"
    return state_directory() .. separator .. WSL_CACHE_FILENAME
end

-- WslDomain をプレーンな table に写し取ります。
-- json_encode に渡せる形へ正規化し、未知のフィールドは持ち込みません。
local function to_plain_domain(domain)
    if type(domain) ~= "table" or not domain.name then
        return nil
    end

    return {
        name = domain.name,
        distribution = domain.distribution,
        username = domain.username,
        default_cwd = domain.default_cwd,
        default_prog = domain.default_prog,
    }
end

-- キャッシュ済みの WSL distro 一覧を読み込みます。
-- 破損・欠損時は空リストを返し、起動を止めません。
local function read_cached_wsl_domains()
    local file = io.open(wsl_cache_path(), "r")
    if not file then
        return {}
    end

    local content = file:read("*a")
    file:close()

    if not content or content == "" then
        return {}
    end

    local ok, parsed = pcall(wezterm.json_parse, content)
    if not ok or type(parsed) ~= "table" or type(parsed.domains) ~= "table" then
        return {}
    end

    local domains = {}
    for _, domain in ipairs(parsed.domains) do
        local plain = to_plain_domain(domain)
        if plain then
            table.insert(domains, plain)
        end
    end

    return domains
end

local function write_cached_wsl_domains(domains)
    local ok, encoded = pcall(wezterm.json_encode, { domains = domains })
    if not ok then
        return false
    end

    local file = io.open(wsl_cache_path(), "w")
    if not file then
        return false
    end

    file:write(encoded)
    file:write("\n")
    file:close()
    return true
end

-- F3 ランチャーに表示する起動候補を作ります。
-- Windows では PowerShell / cmd / WSL をまとめて選べるようにします。
local function build_windows_launch_menu(wsl_domains)
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

    -- キャッシュ済みの WSL distro も同じランチャーに追加します。
    for _, domain in ipairs(wsl_domains) do
        table.insert(launch_menu, {
            label = domain.name,
            domain = { DomainName = domain.name },
        })
    end

    return launch_menu
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

-- OS ごとにランチャー候補を組み立てます。
--
-- Windows では wezterm.default_wsl_domains() をここで呼びません。
-- あの API は内部で wsl.exe を同期実行するため、WSL のサービスが
-- 応答しなくなると設定のロード自体が永久にブロックし、
-- ウィンドウが一度も表示されないまま WezTerm が起動不能になります。
-- 起動時はキャッシュだけを読み、検出は refresh_wsl_domains() で明示的に行います。
function M.build(is_windows, is_macos)
    local wsl_domains = {}
    local launch_menu = {}

    if is_windows then
        wsl_domains = read_cached_wsl_domains()
        launch_menu = build_windows_launch_menu(wsl_domains)
    elseif is_macos then
        append_posix_shell_launchers(launch_menu)
    end

    return wsl_domains, launch_menu
end

-- WSL distro を検出し直してキャッシュへ書き込みます。
-- wsl.exe を同期実行するので、WSL が応答しないと UI が固まります。
-- そのため起動時ではなく、ユーザーが明示的に呼んだときだけ実行します。
function M.refresh_wsl_domains(window)
    local function notify(message)
        if window then
            window:toast_notification("WezTerm", message, nil, 4000)
        end
        wezterm.log_info("wsl-domains: " .. message)
    end

    local ok, detected = pcall(wezterm.default_wsl_domains)
    if not ok or type(detected) ~= "table" then
        notify("WSL distro の検出に失敗しました")
        return false
    end

    local domains = {}
    for _, domain in ipairs(detected) do
        local plain = to_plain_domain(domain)
        if plain then
            table.insert(domains, plain)
        end
    end

    if not write_cached_wsl_domains(domains) then
        notify("WSL distro のキャッシュ書き込みに失敗しました")
        return false
    end

    notify(string.format("WSL distro を %d 件キャッシュしました。設定を再読み込みします。", #domains))
    return true
end

return M
