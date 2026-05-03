# Official Reference

このファイルは、現行設定の正当性確認と、ローカル reference 作成時の一次情報確認に使った
WezTerm / Codex 公式ドキュメントのリンク集です。最終確認日は 2026-05-03 です。

ローカル reference のカバー範囲は次のとおりです。

- `reference/config-options-reference.md`
  - 公式 `Config Options` index から取得できた `173` 個の option ページを日本語整理
- `reference/non-index-options.md`
  - 公式 index 外だが実用上重要な設定を補足

## 設定ファイル構成

- Configuration Files
  - <https://wezterm.org/config/files.html>
  - `wezterm.lua` の配置場所、複数ファイルへの分割、独自 Lua module の読み込み方法を確認できます。

## Lua 基本 API

- `wezterm.config_builder()`
  - <https://wezterm.org/config/lua/wezterm/config_builder.html>
  - 不正な設定キーに対して警告やエラーを出せる config builder であることを確認できます。
- `wezterm.home_dir`
  - <https://wezterm.org/config/lua/wezterm/home_dir.html>
  - ユーザーのホームディレクトリを表す定数であることを確認できます。
- `wezterm.target_triple`
  - <https://wezterm.org/config/lua/wezterm/target_triple.html>
  - 実行中 platform の target triple を見て、OS ごとの設定分岐に使えることを確認できます。

## イベント

- `format-tab-title`
  - <https://wezterm.org/config/lua/window-events/format-tab-title.html>
  - タブタイトルを動的に整形できること、同期イベントであることを確認できます。
- User Vars
  - <https://wezterm.org/recipes/passing-data.html>
  - pane 内のアプリケーションから OSC 1337 `SetUserVar` escape sequence で WezTerm の Lua 設定へ状態を渡せることを確認できます。
- `pane:get_user_vars()`
  - <https://wezterm.org/config/lua/pane/get_user_vars.html>
  - pane に設定された user var を Lua 側で読み取れることを確認できます。
- `gui-startup`
  - <https://wezterm.org/config/lua/gui-events/gui-startup.html>
  - GUI 起動時に最初の window や pane を生成できることを確認できます。
  - pane を生成すると `default_prog` よりその起動内容が優先されることもここで確認できます。

## 現在使っている主要設定

- `default_cwd`
  - <https://wezterm.org/config/lua/config/default_cwd.html>
  - 絶対パスが必要であり、`~` は使えず、`wezterm.home_dir` を使うべきことを確認できます。
- `default_prog`
  - <https://wezterm.org/config/lua/config/default_prog.html>
  - コマンドと引数を配列で指定する設定であることを確認できます。
- Launching Programs
  - <https://wezterm.org/config/launch.html>
  - `default_prog` を設定しない Posix 系では、WezTerm が login shell を起動することを確認できます。
- `show_tab_index_in_tab_bar`
  - <https://wezterm.org/config/lua/config/show_tab_index_in_tab_bar.html>
  - タブ番号プレフィックスの表示有無を制御する設定であることを確認できます。
- `window_decorations`
  - <https://wezterm.org/config/lua/config/window_decorations.html>
  - タイトルバーとリサイズ境界をフラグで制御する設定であることを確認できます。
- `integrated_title_button_alignment`
  - <https://wezterm.org/config/lua/config/integrated_title_button_alignment.html>
  - 統合タイトルボタンの左右位置を制御できることを確認できます。
- `integrated_title_button_style`
  - <https://wezterm.org/config/lua/config/integrated_title_button_style.html>
  - `INTEGRATED_BUTTONS|RESIZE` 使用時のボタン見た目を制御する設定であることを確認できます。
- `initial_cols`
  - <https://wezterm.org/config/lua/config/initial_cols.html>
  - 新規ウィンドウ幅を文字セル数で指定する設定であることを確認できます。
- `initial_rows`
  - <https://wezterm.org/config/lua/config/initial_rows.html>
  - 新規ウィンドウ高さを文字セル数で指定する設定であることを確認できます。

## 色と外観

- Colors & Appearance
  - <https://wezterm.org/config/appearance.html>
  - `color_scheme` の使い方
  - `window_background_opacity` の範囲が `0.0` から `1.0` であること
  - 透過設定が描画性能へ影響しうること

## 補足

- Config Options
  - <https://wezterm.org/config/lua/config/index.html>
- Codex config schema
  - <https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/config.schema.json>
  - Codex TUI の `[tui.keymap.editor]` / `[tui.keymap.composer]` と、`insert_newline` / `submit` action の存在を確認できます。

このリポジトリでは、自分用にローカル reference も持ちますが、
値の型、既定値、対応 OS、バージョン制約は必ず公式 docs を最終根拠にします。
