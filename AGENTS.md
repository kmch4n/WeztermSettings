# Agent Guidelines

Personal WezTerm configuration shared between Windows and macOS. This file is the single source of agent instructions for this repository: Codex reads it directly, and `.claude/CLAUDE.md` imports it.

## Language Rules

- Converse with the user in Japanese; do not translate technical terms unnecessarily.
- You may think in English for complex problems, but every user-facing response and progress update must be in Japanese.
- Write code, comments, commit messages, GitHub Issues, PR descriptions, and similar repository artifacts in English.
- Exception: Lua comments and the documents under `README.md` / `docs/` are written in Japanese. Follow the surrounding language when editing them.
- Encode every file you touch in UTF-8.

## Repository Layout

- `wezterm.lua` is the entry point. It loads the modules, registers events, and defines keys, mouse bindings, window, and appearance settings.
- Feature modules live next to it: `ai_cli.lua`, `title.lua`, `session.lua`, `launcher.lua`, `clipboard.lua`, `smart_paste.lua`.
- `local.lua` holds machine-specific overrides and is not tracked. `local.example.lua` is its template.
- `shell/` holds shell integrations that run outside WezTerm (for example, the remote Bash AI CLI integration).
- `docs/` holds the detailed documentation. See `docs/README.md` for the index.

## Key Modules

- `ai_cli.lua` is the core of AI CLI (Codex / Claude Code / Antigravity CLI) detection and key remapping. Read it thoroughly before changing it.
  - Detection is two-stage: the `AI_CLI` user var first, then a process tree walk (up to 16 `ppid` levels).
  - A per-pane TTL cache (2 seconds) absorbs transient ConPTY lookup failures.
  - `send_key_for_current_process` centralizes the per-CLI key mapping.
- `title.lua` must stay consistent with `ai_cli.lua`: when a CLI is added or renamed, update both the detection tables and the display names.
- The PowerShell profile wrappers that set `AI_CLI` live outside this repository. `docs/powershell-integration.md` keeps the reference copy; update it when the wrappers change.

## Documentation

- Keep the docs in sync with behavior changes in the same commit.
  - `docs/current-config.md`: what is enabled now (settings, keys, events).
  - `README.md`: overview, file layout, and setup only. Do not duplicate details from `docs/`.
  - `docs/official-reference.md`: official links that justify the settings in use.
  - `docs/powershell-integration.md` / `docs/remote-ai-cli.md`: shell-side integrations.
- Do not copy the official WezTerm docs verbatim; summarize and link.

## Verification

- `wezterm show-keys --lua` prints the effective key table and fails loudly on config errors.
- `wezterm cli list --format json` shows tabs, panes, titles, and cwd. Set `WEZTERM_UNIX_SOCKET` to `~/.local/share/wezterm/gui-sock-<pid>` to target a specific GUI process.
- To inspect key handling, temporarily set `config.debug_key_events = true` and read `~/.local/share/wezterm/wezterm-gui.exe-log-<pid>.txt`. Remove the setting and clear the log afterwards because it records every keystroke.
- `automatically_reload_config` is enabled, so saving a file reloads running windows.

## Git Rules

### Commit Messages

- Follow the detailed policy in `~/.codex/commit_message.md` when it exists (gitmoji format, emoji mapping, Git safety).
- Use `[gitmoji] + space + English message`, for example `[✨] Add issue helper`. The `[` and `]` characters are required.
- Keep the first line less than or equal to 72 chars in present tense, and split unrelated work into separate commits whenever practical.
- Review the last 10 commit messages before drafting a commit message.

### Git Operations Policy

- Do not run `git add`, `git commit`, `git push`, or GitHub Issue write actions unless the user explicitly instructs you to do so.
- Do not add AI attribution (for example `Co-Authored-By` trailers) to commit messages, Issue text, comments, or PR descriptions. Naming a supported CLI such as Codex, Claude Code, or Antigravity CLI as the subject of a change is fine.
- Before commit or Issue write actions, verify the active Git and GitHub identity belongs to the user; if it appears to be an AI agent, a bot, or a service account, stop and report it.
- Do not push until the user explicitly requests it.

## Code Style

- Indent with 4 spaces (tabs are forbidden).
- Prefer double quotes.
- Keep individual files roughly within the 500–700 line range by modularizing.
- Lua: keep each module returning a table `M`, and keep `wezterm.lua` focused on wiring settings together.
- Bash: keep `shell/*.bash` compatible with `shellcheck`.

## Output Rules

- JSON output must use `indent=4` and `ensure_ascii=False`.
- Do not reprint an entire file; apply surgical edits with minimal diffs.
- When referencing code, cite the file path and line number.

## File Operations, Encodings, and Newlines

- Perform path queries and file manipulations in PowerShell on Windows.
- `.gitattributes` enforces LF for `*.lua`, `*.md`, `*.bash`, and other text files.
- Use the following encodings and newline styles:
  - Markdown, YAML, TOML, Lua, and other text files: UTF-8 without BOM, LF.
  - CSV files: UTF-8 with BOM, CRLF.
  - PowerShell 5.x scripts: UTF-8 with BOM, LF.
  - PowerShell 7.x scripts: UTF-8 without BOM, LF.

## Development Policy

- Keep machine-specific values in `local.lua`, not in the shared modules.
- Never commit secrets. `local.lua` and `session-state.json` stay in `.gitignore`.
- Keep agent instructions in this root `AGENTS.md`. Tool-specific files such as `.claude/CLAUDE.md` should only import it and add tool-specific notes.
- Review this file frequently and keep it up to date.
