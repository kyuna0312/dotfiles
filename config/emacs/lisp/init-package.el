;;; init-package.el --- package.el + use-package  -*- lexical-binding: t -*-
;;; Code:

(require 'package)
(setq package-archives '(("gnu"    . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa"  . "https://melpa.org/packages/"))
      package-archive-priorities '(("gnu" . 2) ("nongnu" . 1) ("melpa" . 0)))
(package-initialize)

;; First launch: refresh once so every :ensure below can resolve (lazy.nvim's
;; "plugins install themselves on the first launch").
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-defer t
      use-package-expand-minimally t)

;; Keep the installed list in package.el, not custom.el (Centaur hack).
(advice-add #'package--save-selected-packages :override
            (lambda (&optional value) (when value (setq package-selected-packages value))))

(provide 'init-package)
;;; init-package.el ends here
