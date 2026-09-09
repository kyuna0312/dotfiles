# 🐱 NyanEmacs

NyanVim's keys and Night City look on Centaur Emacs' bones. One module per
file, ~600 lines of Elisp, readable in one sitting.

| NyanVim | NyanEmacs |
|---|---|
| lazy.nvim | package.el + use-package (`:defer` everywhere) |
| telescope | vertico + orderless + consult |
| nvim-cmp + LuaSnip | corfu + cape + yasnippet |
| lspconfig + Mason | eglot (builtin); install servers yourself, `M-x nyan-health` lists what's missing |
| nvim-treesitter | treesit-auto |
| conform | apheleia (`<leader>cf` falls back to eglot) |
| nvim-tree | treemacs (docked right, 35 cols) |
| lualine / bufferline | doom-modeline / `H` `L` cycle buffers |
| lazygit / gitsigns | magit / diff-hl |
| toggleterm | eat (`<leader>tt`) |
| dashboard-nvim | dashboard.el, same banner |
| gen.nvim (ollama) | gptel (`<leader>ag`) |
| nightcity.nvim "mix" | `themes/nightcity-mix-theme.el` |
| `:Nyan*` | `M-x nyan-{health,update,config,theme}` and `<leader>n…` |
| "Hold it Cowboy!" | ported |

## Install

```bash
brew install --cask emacs                    # 29.1+
bash ~/dotfiles/install.sh --skip-packages   # links config/emacs → ~/.config/emacs
emacs
```

First launch installs every package from MELPA (about a minute). Then
`M-x nyan-health`.

## Keys

`<space>` is the leader; press it and wait for which-key. The map is
`lisp/init-evil.el` and follows NyanVim's `keymaps.lua` one to one:
`<leader>ff` find, `fg` grep, `e` explorer, `gg` magit, `tt` terminal,
`ca` code action, `cf` format, `rn` rename, `th` theme, `nh` health.

## Make it yours

`user.el` (git-ignored) loads last: put overrides there, `<leader>nc` opens it.
`custom.el` is where Customize writes; also ignored.
