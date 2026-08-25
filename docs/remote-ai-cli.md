# Remote AI CLI Integration

SSH先で実行するCodex / Claude CodeをWezTerm側が認識するための設定です。

ローカルWezTermから見えるprocess treeは`ssh.exe`までであり、remote側の
`codex`や`claude`は直接検出できません。そのため、remote shellからOSC 1337
`SetUserVar`を送り、paneの`AI_CLI` user varを設定します。

## 対象

- Ubuntu 24.04
- Bash
- `codex resume`
- `claude -r`
- tmux内でのCodex / Claude Code実行

## 導入

`shell/wezterm-ai-cli.bash`をremote hostへ配置し、`~/.bashrc`から読み込みます。

```bash
mkdir -p ~/.config/wezterm
cp wezterm-ai-cli.bash ~/.config/wezterm/wezterm-ai-cli.bash
printf '\nsource "$HOME/.config/wezterm/wezterm-ai-cli.bash"\n' >> ~/.bashrc
```

tmuxを利用する場合は、`~/.tmux.conf`に次を追加します。

```tmux
set -g allow-passthrough on
```

既に起動しているtmux serverへ反映するには、次を実行します。

```bash
tmux set-option -g allow-passthrough on
```

設定後、新しいSSH sessionを開くか、次を実行します。

```bash
source ~/.bashrc
```

## 動作

- `codex resume`
  - 起動前に`AI_CLI=codex`を通知します。
  - 終了後に`AI_CLI`をクリアします。
- `claude -r`
  - 起動前に`AI_CLI=claude`を通知します。
  - 終了後に`AI_CLI`をクリアします。
- tmux内
  - tmux用DCS passthrough sequenceへ自動的に切り替えます。

引数とCLIの終了コードはwrapperからそのまま返します。

## 制約

- `base64`コマンドが必要です。
- tmux 3.3以降では`allow-passthrough on`が必要です。
- SSH先がBash以外の場合は、このintegrationをそのまま読み込めません。
- `sudo codex`や`sudo claude`はshell functionを経由しないため対象外です。

## 公式参照

- WezTerm `pane:get_user_vars()`
  - <https://wezterm.org/config/lua/pane/get_user_vars.html>
- tmux passthrough FAQ
  - <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it>
