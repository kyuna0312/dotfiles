-- WezTerm — Night City Mix
-- Same palette as the ghostty/kitty/tmux Night City Mix theming.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ---- Font ----
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 13.0

-- ---- Window ----
config.window_background_opacity = 0.8
config.macos_window_background_blur = 32
config.window_padding = { left = 16, right = 16, top = 16, bottom = 16 }
config.hide_tab_bar_if_only_one_tab = true
config.audible_bell = "Disabled"

-- ---- Cursor ----
config.default_cursor_style = "BlinkingBar"

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

-- ---- Palette — from the night-city-palettes submodule ----
-- ~/.config/themes -> themes/night-city-palettes (linked by install.sh).
-- Swap the file name to switch palettes (e.g. box-uk-contrast.lua).
config.colors = dofile(wezterm.home_dir .. "/.config/themes/extras/wezterm/night-city-mix.lua")

-- dotfiles-specific tab-bar styling on top of the shared theme
config.colors.tab_bar.background = "#101a1f"
config.colors.tab_bar.active_tab.intensity = "Bold"
config.colors.tab_bar.inactive_tab = { bg_color = "#15242d", fg_color = "#5b7189" }
config.colors.tab_bar.inactive_tab_hover = { bg_color = "#1d2c36", fg_color = "#b6c5d3" }
config.colors.tab_bar.new_tab = { bg_color = "#101a1f", fg_color = "#5b7189" }
config.colors.tab_bar.new_tab_hover = { bg_color = "#1d2c36", fg_color = "#2bbcd5" }

return config
