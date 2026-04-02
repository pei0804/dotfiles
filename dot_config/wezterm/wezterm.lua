local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Load plugins from plugins.d/
local config_dir = wezterm.config_dir
local plugins_dir = config_dir .. "/plugins.d"
for _, entry in ipairs(wezterm.glob(plugins_dir .. "/*.lua")) do
  local ok, err = pcall(dofile, entry)
  if not ok then
    wezterm.log_warn("Failed to load plugin " .. entry .. ": " .. tostring(err))
  end
end

-- Font
config.font = wezterm.font("PlemolJP Console NF")
config.font_size = 14

-- Theme
config.color_scheme = "Catppuccin Mocha"

-- Window
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
config.window_decorations = "RESIZE"

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = "SteadyBlock"

-- Kitty keyboard protocol (tmux経由でShift+Enter等を送るために必要)
config.enable_kitty_keyboard = true

return config
