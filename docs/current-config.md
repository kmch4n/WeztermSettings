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
  - 現在は `default_cwd` のみを持ち、既定値は `wezterm.home_dir` です。
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
  - PowerShell 系の既定タイトルはタブバー上で `Terminal` に置き換えます。
- `gui-startup`
  - GUI 起動時に最初のウィンドウを生成します。
  - 最初のタブタイトルを `Dev`、2 つ目のタブタイトルを `Agent` に固定します。
  - このイベント内で pane を生成しているため、通常の `default_prog` よりこちらの起動処理が優先されます。

### 起動・既定値

- `automatically_reload_config = true`
  - 保存時に自動再読み込みします。
- `default_prog = { "powershell.exe", "-NoLogo" }`
  - 新規 pane の既定プログラムは Windows PowerShell です。
- `default_cwd`
  - `local.lua` 側で上書きしない場合は `wezterm.home_dir` を使います。
  - 現在の `local.lua` でも `wezterm.home_dir` を設定しているため、実効値はホームディレクトリです。
- `show_tab_index_in_tab_bar = false`
  - タブバーの数値プレフィックスを無効化しています。

### キーバインド

- `Ctrl + LeftArrow`
  - 左隣のタブへ移動します。
- `Ctrl + RightArrow`
  - 右隣のタブへ移動します。

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
