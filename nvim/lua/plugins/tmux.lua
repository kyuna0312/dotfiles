-- Seamless navigation between nvim splits and tmux panes with C-h/j/k/l.
-- Requires christoomey/vim-tmux-navigator on the tmux side (see tmux.conf).
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>",     desc = "Pane left" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>",     desc = "Pane down" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>",       desc = "Pane up" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>",    desc = "Pane right" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Pane previous" },
    },
  },
}
