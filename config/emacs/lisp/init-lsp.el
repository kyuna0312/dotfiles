;;; init-lsp.el --- eglot + tree-sitter + format  -*- lexical-binding: t -*-
;; No Mason here: install servers with brew/npm/go, eglot finds them on PATH.
;; `M-x nyan-health' lists which ones are missing.
;;; Code:

(use-package eglot
  :ensure nil
  :hook (prog-mode . (lambda ()
                       (unless (derived-mode-p 'emacs-lisp-mode 'lisp-mode 'makefile-mode)
                         (eglot-ensure))))
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-config '(:size 0 :format short))
  (eglot-send-changes-idle-time 0.5)
  (eglot-extend-to-xref t))
(use-package consult-eglot :after eglot)

;; Diagnostics: like CursorHold → open_float, eldoc shows them at point.
(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom (flymake-no-changes-timeout 0.5))
(setq eldoc-echo-area-use-multiline-p 2
      eldoc-idle-delay 0.25)

;; nvim-treesitter → treesit-auto (grammars auto-install, *-ts-mode remap).
(use-package treesit-auto
  :hook (after-init . global-treesit-auto-mode)
  :custom (treesit-auto-install 'prompt) (treesit-font-lock-level 4)
  :config (treesit-auto-add-to-auto-mode-alist 'all))

;; conform.nvim → apheleia (stylua, prettier, black, gofmt, rustfmt on PATH).
(use-package apheleia)
(defun nyan-format ()
  "Format buffer: apheleia's formatter if one is configured, else eglot, else indent."
  (interactive)
  (require 'apheleia)
  (cond ((apheleia--get-formatters) (apheleia-format-buffer (apheleia--get-formatters)))
        ((and (fboundp 'eglot-managed-p) (eglot-managed-p)) (eglot-format-buffer))
        (t (indent-region (point-min) (point-max)))))

(use-package markdown-mode :mode ("\\.md\\'" . gfm-mode))

(provide 'init-lsp)
;;; init-lsp.el ends here
