# Reference Docs

このディレクトリは、自分用の厚い WezTerm reference を置くための場所です。
現行設定に使っているかどうかに関係なく、後で設定を増やす時の索引として使います。

## ファイル一覧

- `config-options-reference.md`
  - 公式 `Config Options` index に載っている項目を、日本語で分野別に整理した一覧です。
  - 2026-04-15 時点で確認できた `173` 個の option ページを対象にしています。
- `non-index-options.md`
  - 公式 `Config Options` index には並んでいないが、実用上よく使う設定や周辺項目をまとめています。
  - 例: `keys`, `leader`, `mouse_bindings`, `color_scheme`

## 使い方

1. まず `config-options-reference.md` か `non-index-options.md` で項目名を探す
2. 項目名が分かったら `official-reference.md` か WezTerm 公式 docs の該当ページを開く
3. 実際に採用した設定は `wezterm.lua` と `current-config.md` に反映する

## 注意

- この reference は公式 docs の日本語整理であって、公式 docs の代替ではありません
- 値の型、既定値、OS 制約、バージョン要件は必ず公式ページで確認します
- WezTerm の docs 構成は将来変わりうるので、必要に応じて更新します
