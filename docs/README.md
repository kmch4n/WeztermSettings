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
- `powershell-integration.md`
  - Windows の PowerShell profile から AI CLI / Expo の実行状態を通知する wrapper の控えと説明です。
  - profile 本体はリポジトリ外にあるため、新しいマシンではここから再現します。
- `remote-ai-cli.md`
  - SSH / tmux内のCodex・Claude Code・Antigravity CLIを認識させるremote Bash設定です。
- `reference/README.md`
  - 網羅 reference の入口です。
  - 公式 `Config Options` index ベースの一覧と、index 外の重要設定を辿れます。

## 設定ファイルの構成

ファイルごとの役割は [../README.md](../README.md#ファイル構成) にまとめています。

## docs の設計方針

- 現在有効な設定は `current-config.md` に集約する
- README は概要・ファイル構成・セットアップの入口に留め、詳細を重複させない
- shell 側の連携 (PowerShell / remote Bash) は専用ファイルに分ける
- 正当性確認に使う一次情報は `official-reference.md` に集約する
- WezTerm の設定項目を広く引けるように `reference/` に厚い catalog を置く
- 公式 docs の全文コピーはしない

この構成により、「今の設定を知る」「連携を再現する」「新しい設定を探す」「公式根拠を確認する」を分離しています。

コーディングエージェント向けの指示はリポジトリ直下の `AGENTS.md` にあり、どの変更でどの docs を更新するかもそこに書いています。
