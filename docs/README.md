# WezTerm Docs

この `docs` ディレクトリは、このリポジトリ用の WezTerm 設定資料をまとめたものです。
2026-04-15 時点では、薄い導線だけでなく、自分用に厚めのローカル reference も持つ方針にしています。

確認の前提は次のとおりです。

- インストール済み WezTerm: `20260107-161548-4bcb2b32`
- 公式ドキュメント: `wezterm.org`
- 公式 `Config Options` index から取得できた個別 option ページ数: `173`

## 読み方

- `current-config.md`
  - このリポジトリで現在有効な設定の要約です。
  - 実際に何を有効にしているかを最短で確認したい時に見ます。
- `official-reference.md`
  - 現行設定の正当性確認に使った公式リンク集です。
  - 変更前に一次情報へ飛ぶための入口です。
- `reference/README.md`
  - 網羅 reference の入口です。
  - 公式 `Config Options` index ベースの一覧と、index 外の重要設定を辿れます。

## 設定ファイルの構成

- `wezterm.lua`
  - 共通設定本体です。
  - イベント、起動設定、ウィンドウ、外観、既定キーバインドを持ちます。
- `local.lua`
  - ローカル環境専用の上書きです。
  - Git 管理の対象外です。
- `local.example.lua`
  - `local.lua` の雛形です。

## docs の設計方針

- 現在有効な設定は `current-config.md` に集約する
- 正当性確認に使う一次情報は `official-reference.md` に集約する
- WezTerm の設定項目を広く引けるように `reference/` に厚い catalog を置く
- 公式 docs の全文コピーはしない

この構成により、「今の設定を知る」「新しい設定を探す」「公式根拠を確認する」を分離しています。
