-- WezTerm — LUCY UI (Cyberpunk: Edgerunners, solarized-osaka)
-- Same palette as the ghostty/kitty/tmux LUCY theming.

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

-- ---- Keybindings (mirror the Ghostty/kitty cmd-based scheme) ----
-- SUPER = cmd on macOS. Splits/tabs/font-size on the same chords as kitty.
local act = wezterm.action
config.keys = {
	-- Tabs
	{ key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "LeftArrow", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },

	-- Splits
	{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "LeftArrow", mods = "SUPER|ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "SUPER|ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "SUPER|ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "SUPER|ALT", action = act.ActivatePaneDirection("Down") },

	-- Font size
	{ key = "=", mods = "SUPER", action = act.IncreaseFontSize },
	{ key = "-", mods = "SUPER", action = act.DecreaseFontSize },
	{ key = "0", mods = "SUPER", action = act.ResetFontSize },

	-- Window / misc
	{ key = "Enter", mods = "SUPER", action = act.ToggleFullScreen },
	{ key = "r", mods = "SUPER|SHIFT", action = act.ReloadConfiguration },
}

-- ---- LUCY palette ----
config.colors = {
	foreground = "#839495",
	background = "#00141a",

	cursor_bg = "#2aa298",
	cursor_fg = "#00141a",
	cursor_border = "#2aa298",

	selection_bg = "#2aa298",
	selection_fg = "#00141a",

	split = "#2aa298",
	scrollbar_thumb = "#0e3139",

	ansi = {
		"#00141a", -- black
		"#2aa298", -- cyan/teal (lucy)
		"#859900", -- green
		"#b28600", -- yellow (solarized accent)
		"#2f879d", -- blue
		"#d33682", -- magenta
		"#4fd1c5", -- cyan bright
		"#839495", -- white (grey-blue fg)
	},
	brights = {
		"#0e3139",
		"#4fd1c5",
		"#859900",
		"#b28600",
		"#2f879d",
		"#d33682",
		"#4fd1c5",
		"#839495",
	},

	tab_bar = {
		background = "#00141a",
		active_tab = { bg_color = "#b28600", fg_color = "#00141a", intensity = "Bold" },
		inactive_tab = { bg_color = "#002d38", fg_color = "#52727a" },
		inactive_tab_hover = { bg_color = "#0e3139", fg_color = "#839495" },
		new_tab = { bg_color = "#00141a", fg_color = "#52727a" },
		new_tab_hover = { bg_color = "#0e3139", fg_color = "#2aa298" },
	},
}

return config
