# WezTerm Settings

個人用の WezTerm 設定です。Windows と macOS の両方で同じ運用感になるように、次の方針で調整しています。

- タブタイトルを見やすくする
- OS ごとの主要 shell を launcher から開けるようにする
- 右クリックのコピー/ペースト挙動をシンプルにする
- Codex 実行中だけ WezTerm 側で `Enter` 系の入力を入れ替える
- Codex は Codex TUI 側の keymap と WezTerm 側の物理キー変換を組み合わせる
- PowerShell profile から WezTerm pane に Codex / Claude / Expo 実行状態を通知する
- 前回終了前に開いていたタブと作業ディレクトリを復元する
- ローカル環境依存の値は `local.lua` に逃がす

## ファイル構成

- `wezterm.lua`
  - 共通設定の入口
  - 各モジュールを読み込み、イベント登録・キー設定・外観設定をまとめる
- `ai_cli.lua`
  - Codex / Claude Code の検出と `Enter` 系キー変換
- `clipboard.lua`
  - `Ctrl + C` と右クリックのコピー/貼り付け補助
- `launcher.lua`
  - OS ごとの launcher menu 生成
- `title.lua`
  - タブタイトル整形
- `session.lua`
  - 前回 session の tab / cwd 保存と復元
- `local.lua`
  - ローカル環境専用の上書き
  - Git 管理対象外
- `local.example.lua`
  - `local.lua` の雛形
- `docs/`
  - 設定の説明、公式参照先、網羅 reference

## 現在の主な設定

- Windows では既定シェルを `pwsh.exe -NoLogo` に固定
- macOS では WezTerm 既定の login shell をそのまま使用
- 起動サイズは `local.lua` の `initial_cols` / `initial_rows` で環境ごとに上書き可能
- `Ctrl + LeftArrow` / `Ctrl + RightArrow` でタブ移動
- `F3` で launcher を表示
- Windows の launcher では PowerShell / Command Prompt / WSL を表示
- macOS の launcher では login shell と標準 shell を表示
- 右クリックは「選択があればコピー、なければ貼り付け」
- ウィンドウ close ボタンは確認なし
- `Ctrl + Shift + W` でのタブ close も確認なし
- Windows では WezTerm の `SSH_AUTH_SOCK` 注入を止め、OpenSSH の `ssh-agent` を使用
- 15 秒ごとに tab / cwd の軽量 snapshot を config dir 外の `session-state.json` に保存
- 次回 GUI 起動時に前回 snapshot から tab と cwd だけを復元
- タブタイトルの shell 名は `Terminal` 表示に寄せ、Codex / Claude Code / Expo は `Codex - wezterm` のようにツール名と作業ディレクトリ名を表示
- `AI_CLI` user var、または `codex` 系 process が検出できるときだけ
- Codex 実行中は
  - `Enter` を通常の `Enter`
  - `Ctrl + Enter` を `F12`
- Claude 実行中は
  - `Enter` を `Ctrl + J`
  - `Ctrl + Enter` を通常の `Enter`
- Codex は `~/.codex/config.toml` の native keymap で
  - 通常の `Enter` を newline
  - `F12` を submit

## `wezterm.lua` の読み方

`wezterm.lua` は、共通設定の入口です。個別の判断や補助処理は Lua module に分け、設定本体では「何を有効化しているか」が追いやすい形にしています。

- `local.lua` の読み込み
  - `local.lua` が存在する場合だけ読み込み、共通設定をローカル値で上書きします。
- `title.lua`
  - shell 名など、タブ名として情報量が低いものを `Terminal` に寄せます。
  - Codex / Claude Code は、認識できる場合は `Codex - wezterm` / `ClaudeCode - SnowLog` のように CLI 名と作業ディレクトリ名を表示します。
  - `npx expo ...` は、PowerShell profile から `TAB_CONTEXT` と起動時の作業ディレクトリ名が設定される場合に `Expo - SnowLog` のように表示します。
  - 作業ディレクトリが取れない場合は、`Codex` / `ClaudeCode` だけを表示します。
  - Codex が npm 経由で `node.exe` と表示される場合も、`AI_CLI` user var があれば `Codex - <directory>` と表示します。
- `session.lua`
  - `session.lua` が 15 秒ごとに現在の window / tab / cwd を config dir 外の `session-state.json` に保存します。
  - WezTerm の GUI 起動時に、保存されていた cwd ごとに shell tab を開き直します。
  - 実行中コマンド、pane 分割、scrollback、SSH 接続は復元しません。
- `launcher.lua`
  - Windows 用の PowerShell / Command Prompt / WSL 候補を作ります。
  - macOS / Linux 用の login shell 候補を作ります。
- `clipboard.lua`
  - `Ctrl + C` は選択中ならコピー、未選択なら割り込みとして送信します。
  - 右クリックは選択中ならコピー、未選択なら貼り付けです。
- `ai_cli.lua`
  - PowerShell profile の `codex` / `claude` wrapper が `AI_CLI` user var を設定している場合は、それを最優先します。
  - user var がない場合は、`codex` / `claude` / `claude-code` の foreground process を見て、CLI 種別を判定します。
  - Claude Code の Enter 入れ替えは既存の挙動を維持します。
  - Codex と Claude Code は Node.js 経由で起動する場合があるため、実行ファイル名だけでなく argv も確認します。
- OS 別設定
  - Windows では WSL domain、OpenSSH agent、PowerShell 7 既定起動を明示します。
  - macOS では WezTerm 既定の login shell を尊重します。

## セットアップ

1. `local.example.lua` を `local.lua` としてコピーする
2. 必要なら `default_cwd`、`initial_cols`、`initial_rows` などをローカル環境に合わせて変更する
3. PowerShell profile を読み込み直すか、新しいタブを開く
4. WezTerm を再読み込みする

## PowerShell 連携

`C:\Users\kmch4n\OneDrive - 同志社大学\Document\PowerShell\Microsoft.PowerShell_profile.ps1` では、`codex` / `claude` 実行時だけ `AI_CLI` user var を WezTerm pane に設定します。
また、`npx expo ...` 実行時だけ `TAB_CONTEXT=expo` と起動時の作業ディレクトリ名を設定します。

これにより、Windows ConPTY が foreground process を `pwsh.exe` として返す場合でも、WezTerm 側は AI CLI 実行中だと判定できます。
Codex は npm の `codex.ps1` 経由だと foreground が `node.exe` になることがあるため、profile wrapper では同梱 native `codex.exe` を優先して起動します。
Expo は npm / npx 経由だと foreground や pane title が `node.exe` や `C:\Windows\system32` に寄ることがあるため、`TAB_CONTEXT` と起動時の作業ディレクトリ名を優先してタブ名を決めます。

既に開いている shell では、次のどちらかが必要です。

- 新しい WezTerm タブを開く
- 既存 shell で `. $PROFILE` を実行してから `codex` / `claude` を起動し直す

## Docs

- [docs/README.md](docs/README.md)
  - docs 全体の入口
- [docs/current-config.md](docs/current-config.md)
  - 現在有効な設定の要約
- [docs/official-reference.md](docs/official-reference.md)
  - 公式ドキュメントへの導線
- [docs/reference/README.md](docs/reference/README.md)
  - 設定項目の厚い reference
