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
  - 現在は `default_cwd` のみを持ちます。
- `local.example.lua`
  - `local.lua` の雛形です。

現時点の設定量では、これ以上の分割は不要です。
WezTerm 公式 docs では複数ファイル構成自体はサポートされていますが、
このリポジトリでは共通設定とローカル上書きの 2 層で十分です。

## 現在の設定内容

### 共通初期化

- `wezterm.config_builder()` を使って設定オブジェクトを作成しています。
- `local.lua` が読める場合は、そのキーを共通設定に上書きしています。

### 起動時のイベント

- `format-tab-title`
  - 明示的なタブタイトルがあればそれを優先します。
  - そうでなければアクティブ pane のタイトルを使います。
  - `powershell.exe`、`pwsh.exe`、`cmd.exe`、`codex.exe` を含むタイトルは `Terminal` に置き換えます。

### 起動・既定値

- `automatically_reload_config = true`
  - 保存時に自動再読み込みします。
- `default_prog = { "pwsh.exe", "-NoLogo" }`
  - 新規 pane の既定プログラムは PowerShell 7 です。
- `default_cwd`
  - `local.lua` 側で上書きしない場合は `wezterm.home_dir` を使います。
  - 現在の `local.lua` ではローカルの開発用ディレクトリを設定しています。
- `launch_menu`
  - PowerShell 7、Windows PowerShell、Command Prompt、WSL domain を launcher から開けます。
- `wsl_domains`
  - `wezterm.default_wsl_domains()` の結果をそのまま取り込みます。
- `scrollback_lines = 10000`
- `switch_to_last_active_tab_when_closing_tab = true`
- `show_tab_index_in_tab_bar = false`
  - タブバーの数値プレフィックスを無効化しています。
- `window_close_confirmation = "NeverPrompt"`
  - ウィンドウ close ボタン経由では確認を出しません。

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
  - foreground process が `codex` / `claude` 系のときだけ
    - `Enter` は `Ctrl + J`
    - `Ctrl + Enter` は通常の `Enter`

### マウス

- 右クリック押下時の既定動作は無効化しています。
- 右クリックを離したとき
  - 選択中テキストがあればコピー
  - そうでなければ貼り付け

### ウィンドウ

- `initial_cols = 120`
  - 新規ウィンドウの初期幅を 120 桁にします。
- `initial_rows = 28`
  - 新規ウィンドウの初期高さを 28 行にします。
- `window_decorations = "INTEGRATED_BUTTONS|RESIZE"`
  - タイトルバーを消しつつ、統合ボタンとリサイズ境界を維持します。
- `integrated_title_button_style = "Windows"`
  - 統合タイトルボタンを Windows 風にします。

### 外観

- `font_size = 10`
- `window_background_opacity = 0.96`
- `color_scheme = "Tokyo Night"`

## 運用上のメモ

- `local.lua` は Git 管理しない前提です。
- 新しいマシンで使うときは `local.example.lua` をコピーして `local.lua` を作れば十分です。
- 共有設定を増やす場合はまず `wezterm.lua` に書き、ローカル差分だけを `local.lua` に残します。
