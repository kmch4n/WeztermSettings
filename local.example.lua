local wezterm = require("wezterm")

local function directory_exists(path)
    local ok = pcall(function()
        wezterm.read_dir(path)
    end)

    return ok
end

local function default_cwd()
    local target_triple = wezterm.target_triple
    local is_windows = target_triple:find("windows", 1, true) ~= nil
    local is_macos = target_triple:find("darwin", 1, true) ~= nil

    local candidates = {}

    if is_windows then
        candidates = {
            wezterm.home_dir .. "\\OneDrive - 同志社大学\\dev",
        }
    elseif is_macos then
        candidates = {
            wezterm.home_dir .. "/Library/CloudStorage/OneDrive-同志社大学/dev",
            wezterm.home_dir .. "/OneDrive - 同志社大学/dev",
        }
    end

    for _, path in ipairs(candidates) do
        if directory_exists(path) then
            return path
        end
    end

    return wezterm.home_dir
end

return {
    default_cwd = default_cwd(),
    initial_cols = 120,
    initial_rows = 28,
    font_size = 10,
}
