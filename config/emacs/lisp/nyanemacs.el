;;; nyanemacs.el --- :Nyan* commands + cowboy discipline  -*- lexical-binding: t -*-
;; NyanVim's lua/nyanvim/{init,health,theme,discipline}.lua in one file.
;;; Code:

(defconst nyan-servers
  '(("lua-language-server" . "brew install lua-language-server")
    ("pyright-langserver"  . "npm i -g pyright")
    ("typescript-language-server" . "npm i -g typescript typescript-language-server")
    ("rust-analyzer"       . "rustup component add rust-analyzer")
    ("gopls"               . "go install golang.org/x/tools/gopls@latest")
    ("vscode-json-language-server" . "npm i -g vscode-langservers-extracted")
    ("rg"                  . "brew install ripgrep"))
  "Tools NyanVim's Mason list installs; here you install them yourself.")

(defun nyan-health ()
  "Report missing language servers and tools (`:NyanHealth')."
  (interactive)
  (with-help-window "*nyan-health*"
    (princ (format "NyanEmacs on Emacs %s\n\n" emacs-version))
    (dolist (s nyan-servers)
      (princ (format "  %s %-30s %s\n"
                     (if (executable-find (car s)) "✓" "✗") (car s)
                     (if (executable-find (car s)) "" (cdr s)))))
    (princ (format "\n  %s tree-sitter\n  %s native-comp\n"
                   (if (treesit-available-p) "✓" "✗")
                   (if (native-comp-available-p) "✓" "✗")))))

(defun nyan-update ()
  "Pull the dotfiles repo and upgrade packages (`:NyanUpdate')."
  (interactive)
  (let ((default-directory user-emacs-directory))
    (shell-command "git pull --ff-only"))
  (package-refresh-contents)
  (package-upgrade-all))

(defun nyan-config ()
  "Open user.el, your override layer (`:NyanConfig')."
  (interactive)
  (find-file (expand-file-name "user.el" user-emacs-directory)))

(defun nyan-find-file ()
  "Project files if in a project, else buffers+recent (telescope find_files)."
  (interactive)
  (if (project-current) (project-find-file) (consult-buffer)))

(defun nyan-hover ()
  "LSP hover (K): eldoc in a buffer, or Emacs help for elisp."
  (interactive)
  (if (derived-mode-p 'emacs-lisp-mode)
      (describe-symbol (symbol-at-point))
    (eldoc-print-current-symbol-info t)))

(defun nyan-goto-window (n)
  "Select window N in `window-list' order (M-1..M-4)."
  (let ((w (nth (1- n) (window-list nil 'no-minibuf (frame-first-window)))))
    (when w (select-window w))))

(defun nyan-kill-other-buffers ()
  "Kill every file buffer except the current one."
  (interactive)
  (dolist (b (buffer-list))
    (unless (or (eq b (current-buffer)) (not (buffer-file-name b)))
      (kill-buffer b))))

(defun nyan-theme ()
  "Theme picker with live preview (`consult-theme'; <leader>th)."
  (interactive)
  (call-interactively #'consult-theme))

;; Hold it Cowboy! Ten h/j/k/l presses in two seconds get a warning.
(defvar nyan--cowboy-count 0)
(defvar nyan--cowboy-timer nil)
(defun nyan--cowboy (&rest _)
  (when (and (bound-and-true-p evil-state) (eq evil-state 'normal) (not current-prefix-arg))
    (setq nyan--cowboy-count (1+ nyan--cowboy-count))
    (when nyan--cowboy-timer (cancel-timer nyan--cowboy-timer))
    (setq nyan--cowboy-timer (run-at-time 2 nil (lambda () (setq nyan--cowboy-count 0))))
    (when (>= nyan--cowboy-count 10)
      (setq nyan--cowboy-count 0)
      (message "🤠 Hold it Cowboy!"))))
(with-eval-after-load 'evil
  (dolist (f '(evil-backward-char evil-forward-char evil-next-line evil-previous-line))
    (advice-add f :after #'nyan--cowboy)))

(provide 'nyanemacs)
;;; nyanemacs.el ends here
