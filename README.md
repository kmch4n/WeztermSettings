# WezTerm Settings

個人用の WezTerm 設定です。Windows 上でのローカル開発を前提に、次の方針で調整しています。

- タブタイトルを見やすくする
- PowerShell / WSL / Command Prompt を launcher から開けるようにする
- 右クリックのコピー/ペースト挙動をシンプルにする
- Codex / Claude 実行中だけ `Enter` 系の入力を入れ替える
- ローカル環境依存の値は `local.lua` に逃がす

## ファイル構成

- `wezterm.lua`
  - 共通設定本体
- `local.lua`
  - ローカル環境専用の上書き
  - Git 管理対象外
- `local.example.lua`
  - `local.lua` の雛形
- `docs/`
  - 設定の説明、公式参照先、網羅 reference

## 現在の主な設定

- 既定シェルは `pwsh.exe -NoLogo`
- `Ctrl + LeftArrow` / `Ctrl + RightArrow` でタブ移動
- `F3` で launcher を表示
- 右クリックは「選択があればコピー、なければ貼り付け」
- ウィンドウ close ボタンは確認なし
- `Ctrl + Shift + W` でのタブ close は確認あり
- タブタイトルの `powershell.exe` / `pwsh.exe` / `cmd.exe` / `codex.exe` は `Terminal` 表示に寄せる
- `codex` / `claude` 系 process が foreground のときだけ
  - `Enter` を `Ctrl + J`
  - `Ctrl + Enter` を通常の `Enter`

## セットアップ

1. `local.example.lua` を `local.lua` としてコピーする
2. 必要なら `default_cwd` などをローカル環境に合わせて変更する
3. WezTerm を再読み込みする

## Docs

- [docs/README.md](docs/README.md)
  - docs 全体の入口
- [docs/current-config.md](docs/current-config.md)
  - 現在有効な設定の要約
- [docs/official-reference.md](docs/official-reference.md)
  - 公式ドキュメントへの導線
- [docs/reference/README.md](docs/reference/README.md)
  - 設定項目の厚い reference
