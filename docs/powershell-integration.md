# PowerShell Integration

Windows の PowerShell 7 から、AI CLI や Expo の実行状態を WezTerm に伝えるための設定です。
profile 本体はこのリポジトリの外にあるため、ここに必要な部分の控えを置きます。

## なぜ必要か

Windows の ConPTY には tty の foreground という概念がありません。
そのため WezTerm からは、AI CLI 実行中でも foreground process が `pwsh.exe` や MCP サーバーの `node.exe` に見えることがあります。

そこで profile の wrapper 関数が、CLI の実行中だけ OSC 1337 `SetUserVar` で pane に user var を設定します。
WezTerm 側の `ai_cli.lua` と `title.lua` は、process tree よりこの user var を優先して判定します。

| user var | 値 | 設定する wrapper | 使う側 |
| --- | --- | --- | --- |
| `AI_CLI` | `codex` / `claude` / `agy` | `codex` / `claude` / `agy` | `ai_cli.lua` のキー変換、`title.lua` のタブ名 |
| `TAB_CONTEXT` | `expo` | `npx expo ...` | `title.lua` のタブ名 |
| `TAB_CONTEXT_CWD_NAME` | 起動時の作業フォルダ名 | `npx expo ...` | `title.lua` のタブ名 |

## profile の場所

```text
C:\Users\kmch4n\OneDrive - 同志社大学\Document\PowerShell\Microsoft.PowerShell_profile.ps1
```

PowerShell 上では `$PROFILE` で確認できます。

## wrapper の控え

```powershell
function Set-WezTermUserVar {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [string]$Value
    )

    if (-not $env:WEZTERM_PANE) {
        return
    }

    if ($null -eq $Value) {
        $Value = ""
    }

    $encodedValue = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Value))
    [Console]::Out.Write("$([char]0x1b)]1337;SetUserVar=$Name=$encodedValue$([char]0x07)")
}

function Invoke-AiCliWithWezTermUserVar {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$CommandPath,

        [object[]]$Arguments
    )

    Set-WezTermUserVar -Name "AI_CLI" -Value $Name
    try {
        & $CommandPath @Arguments
    } finally {
        Set-WezTermUserVar -Name "AI_CLI" -Value ""
    }
}

function Invoke-TabContextWithWezTermUserVar {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$CommandPath,

        [object[]]$Arguments
    )

    $cwdName = Split-Path -Leaf (Get-Location).ProviderPath
    Set-WezTermUserVar -Name "TAB_CONTEXT" -Value $Name
    Set-WezTermUserVar -Name "TAB_CONTEXT_CWD_NAME" -Value $cwdName
    try {
        & $CommandPath @Arguments
    } finally {
        Set-WezTermUserVar -Name "TAB_CONTEXT_CWD_NAME" -Value ""
        Set-WezTermUserVar -Name "TAB_CONTEXT" -Value ""
    }
}

function claude {
    $command = Get-Command claude.exe -CommandType Application -ErrorAction Stop
    Invoke-AiCliWithWezTermUserVar -Name "claude" -CommandPath $command.Source -Arguments $args
}

function codex {
    $script = Get-Command codex.ps1 -CommandType ExternalScript -ErrorAction Stop
    $baseDir = Split-Path -Parent $script.Source
    $nativeCommand = Join-Path $baseDir "node_modules\@openai\codex\node_modules\@openai\codex-win32-x64\vendor\x86_64-pc-windows-msvc\codex\codex.exe"

    if (Test-Path -LiteralPath $nativeCommand) {
        Invoke-AiCliWithWezTermUserVar -Name "codex" -CommandPath $nativeCommand -Arguments $args
        return
    }

    Invoke-AiCliWithWezTermUserVar -Name "codex" -CommandPath $script.Source -Arguments $args
}

function agy {
    $command = Get-Command agy.exe -CommandType Application -ErrorAction Stop
    Invoke-AiCliWithWezTermUserVar -Name "agy" -CommandPath $command.Source -Arguments $args
}

function npx {
    $command = Get-Command npx.cmd -CommandType Application -ErrorAction Stop

    if ($args.Count -gt 0 -and [string]$args[0] -eq "expo") {
        Invoke-TabContextWithWezTermUserVar -Name "expo" -CommandPath $command.Source -Arguments $args
        return
    }

    & $command.Source @args
}
```

## 各 wrapper の補足

- `codex`
  - npm の `codex.ps1` 経由だと foreground が `node.exe` になるため、同梱の native `codex.exe` を優先して起動します。
  - native binary が見つからない場合だけ `codex.ps1` に fallback します。
- `claude` / `agy`
  - 実行ファイルをそのまま起動し、実行中だけ `AI_CLI` を設定します。
  - agy はウィンドウタイトルを設定しないため、wrapper を通らずに起動した場合は `title.lua` の foreground process 判定が頼りになります。
- `npx`
  - `npx expo ...` のときだけ `TAB_CONTEXT=expo` と起動時の作業フォルダ名を設定します。
  - Expo は foreground や pane title が `node.exe` や `C:\Windows\system32` に寄るため、起動時のフォルダ名を優先してタブ名にします。

`Set-WezTermUserVar` は `WEZTERM_PANE` がない場合は何もしないので、WezTerm 以外のターミナルで profile を読み込んでも影響はありません。

## 反映方法

profile を変更したあと、既に開いている shell では次のどちらかが必要です。

- 新しい WezTerm タブを開く
- 既存 shell で `. $PROFILE` を実行してから CLI を起動し直す

## 関連

- SSH 先の Bash で同じ user var を通知する設定は [remote-ai-cli.md](remote-ai-cli.md) を参照してください。
- WezTerm 側の判定ルールは [current-config.md](current-config.md) の「キーバインド」と「起動時のイベント」を参照してください。
