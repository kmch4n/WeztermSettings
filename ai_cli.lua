-- AI CLI detection and key translation.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local ai_cli_user_vars = {
    ["codex"] = "codex",
    ["claude"] = "claude",
    ["claude-code"] = "claude",
}

-- 判定結果を pane 単位で短時間だけキャッシュし、
-- Windows ConPTY 側で foreground や祖先の取得が一時的に失敗したときに、
-- 直前の確定結果をフォールバックとして再利用するための入れ物です。
local ai_cli_detection_cache = {}
local AI_CLI_DETECTION_TTL_SECONDS = 2

-- 実行ファイルのパスからファイル名だけを取り出します。
-- Windows と POSIX の両方の区切り文字に対応します。
local function basename(path)
    if not path or path == "" then
        return nil
    end

    return path:match("([^/\\]+)$")
end

local function user_vars_ai_cli_name(vars)
    if not vars then
        return nil
    end

    local ai_cli = vars.AI_CLI
    if not ai_cli or ai_cli == "" then
        return nil
    end

    return ai_cli_user_vars[ai_cli:lower()]
end

-- process info から、Codex / Claude Code のどちらが実行中か判定します。
-- 実行ファイル名だけでなく、Node.js 経由の argv も見ます。
local function process_ai_cli_name(info)
    local exe = basename(info.executable)
    if exe then
        exe = exe:lower()
        if exe == "codex" or exe == "codex.exe" then
            return "codex"
        end
        if exe == "claude" or exe == "claude.exe" then
            return "claude"
        end
    end

    -- npm CLI は node 経由で起動される場合があるため、
    -- argv 側の package path も見て判定する。
    if info.argv then
        for _, arg in ipairs(info.argv) do
            local lower = arg:lower()
            if lower:find("@openai/codex", 1, true)
                or lower:find("codex.js", 1, true) then
                return "codex"
            end
            if lower:find("claude-code", 1, true)
                or lower:find("@anthropic-ai", 1, true) then
                return "claude"
            end
        end
    end

    return nil
end

-- PowerShell profile などから AI_CLI user var が設定されている場合は、
-- process tree よりもその明示的な状態を優先します。
local function user_var_ai_cli_name(pane)
    return user_vars_ai_cli_name(pane:get_user_vars())
end

local function remember_ai_cli_detection(pane_id, result)
    ai_cli_detection_cache[pane_id] = {
        result = result,
        at = os.time(),
    }
end

local function recall_ai_cli_detection(pane_id)
    local entry = ai_cli_detection_cache[pane_id]
    if not entry then
        return nil
    end
    if os.time() - entry.at > AI_CLI_DETECTION_TTL_SECONDS then
        return nil
    end
    return entry.result
end

-- AI CLI は MCP サーバーなど複数の子プロセスを同時に抱える。
-- Windows の ConPTY には tty foreground の概念がないため、
-- pane:get_foreground_process_info() は一番奥の子孫 (= MCP サーバー)
-- を返すことがある。ppid を辿り、祖先に Codex / Claude Code があれば
-- AI CLI が動いているとみなす。
-- 祖先取得や foreground 取得が失敗した場合は、直近 2 秒以内に得た
-- 確定結果を再利用することで、一過性の取得失敗による誤判定を防ぐ。
local function current_ai_cli_name(pane)
    local pane_id = pane:pane_id()
    local user_var_cli = user_var_ai_cli_name(pane)

    if user_var_cli then
        remember_ai_cli_detection(pane_id, user_var_cli)
        return user_var_cli
    end

    local info = pane:get_foreground_process_info()

    if info == nil then
        local cached = recall_ai_cli_detection(pane_id)
        if cached ~= nil then
            return cached
        end
        return nil
    end

    local depth = 0
    while info and depth < 16 do
        local cli_name = process_ai_cli_name(info)
        if cli_name then
            remember_ai_cli_detection(pane_id, cli_name)
            return cli_name
        end
        if not info.ppid or info.ppid <= 0 then
            remember_ai_cli_detection(pane_id, false)
            return nil
        end
        local parent = wezterm.procinfo.get_info_for_pid(info.ppid)
        if parent == nil then
            -- 祖先取得の失敗は不確定として扱い、直近の判定があればそれを優先する。
            local cached = recall_ai_cli_detection(pane_id)
            if cached ~= nil then
                return cached
            end
            return nil
        end
        info = parent
        depth = depth + 1
    end

    -- depth 上限に到達した場合も不確定として扱う。
    local cached = recall_ai_cli_detection(pane_id)
    if cached ~= nil then
        return cached
    end
    return nil
end

-- 現在の pane が AI CLI なら CLI ごとの専用入力を送り、
-- それ以外なら通常キーを送ります。
-- Enter と Ctrl+Enter の入れ替えをこの関数に集約しています。
function M.send_key_for_current_process(window, pane, cli_keys, default_key, default_mods)
    local cli_name = current_ai_cli_name(pane)
    local cli_key = cli_name and cli_keys[cli_name] or nil

    if cli_key then
        if cli_key.action then
            window:perform_action(cli_key.action, pane)
            return
        end

        window:perform_action(act.SendKey({
            key = cli_key.key,
            mods = cli_key.mods,
        }), pane)
        return
    end

    window:perform_action(act.SendKey({
        key = default_key,
        mods = default_mods,
    }), pane)
end

return M
