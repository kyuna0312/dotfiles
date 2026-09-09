;;; init-ui.el --- Night City look  -*- lexical-binding: t -*-
;;; Code:

(setq frame-title-format '("NyanEmacs · %b")
      icon-title-format frame-title-format
      frame-resize-pixelwise t
      initial-frame-alist '((width . 0.75) (height . 0.85) (top . 0.5) (left . 0.5)))

;; Font: Hack Nerd Font first (installed here), then the usual suspects.
(defun nyan-setup-fonts ()
  "Pick the first available monospace font."
  (when (display-graphic-p)
    (cl-loop for font in '("Hack Nerd Font" "JetBrainsMono Nerd Font" "FiraCode Nerd Font"
                           "SF Mono" "Menlo" "Monaco")
             when (font-available-p font)
             return (set-face-attribute 'default nil :family font :height 140))
    (cl-loop for font in '("Apple Color Emoji" "Noto Color Emoji")
             when (font-available-p font)
             return (set-fontset-font t 'emoji (font-spec :family font) nil 'prepend))))
(nyan-setup-fonts)
(add-hook 'server-after-make-frame-hook #'nyan-setup-fonts)

;; Theme: Night City Mix (themes/nightcity-mix-theme.el, from night-city-palettes).
(load-theme 'nightcity-mix t)
;; Slight transparency like NyanVim; ghostty behind it is the same #101a1f.
(when (featurep 'ns) (push '(alpha . 94) default-frame-alist))

;; Lines: number + relativenumber, cursorline.
(setq-default display-line-numbers-type 'relative
              display-line-numbers-width 4)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(global-hl-line-mode 1)
(blink-cursor-mode -1)
(column-number-mode 1)
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

(use-package nerd-icons :demand t)

;; lualine → doom-modeline.
(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-height 28)
  (doom-modeline-bar-width 3)
  (doom-modeline-buffer-file-name-style 'relative-to-project)
  (doom-modeline-minor-modes nil)
  (doom-modeline-modal-icon t))

;; which-key: builtin since Emacs 30 (NyanEmacs needs 29.1; on 29 run M-x package-install which-key).
(use-package which-key
  :ensure nil
  :hook (after-init . which-key-mode)
  :custom (which-key-idle-delay 0.3) (which-key-separator " → "))

;; nvim-colorizer → rainbow-mode.
(use-package rainbow-mode :hook (prog-mode css-mode))

;; dashboard-nvim → dashboard.el, same banner and keys (f r p m c q; g is evil's prefix).
(use-package dashboard
  :demand t
  :custom
  (dashboard-startup-banner (expand-file-name "banner.txt" user-emacs-directory))
  (dashboard-banner-logo-title nil)
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-projects-backend 'project-el)
  (dashboard-display-icons-p #'display-graphic-p)
  (dashboard-set-file-icons t)
  (dashboard-set-heading-icons t)
  (dashboard-items '((recents . 6) (projects . 4)))
  (dashboard-item-shortcuts '((recents . "r") (projects . "p")))
  (dashboard-startupify-list '(dashboard-insert-banner dashboard-insert-newline
                               dashboard-insert-navigator dashboard-insert-newline
                               dashboard-insert-items dashboard-insert-newline
                               dashboard-insert-init-info))
  (dashboard-navigator-buttons
   '((("󰈞" "Find file" "f" (lambda (&rest _) (nyan-find-file)))
      ("󰊢" "Git" "m"        (lambda (&rest _) (magit-status)))
      ("󰒓" "Config" "c"     (lambda (&rest _) (nyan-config)))
      ("󰩈" "Quit" "q"       (lambda (&rest _) (save-buffers-kill-terminal))))))
  :config
  (dashboard-setup-startup-hook)
  (with-eval-after-load 'evil
    (evil-define-key 'normal dashboard-mode-map
      "f" #'nyan-find-file "m" #'magit-status "c" #'nyan-config "q" #'save-buffers-kill-terminal)))

(provide 'init-ui)
;;; init-ui.el ends here
