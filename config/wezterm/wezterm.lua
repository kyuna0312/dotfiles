-- WezTerm — H4CK3R // LUCY (Cyberpunk: Edgerunners, Lucy Kushinada)
-- Same palette as the ghostty/kitty/tmux/zsh Lucy theming.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ---- Font ----
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 13.0

-- ---- Window ----
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
config.hide_tab_bar_if_only_one_tab = true
config.audible_bell = "Disabled"

-- ---- Cursor ----
config.default_cursor_style = "BlinkingBlock"

-- ---- macOS keys: left option as alt (like ghostty/kitty) ----
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- ---- Lucy palette ----
config.colors = {
	foreground = "#c4d0e0",
	background = "#0a0a1a",

	cursor_bg = "#00e5ff",
	cursor_fg = "#0a0a1a",
	cursor_border = "#00e5ff",

	selection_bg = "#2a2444",
	selection_fg = "#f0e6ff",

	split = "#45c2f0",
	scrollbar_thumb = "#1a1a2e",

	ansi = {
		"#0d0d1a", -- black
		"#ff2a7a", -- red (neon magenta)
		"#00ff41", -- green (matrix)
		"#ffa600", -- yellow (gold)
		"#45c2f0", -- blue (lucy blue)
		"#b967ff", -- magenta (violet)
		"#00e5ff", -- cyan (lucy glow)
		"#c4d0e0", -- white
	},
	brights = {
		"#5a6a7a",
		"#ff6bba",
		"#7dff9e",
		"#ffc266",
		"#7dd3ff",
		"#d0a5ff",
		"#67e8f9",
		"#f0e6ff",
	},

	tab_bar = {
		background = "#0a0a1a",
		active_tab = { bg_color = "#ff2a7a", fg_color = "#0a0a1a", intensity = "Bold" },
		inactive_tab = { bg_color = "#0d0d1a", fg_color = "#5a6a7a" },
		inactive_tab_hover = { bg_color = "#1a1a2e", fg_color = "#c4d0e0" },
		new_tab = { bg_color = "#0a0a1a", fg_color = "#5a6a7a" },
		new_tab_hover = { bg_color = "#1a1a2e", fg_color = "#00e5ff" },
	},
}

return config
