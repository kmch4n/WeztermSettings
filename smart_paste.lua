-- Paste clipboard images as temporary file paths.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local target_triple = wezterm.target_triple
local is_windows = target_triple:find("windows", 1, true) ~= nil
local is_macos = target_triple:find("darwin", 1, true) ~= nil

-- macOS の /tmp は再起動時に OS が片付けるため、そのまま置き場所に使います。
local MACOS_PASTE_DIR = "/tmp/wezterm-clipboard-images"

-- Windows ではクリップボードの判定と PNG 保存を 1 回の PowerShell で済ませます。
-- テキストがあれば何も出力せず、画像だけのときに保存先パスを出力します。
-- Excel のセルのように text と画像を同時に持つ場合は、テキストを優先します。
local WINDOWS_SAVE_SCRIPT = [[
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
if ([Windows.Forms.Clipboard]::ContainsText()) { exit 0 }
if (-not [Windows.Forms.Clipboard]::ContainsImage()) { exit 0 }
$dir = Join-Path $env:TEMP 'wezterm-clipboard-images'
[void](New-Item -ItemType Directory -Force -Path $dir)
$name = 'paste-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.png'
$path = Join-Path $dir $name
$image = [Windows.Forms.Clipboard]::GetImage()
try { $image.Save($path, [Drawing.Imaging.ImageFormat]::Png) } finally { $image.Dispose() }
[Console]::Out.Write($path)
]]

-- Windows の %TEMP% はシャットダウンでは消えないため、
-- 現在のログオンより前 (= 前回シャットダウン前) に保存した画像を削除します。
-- 高速スタートアップでは LastBootUpTime が更新されないので、
-- 同じセッションの explorer.exe の起動時刻をログオン時刻として使います。
local WINDOWS_CLEANUP_SCRIPT = [[
$dir = Join-Path $env:TEMP 'wezterm-clipboard-images'
if (-not (Test-Path -LiteralPath $dir)) { exit 0 }
$session = (Get-Process -Id $PID).SessionId
$logon = Get-Process -Name explorer -ErrorAction SilentlyContinue |
    Where-Object { $_.SessionId -eq $session -and $_.StartTime } |
    Sort-Object StartTime |
    Select-Object -First 1 -ExpandProperty StartTime
if (-not $logon) { exit 0 }
Get-ChildItem -LiteralPath $dir -File |
    Where-Object { $_.LastWriteTime -lt $logon } |
    Remove-Item -Force -ErrorAction SilentlyContinue
]]

local function powershell_args(script)
    return {
        "powershell.exe",
        "-NoProfile",
        "-NonInteractive",
        "-STA",
        "-Command",
        script,
    }
end

local paste_counter = 0

local function save_windows_clipboard_image()
    local success, stdout = wezterm.run_child_process(powershell_args(WINDOWS_SAVE_SCRIPT))
    if not success then
        return nil, true
    end

    local path = stdout and stdout:match("^%s*(.-)%s*$") or ""
    if path == "" then
        return nil, false
    end

    return path, false
end

local function macos_clipboard_has_only_image()
    local success, stdout = wezterm.run_child_process({ "osascript", "-e", "clipboard info" })
    if not success or not stdout then
        return false
    end
    if stdout:find("utf8", 1, true) then
        return false
    end

    return stdout:find("PNGf", 1, true) ~= nil
        or stdout:find("TIFF", 1, true) ~= nil
        or stdout:find("JPEG", 1, true) ~= nil
end

local function save_macos_clipboard_image()
    if not macos_clipboard_has_only_image() then
        return nil, false
    end

    wezterm.run_child_process({ "mkdir", "-p", MACOS_PASTE_DIR })

    -- 同じ秒に複数回貼り付けても上書きしないよう、連番を付けます。
    paste_counter = paste_counter + 1
    local path = string.format(
        "%s/paste-%s-%d.png",
        MACOS_PASTE_DIR,
        os.date("%Y%m%d-%H%M%S"),
        paste_counter
    )
    local script = string.format([[
set imgPath to POSIX file "%s"
set imgData to the clipboard as «class PNGf»
set fileRef to open for access imgPath with write permission
write imgData to fileRef
close access fileRef
]], path)

    local success = wezterm.run_child_process({ "osascript", "-e", script })
    if not success then
        return nil, true
    end

    return path, false
end

-- WSL pane には Windows パスではなく /mnt/<drive>/... 形式で渡します。
local function path_for_pane(pane, path)
    local ok, domain = pcall(function()
        return pane:get_domain_name()
    end)
    if ok and domain and domain:find("^WSL:") then
        local drive, rest = path:match("^(%a):\\(.*)$")
        if drive then
            return "/mnt/" .. drive:lower() .. "/" .. rest:gsub("\\", "/")
        end
    end

    return path
end

local function quote_if_needed(path)
    if path:find(" ", 1, true) then
        return '"' .. path .. '"'
    end

    return path
end

-- クリップボードが画像だけなら一時ファイルに保存してそのパスを、
-- それ以外なら通常のテキストを貼り付けます。
-- bracketed paste を保つため、パスは SendString ではなく send_paste で送ります。
function M.paste(window, pane)
    local path, failed = nil, false
    if is_windows then
        path, failed = save_windows_clipboard_image()
    elseif is_macos then
        path, failed = save_macos_clipboard_image()
    end

    if path then
        pane:send_paste(quote_if_needed(path_for_pane(pane, path)))
        return
    end

    if failed then
        window:toast_notification("Smart Paste", "クリップボード画像の保存に失敗しました", nil, 3000)
    end
    window:perform_action(act.PasteFrom("Clipboard"), pane)
end

-- 前回ログオン時に保存した画像をバックグラウンドで削除します。
-- GUI 起動を待たせないよう、完了は待ちません。
function M.cleanup_stale_images()
    if not is_windows then
        return
    end

    wezterm.background_child_process(powershell_args(WINDOWS_CLEANUP_SCRIPT))
end

return M
