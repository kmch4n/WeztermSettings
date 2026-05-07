-- Clipboard-oriented key and mouse helpers.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Ctrl + C は、選択範囲がある時だけコピーとして扱います。
-- 選択がない時は通常通りターミナルへ Ctrl+C を送ります。
function M.copy_if_selected_or_send_ctrl_c(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ""

    if has_selection then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
        return
    end

    window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
end

-- 右クリックは、選択中ならコピー、未選択なら貼り付けにします。
-- Windows Terminal に近い操作感に寄せるための補助関数です。
function M.copy_if_selected_or_paste(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ""

    if has_selection then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
        return
    end

    window:perform_action(act.PasteFrom("Clipboard"), pane)
end

return M
