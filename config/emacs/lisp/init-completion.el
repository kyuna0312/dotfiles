;;; init-completion.el --- telescope → vertico/consult, cmp → corfu  -*- lexical-binding: t -*-
;;; Code:

(use-package vertico
  :hook (after-init . vertico-mode)
  :custom (vertico-cycle t) (vertico-count 12)
  :bind (:map vertico-map
         ("C-j" . vertico-next) ("C-k" . vertico-previous)
         ("C-n" . vertico-next) ("C-p" . vertico-previous)))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia :hook (after-init . marginalia-mode))
(use-package nerd-icons-completion
  :after marginalia
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup))

(use-package consult
  :custom
  (consult-narrow-key "<")
  (consult-preview-key '(:debounce 0.2 any))
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref))

;; <leader>* / <leader>sw: grep the word under point.
(defun consult-ripgrep-symbol-at-point ()
  "Ripgrep the project for the symbol at point."
  (interactive)
  (consult-ripgrep nil (thing-at-point 'symbol t)))

;; nvim-cmp → corfu (popup, no tab-fight). LSP + path + buffer words via cape.
(use-package corfu
  :hook (after-init . global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-count 10)
  (corfu-cycle t)
  (corfu-preselect 'prompt)          ; noselect
  (tab-always-indent 'complete)
  :bind (:map corfu-map
         ("C-j" . corfu-next) ("C-k" . corfu-previous)
         ("TAB" . corfu-next) ("S-TAB" . corfu-previous)
         ("RET" . corfu-insert)))
(use-package nerd-icons-corfu
  :after corfu
  :demand t
  :config (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))
(use-package cape
  :demand t
  :config
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

;; friendly-snippets → yasnippet-snippets.
(use-package yasnippet :hook (after-init . yas-global-mode))
(use-package yasnippet-snippets :after yasnippet :demand t)

(provide 'init-completion)
;;; init-completion.el ends here
