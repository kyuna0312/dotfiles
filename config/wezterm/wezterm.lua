-- WezTerm — ARASAKA UI (CyberArch-Dotfiles, Cyberpunk 2077)
-- Same palette as the ghostty/kitty/tmux ARASAKA theming.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ---- Font ----
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 13.0

-- ---- Window ----
config.window_background_opacity = 0.8
config.macos_window_background_blur = 32
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
config.hide_tab_bar_if_only_one_tab = true
config.audible_bell = "Disabled"

-- ---- Cursor ----
config.default_cursor_style = "BlinkingBlock"

-- ---- macOS keys: left option as alt (like ghostty/kitty) ----
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- ---- ARASAKA palette ----
config.colors = {
	foreground = "#ff4d5e",
	background = "#080002",

	cursor_bg = "#ff1e3c",
	cursor_fg = "#080002",
	cursor_border = "#ff1e3c",

	selection_bg = "#ff1e3c",
	selection_fg = "#080002",

	split = "#ff1e3c",
	scrollbar_thumb = "#3a0f16",

	ansi = {
		"#0e0304", -- black
		"#ff1e3c", -- red (arasaka)
		"#39ff88", -- green
		"#fce300", -- yellow (arasaka accent)
		"#00b4ff", -- blue
		"#ff29d4", -- magenta
		"#00ffc8", -- cyan
		"#ff4d5e", -- white (red-tinted, no white anywhere)
	},
	brights = {
		"#5a1a24",
		"#ff6b7d",
		"#7dffb5",
		"#ffe66b",
		"#4dd2ff",
		"#ff7de8",
		"#5fffe0",
		"#ff8f9c",
	},

	tab_bar = {
		background = "#050102",
		active_tab = { bg_color = "#fce300", fg_color = "#080002", intensity = "Bold" },
		inactive_tab = { bg_color = "#1a060a", fg_color = "#c25c6e" },
		inactive_tab_hover = { bg_color = "#3a0f16", fg_color = "#ff4d5e" },
		new_tab = { bg_color = "#050102", fg_color = "#c25c6e" },
		new_tab_hover = { bg_color = "#3a0f16", fg_color = "#ff1e3c" },
	},
}

return config
