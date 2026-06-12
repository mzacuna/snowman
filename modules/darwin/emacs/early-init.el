;;; early-init.el --- Early initialization -*- lexical-binding: t -*-

;;; Commentary:
;; Runs before init.el, before package and UI initialization.
;; We use this for performance-sensitive settings and to disable package.el
;; in favor of Nix-owned load paths.

;;; Code:

;; Disable GC during startup, then turn it back on.
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 100 1024 1024))))

;; Required for lsp-mode to use plists. It has to be set when it's compiled.
;; See: https://emacs-lsp.github.io/lsp-mode/page/performance/
(setenv "LSP_USE_PLISTS" "true")

;; Prevent package.el loading packages since Nix provides package load paths.
(setq package-enable-at-startup nil)

;; Inhibit frame resizing during startup (avoids visual flicker).
(setq frame-inhibit-implied-resize t)

;; Disable UI elements before they can be drawn. Keep the menu bar on darwin
;; since it's native and expected.
(setq default-frame-alist
      '((tool-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        (ns-transparent-titlebar . t)
        (ns-appearance . dark)))

;;; early-init.el ends here

;; Local Variables:
;; no-byte-compile: t
;; no-native-compile: t
;; no-update-autoloads: t
;; End:
