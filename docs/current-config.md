# Current Config

このファイルは、このリポジトリで現在有効な WezTerm 設定を要約したものです。
詳細な根拠や公式リンクは `official-reference.md` を参照してください。
設定項目の網羅的な一覧は `reference/` 配下を参照してください。

## ファイル構成

- `wezterm.lua`
  - 共通設定を定義します。
  - `local.lua` が存在する場合は、そのテーブルを `config` に上書き適用します。
- `local.lua`
  - マシン依存の上書き用です。
  - 現在は `default_cwd`、`initial_cols`、`initial_rows` を持てます。
- `local.example.lua`
  - `local.lua` の雛形です。

現時点の設定量では、これ以上の分割は不要です。
WezTerm 公式 docs では複数ファイル構成自体はサポートされていますが、
このリポジトリでは共通設定とローカル上書きの 2 層で十分です。

## 現在の設定内容

### 共通初期化

- `wezterm.config_builder()` を使って設定オブジェクトを作成しています。
- `local.lua` が読める場合は、そのキーを共通設定に上書きしています。
- `wezterm.target_triple` を見て、Windows と macOS の分岐に使っています。

### 起動時のイベント

- `format-tab-title`
  - 明示的なタブタイトルがあればそれを優先します。
  - そうでなければアクティブ pane のタイトルを使います。
  - `powershell.exe`、`pwsh.exe`、`cmd.exe`、`zsh`、`bash`、`sh`、`fish` などの既定タイトルは `Terminal` に置き換えます。
  - `codex` / `claude` など AI CLI を認識できる場合は `Codex` / `ClaudeCode` に置き換えます。
  - `AI_CLI` user var が設定されている pane では、npm wrapper 由来の `node.exe` 表示も `Codex` / `ClaudeCode` に置き換えます。

### 起動・既定値

- `automatically_reload_config = true`
  - 保存時に自動再読み込みします。
- `default_prog`
  - Windows では `pwsh.exe -NoLogo` を既定プログラムにします。
  - macOS では設定せず、WezTerm 既定の login shell 起動に任せます。
- `default_cwd`
  - `local.lua` 側で上書きしない場合は `wezterm.home_dir` を使います。
  - 現在の `local.lua` ではローカルの開発用ディレクトリを設定しています。
- `launch_menu`
  - Windows では PowerShell 7、Windows PowerShell、Command Prompt、WSL domain を launcher から開けます。
  - macOS では login shell と `/bin/zsh`、`/bin/bash`、`/bin/sh` を launcher から開けます。
- `wsl_domains`
  - Windows でのみ `wezterm.default_wsl_domains()` の結果を取り込みます。
- `scrollback_lines = 10000`
- `switch_to_last_active_tab_when_closing_tab = true`
- `show_tab_index_in_tab_bar = false`
  - タブバーの数値プレフィックスを無効化しています。
- `window_close_confirmation = "NeverPrompt"`
  - ウィンドウ close ボタン経由では確認を出しません。
- `mux_enable_ssh_agent = false`
  - Windows では WezTerm による `SSH_AUTH_SOCK` 注入を止め、Windows OpenSSH の `ssh-agent` をそのまま使います。

### キーバインド

- `Ctrl + LeftArrow`
  - 左隣のタブへ移動します。
- `Ctrl + RightArrow`
  - 右隣のタブへ移動します。
- `F3`
  - launcher を開きます。
- `Ctrl + C`
  - 選択中テキストがあればコピーし、なければ通常の `Ctrl + C` を送ります。
- `Ctrl + V`
  - クリップボード貼り付けを行います。
- `Ctrl + Shift + W`
  - 確認付きで現在のタブを閉じます。
- `Enter` / `Ctrl + Enter`
  - 通常の pane ではそのまま送ります。
  - Codex 実行中だけ
    - `Enter` は通常の `Enter`
    - `Ctrl + Enter` は `F12`
  - Claude 実行中だけ
    - `Enter` は `Ctrl + J`
    - `Ctrl + Enter` は通常の `Enter`
  - Codex は `~/.codex/config.toml` の Codex TUI keymap で通常の `Enter` を newline、`F12` を submit にします。
  - 最初に `pane:get_user_vars().AI_CLI` を確認し、`codex` / `claude` / `claude-code` なら AI CLI とみなします。
  - user var がない場合は `pane:get_foreground_process_info()` を使い、executable 名と argv を併用します。祖先は ppid を辿って最大 16 段まで調べます。
  - Codex と Claude Code は Node.js 製 npm CLI 経由で起動する場合があるため、Windows の `node.exe` 経由でも argv を見て検出できます。
  - プロセス情報の取得が一時的に失敗した場合は、直近 2 秒以内に確定した判定結果を pane 単位で再利用し、Enter / Ctrl+Enter の取り違えを防ぎます。
  - Windows では PowerShell profile の `codex` / `claude` wrapper が、実行中だけ `AI_CLI` user var を設定します。
  - Codex wrapper は、タブタイトルや foreground process が `node.exe` に寄らないよう、npm wrapper より同梱 native `codex.exe` を優先します。

### マウス

- 右クリック押下時の既定動作は無効化しています。
- 右クリックを離したとき
  - 選択中テキストがあればコピー
  - そうでなければ貼り付け

### ウィンドウ

- `initial_cols = 120`
  - `local.lua` 側で上書きしない場合の既定値です。
  - 新規ウィンドウの初期幅を 120 桁にします。
- `initial_rows = 28`
  - `local.lua` 側で上書きしない場合の既定値です。
  - 新規ウィンドウの初期高さを 28 行にします。
- `window_decorations = "INTEGRATED_BUTTONS|RESIZE"`
  - タイトルバーを消しつつ、統合ボタンとリサイズ境界を維持します。
- `integrated_title_button_alignment`
  - macOS では `Left` にして、ネイティブ位置でボタンを見せます。
- `integrated_title_button_style`
  - Windows では `Windows` を使います。
  - macOS では `MacOsNative` を使います。

### 外観

- `font_size = 10`
- `window_background_opacity = 0.96`
- `color_scheme = "Tokyo Night"`

## 運用上のメモ

- `local.lua` は Git 管理しない前提です。
- 新しいマシンで使うときは `local.example.lua` をコピーして `local.lua` を作れば十分です。
- 起動サイズをマシンごとに変えたい場合は `local.lua` の `initial_cols` / `initial_rows` を調整します。
- 共有設定を増やす場合はまず `wezterm.lua` に書き、ローカル差分だけを `local.lua` に残します。
- `codex` の Enter 入れ替えが効かない場合は、新しい WezTerm タブを開くか、既存 shell で `. $PROFILE` を実行してから CLI を起動し直します。
- Codex のタブタイトルが `node.exe` になる場合は、古い shell で profile が再読み込みされていないか、native `codex.exe` が見つからず npm wrapper に fallback している可能性があります。
- Codex の Enter 挙動は、WezTerm 側の Codex process 検出と `~/.codex/config.toml` の `[tui.keymap.editor]` / `[tui.keymap.composer]` を確認します。
