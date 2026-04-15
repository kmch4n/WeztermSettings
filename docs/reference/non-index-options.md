# Non-index Options

このファイルは、公式 `Config Options` index には直接並んでいないものの、
実用上よく使う WezTerm 設定や関連項目をまとめたものです。

## キーバインド関連

- `keys`: キーボードショートカットの割り当てを定義します。
- `leader`: Leader キーの組み合わせとタイムアウトを定義します。
- `mouse_bindings`: マウスイベントごとの動作を定義します。

## 色と背景まわり

- `color_scheme`: 使用するカラースキーム名を指定します。
- `color_scheme_dirs`: 追加のカラースキーム探索ディレクトリを定義します。
- `window_background_image`: ウィンドウ背景画像を指定します。
- `window_background_image_hsb`: 背景画像の色相・彩度・明度補正を定義します。
- `window_background_opacity`: ウィンドウ背景の透過率を指定します。
- `text_background_opacity`: セル背景色の透過率を指定します。
- `inactive_pane_hsb`: 非アクティブ pane の色補正を定義します。

## 入力まわり

- `send_composed_key_when_left_alt_is_pressed`: 左 Alt/Option の composed key 動作を指定します。
- `send_composed_key_when_right_alt_is_pressed`: 右 Alt/Option の composed key 動作を指定します。
- `use_dead_keys`: dead key の保持動作を有効化するかを指定します。

## 補足

`keys`、`leader`、`mouse_bindings` などは WezTerm 設定の中でも使用頻度が高い一方で、
公式 `Config Options` index だけでは見つけにくい項目です。

設定追加時は次の順で見ると探しやすいです。

1. `config-options-reference.md`
2. この `non-index-options.md`
3. `official-reference.md`
