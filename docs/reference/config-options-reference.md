# Config Options Reference

このファイルは、2026-04-15 時点で公式の `Config Options` index に並んでいる項目を、
日本語で引きやすいように分野別に整理したローカル reference です。

確認時点で、公式 index から取得できた個別 option ページ数は `173` でした。
ただし、実用上よく使う設定の一部はこの index 外にあるため、
それらは `non-index-options.md` で補っています。

## 基本・起動・終了

- `automatically_reload_config`: 設定ファイル変更時に自動で再読み込みするかを設定します。
- `check_for_updates`: WezTerm の更新確認を行うかを設定します。
- `clean_exit_codes`: 正常終了として扱う終了コードを設定します。
- `default_cwd`: 新しい pane や tab を開く既定ディレクトリを設定します。
- `default_domain`: 新しい pane や tab を開く既定 domain を設定します。
- `default_gui_startup_args`: GUI 起動時に使う既定引数を設定します。
- `default_mux_server_domain`: 既定で接続する mux server domain を設定します。
- `default_prog`: 新しい pane や tab で起動する既定コマンドを設定します。
- `default_ssh_auth_sock`: 既定の SSH agent socket を設定します。
- `default_workspace`: 起動時の既定 workspace 名を設定します。
- `detect_password_input`: パスワード入力らしい内容を検知して安全寄りに扱うかを設定します。
- `exit_behavior`: プロセス終了後の pane の扱いを設定します。
- `exit_behavior_messaging`: 終了時メッセージの表示方法を設定します。
- `initial_cols`: 新しいウィンドウの初期列数を設定します。
- `initial_rows`: 新しいウィンドウの初期行数を設定します。
- `launch_menu`: launcher menu に表示する項目を設定します。
- `prefer_to_spawn_tabs`: 新規起動時に window より tab を優先するかを設定します。
- `quit_when_all_windows_are_closed`: すべてのウィンドウを閉じたときにプロセスを終了するかを設定します。
- `quote_dropped_files`: ドラッグアンドドロップしたファイルパスの引用形式を設定します。
- `set_environment_variables`: WezTerm 起動時に設定する環境変数を定義します。
- `skip_close_confirmation_for_processes_named`: 特定プロセス名では close confirmation を省略するかを設定します。
- `term`: アプリに通知する端末種別名を設定します。
- `window_close_confirmation`: ウィンドウを閉じる際の確認方針を設定します。

## 色・背景・外観

- `background`: 背景画像やグラデーションなど、背景レイヤー全体を設定します。
- `bold_brightens_ansi_colors`: 太字テキストに bright ANSI color を使うかを設定します。
- `char_select_bg_color`: character selector の背景色を設定します。
- `char_select_fg_color`: character selector の前景色を設定します。
- `color_schemes`: カスタム color scheme の一覧を定義します。
- `colors`: 個別の色を上書きする color palette を設定します。
- `command_palette_bg_color`: command palette の背景色を設定します。
- `command_palette_fg_color`: command palette の前景色を設定します。
- `command_palette_rows`: command palette に表示する行数を設定します。
- `foreground_text_hsb`: 前景テキストの色相・彩度・明度補正を設定します。
- `kde_window_background_blur`: KDE 上でのウィンドウ背景ぼかしを設定します。
- `macos_window_background_blur`: macOS でウィンドウ背景のぼかし量を設定します。
- `text_min_contrast_ratio`: テキストの最小コントラスト比を設定します。
- `win32_acrylic_accent_color`: Windows の acrylic accent color を設定します。
- `win32_system_backdrop`: Windows の system backdrop を設定します。
- `window_background_gradient`: ウィンドウ背景グラデーションを設定します。
- `window_content_alignment`: ウィンドウ内コンテンツの配置を設定します。
- `window_frame`: タイトルバーやタブバー周辺の frame 色や見た目を設定します。
- `window_padding`: ウィンドウ内側の余白を設定します。

## フォント・文字描画

- `allow_square_glyphs_to_overflow_width`: 正方形グリフがセル幅を少しはみ出して描画されることを許可するかを設定します。
- `anti_alias_custom_block_glyphs`: custom block glyphs にアンチエイリアスを適用するかを設定します。
- `cell_width`: 文字セルの横幅倍率を設定します。
- `cell_widths`: 特定文字や範囲ごとのセル幅補正を設定します。
- `char_select_font`: character selector で使うフォントを設定します。
- `char_select_font_size`: character selector で使うフォントサイズを設定します。
- `command_palette_font`: command palette で使うフォントを設定します。
- `command_palette_font_size`: command palette で使うフォントサイズを設定します。
- `custom_block_glyphs`: block glyph の独自描画定義を設定します。
- `font`: 通常テキストに使うメインフォントを設定します。
- `font_antialias`: フォントのアンチエイリアス方式を設定します。
- `font_dirs`: 追加で探索するフォントディレクトリを設定します。
- `font_hinting`: フォントヒンティング方式を設定します。
- `font_locator`: フォント探索の実装方式を設定します。
- `font_rasterizer`: フォント rasterizer を設定します。
- `font_rules`: 太字や italic など条件別のフォントルールを設定します。
- `font_shaper`: フォント shaping engine を設定します。
- `font_size`: 通常テキストのフォントサイズを設定します。
- `freetype_interpreter_version`: FreeType interpreter version を設定します。
- `freetype_load_flags`: FreeType の load flags を設定します。
- `freetype_load_target`: FreeType の load target を設定します。
- `freetype_pcf_long_family_names`: PCF フォント名の扱いを設定します。
- `freetype_render_target`: FreeType の render target を設定します。
- `harfbuzz_features`: Harfbuzz の OpenType feature を設定します。
- `line_height`: 行の高さ倍率を設定します。
- `normalize_output_to_unicode_nfc`: 出力テキストを Unicode NFC に正規化するかを設定します。
- `pane_select_font`: pane selector で使うフォントを設定します。
- `strikethrough_position`: 打ち消し線の位置を設定します。
- `treat_east_asian_ambiguous_width_as_wide`: East Asian Ambiguous 幅の文字を全角扱いするかを設定します。
- `underline_position`: 下線の位置を設定します。
- `underline_thickness`: 下線の太さを設定します。
- `unicode_version`: 絵文字や文字幅判定に使う Unicode version を設定します。
- `use_cap_height_to_scale_fallback_fonts`: fallback font の拡大縮小に cap height を使うかを設定します。
- `warn_about_missing_glyphs`: 不足 glyph の警告を出すかを設定します。

## カーソル・ベル・点滅

- `audible_bell`: ベル発生時の可聴ベル動作を設定します。
- `cursor_blink_ease_in`: カーソル点滅の立ち上がり easing を設定します。
- `cursor_blink_ease_out`: カーソル点滅の立ち下がり easing を設定します。
- `cursor_blink_rate`: カーソル点滅の周期を設定します。
- `cursor_thickness`: バーや下線カーソルの太さを設定します。
- `default_cursor_style`: 既定のカーソル形状を設定します。
- `force_reverse_video_cursor`: reverse video cursor を強制するかを設定します。
- `reverse_video_cursor_min_contrast`: reverse video cursor の最低コントラストを設定します。
- `text_blink_ease_in`: text blink の立ち上がり easing を設定します。
- `text_blink_ease_out`: text blink の立ち下がり easing を設定します。
- `text_blink_rapid_ease_in`: rapid text blink の立ち上がり easing を設定します。
- `text_blink_rapid_ease_out`: rapid text blink の立ち下がり easing を設定します。
- `text_blink_rate`: 通常の text blink 周期を設定します。
- `text_blink_rate_rapid`: rapid text blink 周期を設定します。
- `visual_bell`: ベル発生時の visual bell 動作を設定します。

## タブ・Pane・ウィンドウ

- `enable_tab_bar`: タブバーを表示するかを設定します。
- `hide_tab_bar_if_only_one_tab`: タブが 1 つだけのときにタブバーを隠すかを設定します。
- `integrated_title_button_alignment`: 統合タイトルバー上のボタン配置位置を設定します。
- `integrated_title_button_color`: 統合タイトルバー上のボタン色を設定します。
- `integrated_title_button_style`: 統合タイトルバー上のボタンスタイルを設定します。
- `integrated_title_buttons`: 統合タイトルバーに表示するボタン構成を設定します。
- `show_close_tab_button_in_tabs`: 各タブに閉じるボタンを表示するかを設定します。
- `show_new_tab_button_in_tab_bar`: タブバーに新規タブボタンを表示するかを設定します。
- `show_tab_index_in_tab_bar`: タブバーにタブ番号を表示するかを設定します。
- `show_tabs_in_tab_bar`: タブバーにタブタイトル自体を表示するかを設定します。
- `switch_to_last_active_tab_when_closing_tab`: タブを閉じた際に最後に使っていたタブへ戻るかを設定します。
- `tab_and_split_indices_are_zero_based`: タブ番号や split 番号を 0 始まりで扱うかを設定します。
- `tab_bar_at_bottom`: タブバーを下側に表示するかを設定します。
- `tab_bar_style`: タブバー各部のスタイルを設定します。
- `tab_max_width`: タブタイトルの最大幅を設定します。
- `unzoom_on_switch_pane`: pane 切り替え時に zoom を解除するかを設定します。
- `use_fancy_tab_bar`: fancy tab bar を使うかを設定します。
- `window_decorations`: タイトルバーや枠などの window decorations を設定します。

## キーボード・マウス・選択

- `allow_win32_input_mode`: Windows の Win32 入力モードを許可するかを設定します。
- `alternate_buffer_wheel_scroll_speed`: alternate screen 上でのマウスホイールスクロール量を設定します。
- `bypass_mouse_reporting_modifiers`: アプリのマウスレポートを一時的に回避する修飾キーを設定します。
- `canonicalize_pasted_newlines`: 貼り付け時の改行コードを正規化する方法を設定します。
- `debug_key_events`: キー入力イベントのデバッグ出力を有効にするかを設定します。
- `disable_default_mouse_bindings`: 既定のマウスバインドを無効にするかを設定します。
- `disable_default_quick_select_patterns`: 既定の quick select pattern を無効にするかを設定します。
- `enable_csi_u_key_encoding`: CSI-u 形式のキーエンコードを有効にするかを設定します。
- `enable_kitty_keyboard`: kitty keyboard protocol を有効にするかを設定します。
- `enable_scroll_bar`: スクロールバーを表示するかを設定します。
- `hide_mouse_cursor_when_typing`: 入力中にマウスカーソルを隠すかを設定します。
- `ime_preedit_rendering`: IME の preedit 表示方法を設定します。
- `hyperlink_rules`: URL とみなすパターンや hyperlink rule を設定します。
- `key_map_preference`: キーマップ解釈の優先方式を設定します。
- `key_tables`: モーダル操作用の key table 群を定義します。
- `launcher_alphabet`: launcher で使うショートカット文字列を設定します。
- `log_unknown_escape_sequences`: 未知の escape sequence をログ出力するかを設定します。
- `min_scroll_bar_height`: スクロールバーの最小高さを設定します。
- `mouse_wheel_scrolls_tabs`: マウスホイールでタブ切り替えを行うかを設定します。
- `notification_handling`: 通知の受け取り方や表示方針を設定します。
- `pane_focus_follows_mouse`: マウス移動で pane focus を切り替えるかを設定します。
- `quick_select_alphabet`: quick select で使うショートカット文字列を設定します。
- `quick_select_patterns`: quick select の対象文字列パターンを設定します。
- `quick_select_remove_styling`: quick select 時に元の装飾を外すかを設定します。
- `scroll_to_bottom_on_input`: 入力時に最下部へ自動スクロールするかを設定します。
- `scrollback_lines`: scrollback に保持する行数を設定します。
- `selection_word_boundary`: 単語選択時の区切り文字を設定します。
- `status_update_interval`: status bar 更新間隔を設定します。
- `swallow_mouse_click_on_pane_focus`: pane focus 時の最初のクリックを消費するかを設定します。
- `swallow_mouse_click_on_window_focus`: window focus 時の最初のクリックを消費するかを設定します。
- `swap_backspace_and_delete`: Backspace と Delete の扱いを入れ替えるかを設定します。
- `treat_left_ctrlalt_as_altgr`: 左 Ctrl+Alt を AltGr として扱うかを設定します。
- `ui_key_cap_rendering`: UI 上のキー表記方法を設定します。
- `use_ime`: IME 入力を有効にするかを設定します。
- `use_resize_increments`: ウィンドウリサイズ時に文字セル単位の増減を使うかを設定します。

## Domain・SSH・TLS・外部接続

- `daemon_options`: mux daemon の起動オプションを設定します。
- `mux_enable_ssh_agent`: mux 経由の SSH agent 利用を有効にするかを設定します。
- `mux_env_remove`: mux 環境から除去する環境変数を設定します。
- `serial_ports`: serial domain 用のポート定義を設定します。
- `ssh_backend`: SSH 接続に使う backend を設定します。
- `ssh_domains`: SSH domain の定義を設定します。
- `tls_clients`: TLS client 定義を設定します。
- `tls_servers`: TLS server 定義を設定します。
- `unix_domains`: Unix domain の定義を設定します。
- `wsl_domains`: WSL domain の定義を設定します。

## 描画・性能・診断

- `adjust_window_size_when_changing_font_size`: フォントサイズ変更時に、ウィンドウサイズも合わせて調整するかを設定します。
- `animation_fps`: UI アニメーションの描画 FPS を設定します。
- `display_pixel_geometry`: ディスプレイの pixel geometry を設定します。
- `dpi`: 描画 DPI を明示指定します。
- `front_end`: 描画 backend を設定します。
- `max_fps`: 通常描画の最大 FPS を設定します。
- `prefer_egl`: OpenGL 系描画で EGL を優先するかを設定します。
- `show_update_window`: 更新通知ウィンドウを表示するかを設定します。
- `tiling_desktop_environments`: tiling WM 環境名の判定ルールを設定します。
- `ulimit_nofile`: 起動時の open files 上限を設定します。
- `ulimit_nproc`: 起動時の process 数上限を設定します。
- `webgpu_force_fallback_adapter`: WebGPU で fallback adapter を強制するかを設定します。
- `webgpu_power_preference`: WebGPU adapter の電力優先方針を設定します。
- `webgpu_preferred_adapter`: WebGPU で優先する adapter を設定します。

## OS 固有

- `enable_wayland`: Linux で Wayland backend を使うかを設定します。
- `macos_forward_to_ime_modifier_mask`: macOS で IME に渡す修飾キーを設定します。
- `macos_fullscreen_extend_behind_notch`: macOS の notch 領域まで全画面を拡張するかを設定します。
- `native_macos_fullscreen_mode`: macOS ネイティブ全画面モードを使うかを設定します。
- `xim_im_name`: X11 系環境で使う XIM の IM 名を設定します。
