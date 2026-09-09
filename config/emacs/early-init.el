;;; early-init.el --- NyanEmacs early init  -*- lexical-binding: t; no-byte-compile: t -*-
;; Runs before package.el and the first frame. Startup speed only; see Centaur's
;; early-init.el for the reasoning behind each knob.

;; GC: huge threshold during startup, gcmh (init-base) restores it.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1.0)
(setq read-process-output-max (* 1024 1024))

;; Skip file-name-handler lookups while loading; restore after startup.
(let ((handlers file-name-handler-alist))
  (setq file-name-handler-alist nil)
  (add-hook 'emacs-startup-hook (lambda () (setq file-name-handler-alist handlers)) 101))

(setq native-comp-jit-compilation nil
      native-comp-async-report-warnings-errors 'silent
      package-enable-at-startup nil   ; init-package does it
      load-prefer-newer noninteractive
      frame-inhibit-implied-resize t
      use-package-enable-imenu-support t)
(prefer-coding-system 'utf-8)

;; Bare frame before it is drawn (NyanVim: no chrome, dark ground).
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(background-color . "#101a1f") default-frame-alist)
(push '(foreground-color . "#b6c5d3") default-frame-alist)
(when (featurep 'ns)
  (push '(ns-transparent-titlebar . t) default-frame-alist)
  (push '(ns-appearance . dark) default-frame-alist))
(setq-default mode-line-format nil)   ; no flash of unstyled mode line

;;; early-init.el ends here
