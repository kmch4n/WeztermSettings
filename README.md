# WezTerm Settings

個人用の WezTerm 設定です。Windows と macOS の両方で同じ運用感になるように調整しています。

## 主な機能

- タブ名を見分けやすくする
  - shell のタブは作業フォルダ名 (ホームは `~`)、SSH 中は `SSH` と表示します。
  - Codex / Claude Code / Antigravity CLI / Expo の実行中は `Codex - wezterm` のようにツール名と作業フォルダ名を表示します。
- AI CLI ごとに `Enter` 系のキーを入れ替える
  - Codex: `Ctrl + Enter` を `F12` (Codex 側の keymap で送信) に変換します。
  - Claude Code / Antigravity CLI: `Enter` と `Shift + Enter` を改行、`Ctrl + Enter` を送信にします。
- タブ操作
  - `Ctrl + ←/→` でタブ移動、`Ctrl + Shift + ←/→` でタブの並べ替えができます。
  - `Ctrl + Shift + W` とウィンドウの閉じるボタンは確認なしで閉じます。
- コピーと貼り付け
  - 右クリックは選択があればコピー、なければ貼り付けです。
  - `Ctrl + V` は、クリップボードが画像だけなら一時 PNG のパスを貼り付けます。
- 前回開いていたタブと作業フォルダを、次回起動時に復元します。
- `F3` の launcher から OS ごとの主要 shell (PowerShell / Command Prompt / WSL、macOS では login shell など) を開けます。

設定と挙動の詳細は [docs/current-config.md](docs/current-config.md) にまとめています。

## ファイル構成

| パス | 役割 |
| --- | --- |
| `wezterm.lua` | 設定の入口。各 module を読み込み、イベント・キー・マウス・ウィンドウ・外観を設定します。 |
| `ai_cli.lua` | AI CLI の検出と `Enter` 系キー変換 |
| `title.lua` | タブ名とウィンドウタイトルの整形 |
| `session.lua` | tab と cwd の保存・復元 |
| `launcher.lua` | OS ごとの launcher menu 生成 |
| `clipboard.lua` | `Ctrl + C` と右クリックのコピー/貼り付け |
| `smart_paste.lua` | クリップボード画像をパスとして貼り付け |
| `local.lua` | マシンごとの上書き (Git 管理外) |
| `local.example.lua` | `local.lua` の雛形 |
| `shell/wezterm-ai-cli.bash` | SSH 先の Bash から AI CLI の実行状態を通知 |
| `docs/` | 設定の詳細、連携手順、公式リンク、設定項目の reference |
| `AGENTS.md` | コーディングエージェント向けの指示 (Codex が直接読み、`.claude/CLAUDE.md` が取り込みます) |

## セットアップ

1. `local.example.lua` を `local.lua` としてコピーし、`default_cwd`、`initial_cols`、`initial_rows`、`font_size` などをマシンに合わせて変更します。
2. Windows では、PowerShell profile に AI CLI 用の wrapper を入れます。手順は [docs/powershell-integration.md](docs/powershell-integration.md) を参照してください。
3. Codex を使う場合は、`~/.codex/config.toml` の keymap で通常の `Enter` を改行、`F12` を送信にします。
4. SSH 先で AI CLI を使う場合は、[docs/remote-ai-cli.md](docs/remote-ai-cli.md) の手順で `shell/wezterm-ai-cli.bash` を読み込みます。

`automatically_reload_config` を有効にしているので、設定ファイルを保存すると開いているウィンドウにすぐ反映されます。

## ドキュメント

- [docs/README.md](docs/README.md): docs 全体の入口
- [docs/current-config.md](docs/current-config.md): 現在有効な設定と挙動
- [docs/powershell-integration.md](docs/powershell-integration.md): Windows の PowerShell profile 連携
- [docs/remote-ai-cli.md](docs/remote-ai-cli.md): SSH / tmux 内の AI CLI 連携
- [docs/official-reference.md](docs/official-reference.md): 公式ドキュメントへのリンク集
- [docs/reference/README.md](docs/reference/README.md): WezTerm 設定項目の reference
