;;; early-init.el --- Early initialization -*- lexical-binding: t -*-

;;; Commentary:
;; Runs before init.el, before package and UI initialization.
;; Shared by darwin and Linux. We use this for performance-sensitive
;; settings; on darwin, Nix prepends generated code that wires Homebrew
;; Emacs to the Nix-owned package load paths.

;;; Code:

;; Disable GC during startup, then turn it back on.
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 100 1024 1024))))

;; Required for lsp-mode to use plists. It has to be set when it's compiled.
;; See: https://emacs-lsp.github.io/lsp-mode/page/performance/
(setenv "LSP_USE_PLISTS" "true")

;; On darwin, package.el must stay out of the way: the generated preamble
;; above already wires the Nix load paths and autoloads into Homebrew Emacs.
;; On Linux, Emacs itself is built by Nix and exposes its packages
;; ELPA-style, so package.el activation is exactly what loads their
;; autoloads -- leave it enabled there.
(when (eq system-type 'darwin)
  (setq package-enable-at-startup nil))

;; Inhibit frame resizing during startup (avoids visual flicker).
(setq frame-inhibit-implied-resize t)

;; Disable UI elements before they can be drawn. Keep the menu bar on darwin
;; since it's native and expected; hide it elsewhere.
(setq default-frame-alist
      (append '((tool-bar-lines . 0)
                (vertical-scroll-bars . nil)
                (horizontal-scroll-bars . nil))
              (if (eq system-type 'darwin)
                  '((ns-transparent-titlebar . t)
                    (ns-appearance . dark))
                '((menu-bar-lines . 0)))))

;;; early-init.el ends here

;; Local Variables:
;; no-byte-compile: t
;; no-native-compile: t
;; no-update-autoloads: t
;; End:
