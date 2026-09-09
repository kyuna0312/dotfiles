;;; init.el --- NyanEmacs  -*- lexical-binding: t; no-byte-compile: t -*-
;;
;;   /\_/\   NyanEmacs — NyanVim's keys and Night City look, Centaur's bones.
;;  ( ^.^ )  One module per file under lisp/, read it in one sitting.
;;   > ^ <   Overrides go in user.el (git-ignored), Custom junk in custom.el.
;;
;; Layout (Centaur): early-init.el → init.el → lisp/init-*.el → custom.el → user.el

(when (version< emacs-version "29.1")
  (error "NyanEmacs needs Emacs 29.1 or newer (you have %s)" emacs-version))

(setq auto-mode-case-fold nil)
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))

(require 'init-package)     ; package.el + use-package
(require 'init-base)        ; NyanVim options.lua, translated
(require 'init-ui)          ; theme, font, modeline, dashboard
(require 'init-evil)        ; evil + <space> leader keymaps (NyanVim keymaps.lua)
(require 'init-completion)  ; vertico/consult (telescope) + corfu (cmp)
(require 'init-lsp)         ; eglot + tree-sitter + format-on-demand
(require 'init-tools)       ; magit, treemacs, terminal, todo
(require 'nyanemacs)        ; M-x nyan-* commands + cowboy discipline

;; custom.el: what Customize writes. user.el: your overrides. Both git-ignored.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)
(load (expand-file-name "user" user-emacs-directory) 'noerror 'nomessage)

;;; init.el ends here
