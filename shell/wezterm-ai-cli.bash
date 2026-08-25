# WezTerm AI CLI integration for remote Bash sessions.
# shellcheck shell=bash

if [[ -n "${__WEZTERM_AI_CLI_INTEGRATION_LOADED:-}" ]]; then
    return 0
fi
__WEZTERM_AI_CLI_INTEGRATION_LOADED=1

__wezterm_set_user_var() {
    local name="$1"
    local value="$2"
    local encoded_value

    if ! command -v base64 >/dev/null 2>&1; then
        return 0
    fi

    encoded_value="$(printf "%s" "${value}" | base64 | tr -d "\r\n")"

    if [[ -n "${TMUX:-}" ]]; then
        printf "\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\" \
            "${name}" "${encoded_value}"
        return
    fi

    printf "\033]1337;SetUserVar=%s=%s\007" "${name}" "${encoded_value}"
}

__wezterm_run_ai_cli() {
    local ai_cli="$1"
    local executable="$2"
    local exit_code
    shift 2

    __wezterm_set_user_var "AI_CLI" "${ai_cli}"
    if command "${executable}" "$@"; then
        exit_code=0
    else
        exit_code=$?
    fi
    __wezterm_set_user_var "AI_CLI" ""

    return "${exit_code}"
}

codex() {
    __wezterm_run_ai_cli "codex" "codex" "$@"
}

claude() {
    __wezterm_run_ai_cli "claude" "claude" "$@"
}
