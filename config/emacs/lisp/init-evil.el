;;; init-evil.el --- evil + NyanVim keymaps (lua/config/keymaps.lua)  -*- lexical-binding: t -*-
;; Single owner of every global keymap, like NyanVim. Leader is <space>.
;;; Code:

(use-package evil
  :demand t
  :init
  (setq evil-want-keybinding nil        ; evil-collection does it
        evil-want-C-u-scroll t
        evil-want-C-i-jump t
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo
        evil-split-window-below t       ; splitbelow / splitright
        evil-vsplit-window-right t
        evil-search-module 'evil-search
        evil-ex-search-case 'smart
        evil-respect-visual-line-mode t)
  :config
  (evil-mode 1)
  ;; v< v> keep the selection.
  (evil-define-key 'visual 'global
    "<" (lambda () (interactive) (call-interactively #'evil-shift-left)  (evil-normal-state) (evil-visual-restore))
    ">" (lambda () (interactive) (call-interactively #'evil-shift-right) (evil-normal-state) (evil-visual-restore)))
  ;; C-h/j/k/l windows, S-h/S-l buffers (bufferline), K hover.
  (evil-define-key 'normal 'global
    (kbd "C-h") #'evil-window-left  (kbd "C-j") #'evil-window-down
    (kbd "C-k") #'evil-window-up    (kbd "C-l") #'evil-window-right
    (kbd "C-<up>")    (lambda () (interactive) (enlarge-window 2))
    (kbd "C-<down>")  (lambda () (interactive) (shrink-window 2))
    (kbd "C-<left>")  (lambda () (interactive) (shrink-window-horizontally 2))
    (kbd "C-<right>") (lambda () (interactive) (enlarge-window-horizontally 2))
    (kbd "M-1") (lambda () (interactive) (nyan-goto-window 1))
    (kbd "M-2") (lambda () (interactive) (nyan-goto-window 2))
    (kbd "M-3") (lambda () (interactive) (nyan-goto-window 3))
    (kbd "M-4") (lambda () (interactive) (nyan-goto-window 4))
    "H" #'previous-buffer "L" #'next-buffer
    "K" #'nyan-hover
    "gd" #'xref-find-definitions "gr" #'xref-find-references
    "gi" #'eglot-find-implementation "gD" #'eglot-find-declaration
    ;; PyCharm/VSCode-style
    (kbd "C-p") #'nyan-find-file (kbd "C-f") #'consult-line
    (kbd "C-S-f") #'consult-ripgrep (kbd "C-e") #'consult-recent-file
    (kbd "C-S-s") #'consult-imenu (kbd "C-b") #'treemacs))

(use-package evil-collection
  :after evil
  :demand t
  :custom (evil-collection-setup-minibuffer nil)
  :config (evil-collection-init))

(use-package evil-surround :after evil :demand t :config (global-evil-surround-mode 1))
(use-package evil-commentary :after evil :demand t :config (evil-commentary-mode 1)) ; gc

;; <space> leader (which-key shows the groups, like config/which-key.lua).
(use-package general
  :after evil
  :demand t
  :config
  (general-evil-setup)
  (general-create-definer nyan-leader :states '(normal visual) :keymaps 'override :prefix "SPC")
  (nyan-leader
    "w"  '(save-buffer :wk "Save file")
    "q"  '(evil-quit :wk "Quit")
    "Q"  '(save-buffers-kill-terminal :wk "Quit all")
    "h"  '(evil-ex-nohighlight :wk "Clear highlights")
    "e"  '(treemacs :wk "Toggle Explorer")
    "*"  '(consult-ripgrep-symbol-at-point :wk "Search word under cursor")
    ;; buffers
    "b"  '(:ignore t :wk "buffer")
    "bd" '(kill-current-buffer :wk "Delete buffer")
    "bp" '(consult-buffer :wk "Pick buffer")
    "bo" '(nyan-kill-other-buffers :wk "Close other buffers")
    ;; code
    "c"  '(:ignore t :wk "code")
    "ca" '(eglot-code-actions :wk "Code actions")
    "cf" '(nyan-format :wk "Format code")
    "cd" '(consult-flymake :wk "Diagnostics")
    "r"  '(:ignore t :wk "refactor")
    "rn" '(eglot-rename :wk "Rename symbol")
    ;; find
    "f"  '(:ignore t :wk "find")
    "ff" '(nyan-find-file :wk "Find files")
    "fg" '(consult-ripgrep :wk "Live grep")
    "fb" '(consult-buffer :wk "Find buffers")
    "fr" '(consult-recent-file :wk "Recent files")
    "fh" '(consult-info :wk "Help tags")
    "fk" '(describe-bindings :wk "Keymaps (cheatsheet)")
    "fy" '(consult-yank-pop :wk "Yank history")
    ;; search
    "s"  '(:ignore t :wk "search")
    "sp" '(consult-ripgrep :wk "Search in project")
    "sw" '(consult-ripgrep-symbol-at-point :wk "Search current word")
    "sb" '(consult-line :wk "Search buffer")
    "ss" '(consult-imenu :wk "Document symbols")
    "sS" '(consult-eglot-symbols :wk "Workspace symbols")
    ;; project
    "p"  '(:ignore t :wk "project")
    "pf" '(project-find-file :wk "Find file")
    "pp" '(project-switch-project :wk "Switch project")
    "pt" '(hl-todo-occur :wk "Todo list")
    ;; git
    "g"  '(:ignore t :wk "git")
    "gg" '(magit-status :wk "Magit (lazygit)")
    "gs" '(magit-status :wk "Git status")
    "gb" '(magit-branch-checkout :wk "Git branches")
    "gc" '(magit-log-current :wk "Git commits")
    "gd" '(magit-diff-buffer-file :wk "Diff view")
    ;; toggle
    "t"  '(:ignore t :wk "toggle")
    "tt" '(nyan-terminal :wk "Toggle terminal")
    "th" '(nyan-theme :wk "Theme picker")
    ;; ai
    "a"  '(:ignore t :wk "ai")
    "ag" '(gptel :wk "Local LLM (ollama)")
    ;; NyanEmacs menu
    "n"  '(:ignore t :wk "nyan")
    "nu" '(nyan-update :wk "Update NyanEmacs")
    "nh" '(nyan-health :wk "Health check")
    "nc" '(nyan-config :wk "Edit my overrides (user.el)")
    "nk" '(describe-bindings :wk "Keymaps cheatsheet")
    "nl" '(list-packages :wk "Plugin manager")
    "nt" '(nyan-theme :wk "Theme picker")))

(provide 'init-evil)
;;; init-evil.el ends here
