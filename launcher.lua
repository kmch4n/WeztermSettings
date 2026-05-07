-- OS-aware launcher menu construction.
local wezterm = require("wezterm")

local M = {}

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

    -- WezTerm が検出した WSL distro も同じランチャーに追加します。
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
function M.build(is_windows, is_macos)
    local wsl_domains = {}
    local launch_menu = {}

    if is_windows then
        wsl_domains = wezterm.default_wsl_domains()
        launch_menu = build_windows_launch_menu(wsl_domains)
    elseif is_macos then
        append_posix_shell_launchers(launch_menu)
    end

    return wsl_domains, launch_menu
end

return M
