;;; init-base.el --- editor defaults (NyanVim lua/config/options.lua)  -*- lexical-binding: t -*-
;;; Code:

(setq user-full-name "kyuna0312")

;; Files: no backups/swap/lockfiles; persistent undo via undo-fu-session below.
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      auto-revert-verbose nil
      require-final-newline t
      confirm-kill-processes nil
      use-short-answers t
      ring-bell-function #'ignore
      inhibit-startup-screen t
      initial-scratch-message nil)
(global-auto-revert-mode 1)

;; Indentation: 2 spaces, no tabs, no wrap.
(setq-default indent-tabs-mode nil
              tab-width 2
              standard-indent 2
              truncate-lines t
              fill-column 100)

;; Search: ignorecase + smartcase.
(setq case-fold-search t
      search-upper-case t
      isearch-lazy-count t)

;; Scroll: scrolloff 8, no jumpy recentering.
(setq scroll-margin 8
      scroll-conservatively 101
      scroll-preserve-screen-position t
      fast-but-imprecise-scrolling t
      redisplay-skip-fontification-on-input t)
(when (fboundp 'pixel-scroll-precision-mode) (pixel-scroll-precision-mode 1))

;; Splits open right/below and stay where you put them.
(setq split-height-threshold nil
      split-width-threshold 120
      window-combination-resize t)

;; Clipboard = system, mouse on.
(setq select-enable-clipboard t
      select-enable-primary nil
      mouse-yank-at-point t)
(unless (display-graphic-p) (xterm-mouse-mode 1))

;; Bidi off: faster long lines.
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; Remember place, recent files, minibuffer history (BufReadPost mark / oldfiles).
(save-place-mode 1)
(savehist-mode 1)
(use-package recentf
  :ensure nil
  :hook (after-init . recentf-mode)
  :custom (recentf-max-saved-items 200)
  (recentf-exclude '("/tmp/" "/ssh:" "\\.elc$" "/elpa/")))

(electric-pair-mode 1)              ; nvim-autopairs
(delete-selection-mode 1)
(global-subword-mode 1)

;; Undo that survives restarts (undofile = true).
(use-package undo-fu-session
  :hook (after-init . undo-fu-session-global-mode))

;; PATH from the login shell so eglot finds ~/go/bin, node LSPs, etc.
(use-package exec-path-from-shell
  :when (memq window-system '(mac ns))
  :hook (after-init . exec-path-from-shell-initialize)
  :custom (exec-path-from-shell-arguments '("-l")))

;; GC back to sane once we're up (undoes early-init's most-positive-fixnum).
(use-package gcmh
  :hook (emacs-startup . gcmh-mode)
  :custom (gcmh-idle-delay 'auto) (gcmh-high-cons-threshold (* 64 1024 1024)))

(provide 'init-base)
;;; init-base.el ends here
