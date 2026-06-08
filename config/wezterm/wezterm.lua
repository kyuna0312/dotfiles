local wezterm = require("wezterm")

-- Soft, elegant, minimal terminal style.
return {
  adjust_window_size_when_changing_font_size = false,
  color_scheme = "Catppuccin Mocha",
  font = wezterm.font("JetBrains Mono"),
  font_size = 16.0,
  enable_tab_bar = false,
  window_background_opacity = 0.78,
  window_decorations = "RESIZE",

  -- macOS-only; harmless on Linux.
  macos_window_background_blur = 30,

  keys = {
    {
      key = "q",
      mods = "CTRL",
      action = wezterm.action.ToggleFullScreen,
    },
    {
      key = "'",
      mods = "CTRL",
      action = wezterm.action.ClearScrollback("ScrollbackAndViewport"),
    },
  },

  mouse_bindings = {
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "CTRL",
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  },
}
