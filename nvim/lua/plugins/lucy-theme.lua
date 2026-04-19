-- Lucy Kushinada · Cyberpunk Edgerunners Neovim theme
-- Catppuccin Mocha + Lucy Edgerunner+ palette overrides + lualine + dashboard

return {

  -- ── Catppuccin colorscheme ─────────────────────────────────────────────────
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      show_end_of_buffer = false,
      term_colors = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = { enabled = true },
        treesitter = true,
        which_key = true,
        mini = { enabled = true },
        dashboard = true,
        lualine = true,
      },
      -- Lucy Edgerunner+ color overrides on top of Catppuccin Mocha
      color_overrides = {
        mocha = {
          base   = "#0a0a14",  -- void black
          mantle = "#11111e",  -- surface
          crust  = "#1a1a2e",  -- overlay
          -- accent: sakura replaces mauve/flamingo
          mauve    = "#ff6bba",
          flamingo = "#ffb3d9",
          pink     = "#ff6bba",
          -- keep cyan sharp
          sky      = "#00e5ff",
          sapphire = "#67e8f9",
          blue     = "#c8a5ff",  -- lavender as "blue"
          -- greens → mint
          green    = "#9dffcc",
          teal     = "#9dffcc",
          -- warm tones
          yellow   = "#ffd97d",
          peach    = "#ffb3a0",
          red      = "#ff4d8d",
          -- text
          text     = "#f0e6ff",
          subtext1 = "#c4b0d8",
          subtext0 = "#9a8aaa",
        },
      },
    },
  },

  -- ── Set catppuccin as LazyVim's colorscheme ────────────────────────────────
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },

  -- ── Lualine — Lucy identity statusline ────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local colors = {
        pink    = "#ff6bba",
        cyan    = "#00e5ff",
        lav     = "#c8a5ff",
        mint    = "#9dffcc",
        gold    = "#ffd97d",
        rose    = "#ff4d8d",
        bg      = "#0a0a14",
        surface = "#11111e",
        overlay = "#1a1a2e",
        text    = "#f0e6ff",
        muted   = "#c4b0d8",
      }
      local lucy_theme = {
        normal = {
          a = { bg = colors.pink,  fg = colors.bg,   gui = "bold" },
          b = { bg = colors.overlay, fg = colors.lav },
          c = { bg = colors.surface, fg = colors.muted },
        },
        insert = {
          a = { bg = colors.cyan,  fg = colors.bg,   gui = "bold" },
          b = { bg = colors.overlay, fg = colors.cyan },
          c = { bg = colors.surface, fg = colors.muted },
        },
        visual = {
          a = { bg = colors.lav,  fg = colors.bg,   gui = "bold" },
          b = { bg = colors.overlay, fg = colors.lav },
          c = { bg = colors.surface, fg = colors.muted },
        },
        replace = {
          a = { bg = colors.rose,  fg = colors.bg,   gui = "bold" },
          b = { bg = colors.overlay, fg = colors.rose },
          c = { bg = colors.surface, fg = colors.muted },
        },
        command = {
          a = { bg = colors.gold,  fg = colors.bg,   gui = "bold" },
          b = { bg = colors.overlay, fg = colors.gold },
          c = { bg = colors.surface, fg = colors.muted },
        },
        inactive = {
          a = { bg = colors.surface, fg = colors.muted },
          b = { bg = colors.surface, fg = colors.muted },
          c = { bg = colors.surface, fg = colors.muted },
        },
      }
      return {
        options = {
          theme = lucy_theme,
          component_separators = { left = "❥", right = "❥" },
          section_separators   = { left = "", right = "" },
          globalstatus = true,
        },
        sections = {
          lualine_a = { { "mode", fmt = function(s) return "✦ " .. s end } },
          lualine_b = { "branch", "diff" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "diagnostics", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { { "location", fmt = function(s) return s .. " ♡" end } },
        },
        inactive_sections = {
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "location" },
        },
      }
    end,
  },

  -- ── Dashboard — Lucy boot screen ──────────────────────────────────────────
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = {
      theme = "doom",
      config = {
        header = {
          "",
          "  ██╗     ██╗   ██╗ ██████╗██╗   ██╗",
          "  ██║     ██║   ██║██╔════╝╚██╗ ██╔╝",
          "  ██║     ██║   ██║██║      ╚████╔╝ ",
          "  ██║     ██║   ██║██║       ╚██╔╝  ",
          "  ███████╗╚██████╔╝╚██████╗   ██║   ",
          "  ╚══════╝ ╚═════╝  ╚═════╝   ╚═╝   ",
          "",
          "      ✦  netrunner online  ♡         ",
          "      lucy kushinada · edgerunner     ",
          "",
        },
        center = {
          { icon = "  ", icon_hl = "DashboardIcon", key = "f", desc = "Find file",    action = "Telescope find_files" },
          { icon = "  ", icon_hl = "DashboardIcon", key = "r", desc = "Recent files", action = "Telescope oldfiles" },
          { icon = "  ", icon_hl = "DashboardIcon", key = "g", desc = "Live grep",    action = "Telescope live_grep" },
          { icon = "  ", icon_hl = "DashboardIcon", key = "d", desc = "Dotfiles",     action = "e ~/dotfiles" },
          { icon = "󰒲  ", icon_hl = "DashboardIcon", key = "l", desc = "Lazy",         action = "Lazy" },
          { icon = "  ", icon_hl = "DashboardIcon", key = "q", desc = "Quit",          action = "qa" },
        },
        footer = function()
          local stats = require("lazy").stats()
          return { "", "  ⚡ " .. stats.loaded .. "/" .. stats.count .. " plugins  ·  jack in, edgerunner" }
        end,
      },
    },
  },
}
