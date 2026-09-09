;;; init-tools.el --- git, explorer, terminal, todo, AI  -*- lexical-binding: t -*-
;;; Code:

;; lazygit + gitsigns + diffview → magit + diff-hl.
(use-package magit
  :custom (magit-diff-refine-hunk t) (magit-save-repository-buffers 'dontask))
(use-package diff-hl
  :hook ((after-init . global-diff-hl-mode)
         (magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :custom (diff-hl-draw-borders nil))

;; nvim-tree → treemacs, docked right at width 35 like <leader>e.
(use-package treemacs
  :custom
  (treemacs-position 'right)
  (treemacs-width 35)
  (treemacs-follow-after-init t)
  (treemacs-is-never-other-window t)
  (treemacs-no-png-images t)
  :config (treemacs-follow-mode 1) (treemacs-git-mode 'simple))
(use-package treemacs-evil :after (treemacs evil) :demand t)
(use-package treemacs-nerd-icons
  :after treemacs :demand t
  :config (treemacs-load-theme "nerd-icons"))

;; toggleterm → eat (pure elisp, no cmake).
(use-package eat
  :custom (eat-kill-buffer-on-exit t)
  :config (with-eval-after-load 'evil (evil-set-initial-state 'eat-mode 'emacs)))
(defun nyan-terminal ()
  "Toggle a bottom terminal for the current project (<leader>tt)."
  (interactive)
  (let ((win (get-buffer-window "*eat*")))
    (if win (delete-window win)
      (let ((default-directory (if (project-current) (project-root (project-current)) default-directory)))
        (select-window (split-window-below -15))
        (eat)))))

;; todo-comments → hl-todo.
(use-package hl-todo :hook (after-init . global-hl-todo-mode))

;; gen.nvim (ollama) → gptel. `M-x gptel-menu' to switch backend/model.
(use-package gptel
  :custom (gptel-default-mode 'org-mode)
  :config
  (setq gptel-backend (gptel-make-ollama "Ollama" :host "localhost:11434" :stream t
                        :models '(llama3.1 qwen2.5-coder))
        gptel-model 'qwen2.5-coder))

(provide 'init-tools)
;;; init-tools.el ends here
