;;; init.el --- Emacs configuration -*- lexical-binding: t -*-

;;; Commentary:
;; A clean, vanilla Emacs configuration, shared by darwin and Linux.
;; Uses Nix for package management; platform-specific behavior is
;; guarded with `system-type' checks.

;;; Code:


;;; -- Package declarations --

(require 'use-package)
(setq use-package-always-ensure nil)

(use-package compat
  :ensure nil)
(use-package transient)


;;; -- Helper functions --

(defun mzacuna/apply-theme (theme)
  "Disable active themes and load THEME (a symbol).
When called interactively, prompt for THEME with completion.
Vanilla `load-theme' stacks themes on top of each other, which produces
visual artifacts; this helper disables active themes first."
  (interactive
   (list (intern (completing-read "Apply custom theme: "
                                  (mapcar #'symbol-name
                                          (custom-available-themes))))))
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t))


;;; -- Housekeeping --

;; Keep ~/.config/emacs clean by redirecting state and cache files.
;; Must be configured before other packages write their files.
(use-package no-littering
  :demand t
  :config
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))


;;; -- Core defaults --

(use-package emacs
  :ensure nil
  :init
  ;; Bumping these meaningfully improves LSP responsiveness.
  ;; LSP servers send large JSON payloads; the default 4 KiB read buffer
  ;; causes many syscalls. 4 MiB is the lsp-mode performance recommendation.
  (setq read-process-output-max (* 4 1024 1024))

  :custom
  ;; TAB does indent-or-complete based on context. Required for Corfu.
  (tab-always-indent 'complete)
  ;; Disable Emacs 30's ispell-based text-mode completion, which
  ;; interferes with Corfu in text buffers.
  (text-mode-ispell-word-completion nil)
  ;; Hide commands in M-x that don't apply to the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Allow opening minibuffers from inside other minibuffers.
  (enable-recursive-minibuffers t)
  ;; Don't let the cursor enter the minibuffer prompt.
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))

  :config
  ;; Encoding
  (set-language-environment "UTF-8")

  ;; General
  (setq load-prefer-newer t
        use-short-answers t
        make-backup-files nil
        sentence-end-double-space nil
        inhibit-startup-screen t
        initial-scratch-message nil
        initial-major-mode 'fundamental-mode
        ring-bell-function #'ignore)

  ;; Visuals
  (setq-default truncate-lines t
                indent-tabs-mode nil
                tab-width 4)
  (column-number-mode 1)
  (show-paren-mode 1)
  (setq show-paren-delay 0)

  ;; Editing
  (electric-pair-mode 1)
  (delete-selection-mode 1)
  ;; Auto-revert buffers when files change on disk (e.g., git checkout).
  (global-auto-revert-mode 1)

  ;; Native macOS-style right-click context menus.
  (context-menu-mode 1)

  ;; Track recently opened files; surfaces in `consult-buffer'.
  (recentf-mode 1)
  ;; Remember cursor position in files across sessions.
  (save-place-mode 1))

;; Treat nested language projects as project roots inside larger monorepos.
;; This keeps LSP workspace roots aligned with the package/crate being edited.
(use-package project
  :ensure nil
  :custom
  (project-vc-extra-root-markers '("Cargo.toml" "pyproject.toml")))

;; Keybindings: text scaling. Bound to both Ctrl (universal muscle memory)
;; and Meta (Mac convention for Cmd-+, Cmd--, Cmd-0).
(use-package emacs
  :ensure nil
  :bind (("C-=" . text-scale-increase)
         ("C-+" . text-scale-increase)
         ("C--" . text-scale-decrease)
         ("C-0" . text-scale-adjust)
         ("M-=" . text-scale-increase)
         ("M-+" . text-scale-increase)
         ("M--" . text-scale-decrease)
         ("M-0" . text-scale-adjust)))

;; Scrolling
(use-package ultra-scroll
  :init
  (setq scroll-conservatively 3
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))


;;; -- macOS integration --

(use-package emacs
  :ensure nil
  :when (eq system-type 'darwin)
  :config
  ;; Use Command as Meta -- the ergonomic choice on Mac.
  (setq ns-command-modifier 'meta
        ns-option-modifier  'none)

  ;; Don't pop up new frames when opening files.
  (setq ns-pop-up-frames nil)

  ;; Keep the menu bar (it's native on macOS and expected).
  (menu-bar-mode 1))

;; Inherit PATH and other env vars from the user's shell.
;; Essential on macOS where GUI apps don't get the shell environment.
(use-package exec-path-from-shell
  :demand t
  :when (eq system-type 'darwin)
  :config
  (exec-path-from-shell-initialize))

;; Apply direnv/nix-direnv environments per buffer before tools like LSP
;; decide which project-local executables are available.
(use-package envrc
  :config
  (envrc-global-mode 1))


;;; -- Themes --

;; Three theme packs available; switch with `M-x mzacuna/apply-theme'.
(use-package modus-themes
  :demand t
  :config
  (setq modus-themes-italic-constructs t
        modus-themes-bold-constructs t)
  (load-theme 'modus-vivendi :no-confirm))

(use-package ef-themes)
(use-package doom-themes)


;;; -- Font ---

(use-package emacs
  :ensure nil
  :config
  (let ((mono "Inconsolata Nerd Font")
        (vari "Inter")
        (size 220))
    ;; Default face: absolute size, set via frame alist for new frames AND
    ;; via set-face-attribute for the current frame.
    (add-to-list 'default-frame-alist `(font . ,(format "%s-%d" mono (/ size 10))))
    (set-face-attribute 'default nil :family mono :height size)
    ;; variable-pitch and fixed-pitch: family-only, with relative height.
    ;; This makes text-scale-adjust scale them proportionally.
    (set-face-attribute 'fixed-pitch    nil :family mono :height 1.0)
    (set-face-attribute 'variable-pitch nil :family vari :height 1.1818)))

;; mixed-pitch reads `fix-height' from the `default' face, which captures
;; an absolute integer (e.g. 180). That breaks `text-scale-adjust' in
;; mixed-pitch buffers — code blocks don't scale because they're remapped
;; to an absolute height. This advice redirects only that one call to
;; read from the `fixed-pitch' face instead, where we keep a relative
;; height (1.0). Both prose and code then scale with `text-scale-adjust'.
(defun mzacuna/mixed-pitch--read-fix-height-from-fixed-pitch (orig-fn &rest args)
  "Around-advice for `mixed-pitch-mode' to make `fix-height' relative."
  (cl-letf* ((orig-face-attribute (symbol-function 'face-attribute))
             ((symbol-function 'face-attribute)
              (lambda (face attr &rest rest)
                (if (and (eq face 'default) (eq attr :height))
                    (apply orig-face-attribute 'fixed-pitch attr rest)
                  (apply orig-face-attribute face attr rest)))))
    (apply orig-fn args)))

(use-package mixed-pitch
  :commands mixed-pitch-mode
  :custom
  (mixed-pitch-set-height t)
  :config
  (advice-add 'mixed-pitch-mode :around
              #'mzacuna/mixed-pitch--read-fix-height-from-fixed-pitch))


;;; Visual (other)

;; Highlight current line on programming buffers.
(use-package hl-line
  :ensure nil
  :hook (prog-mode . hl-line-mode))

(use-package display-line-numbers
  :ensure nil
  :hook ((prog-mode conf-mode) . display-line-numbers-mode)
  :custom
  (display-line-numbers-width-start t))


;;; -- Minibuffer completion --

;; Vertico: minimal, vertical completion UI.
(use-package vertico
  :custom
  (vertico-cycle t)
  :config
  (vertico-mode 1)
  ;; Built into Emacs 31; advice needed in 30 to show the CRM separator
  ;; visibly when reading multiple candidates.
  (when (< emacs-major-version 31)
    (advice-add #'completing-read-multiple :filter-args
                (lambda (args)
                  (cons (format "[CRM%s] %s"
                                (string-replace "[ \t]*" "" crm-separator)
                                (car args))
                        (cdr args))))))

;; Space-separated completion completion style, in any order.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Rich annotations in the minibuffer.
(use-package marginalia
  :demand t
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))
  :config
  (marginalia-mode 1))

;; Enhanced commands.
(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-s r"   . consult-ripgrep)
         ("M-s l"   . consult-line)))

;; Act on whatever is at point or in the minibuffer.
(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings)))

;; Bridge between embark and consult.
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Edit consult-ripgrep results in place.
(use-package wgrep)


;;; -- In-buffer completion --

;; Popup completion-at-point UI.
(use-package corfu
  :demand t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-cycle t)
  ;; Don't close the popup when there's no match, just on the separator.
  ;; Gives more time to backspace and try again.
  (corfu-quit-no-match 'separator)
  :hook
  ;; Documentation popup for the currently-highlighted completion
  ;; candidate.
  (corfu-mode . corfu-popupinfo-mode)
  :config
  (require 'corfu-popupinfo)
  (global-corfu-mode 1))

;; Additional completion-at-point backends. cape-capf-buster is used in
;; the lsp-mode setup below to keep completion candidates consistent
;; when the prefix changes mid-symbol.
(use-package cape
  :config
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))


;;; -- Keybinding discoverability --

(use-package which-key
  :ensure nil
  :config
  (which-key-mode 1))


;;; -- Version control --

(use-package magit
  :bind ("C-c g" . magit-status))


;;; -- Terminal --

(use-package ghostel
  :ensure nil
  :commands (ghostel ghostel-project ghostel-other)
  :custom
  (ghostel-module-auto-install nil))


;;; -- LSP --

;; emacs-lsp-booster must be installed and on PATH. It wraps LSP server
;; processes to handle JSON parsing off the Emacs thread, and requires
;; lsp-use-plists=t (set via LSP_USE_PLISTS in early-init.el).
(defun lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or (when (equal (following-char) ?#)
        (let ((bytecode (read (current-buffer))))
          (when (byte-code-function-p bytecode)
            (funcall bytecode))))
      (apply old-fn args)))

(defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)
             (not (file-remote-p default-directory))
             lsp-use-plists
             (not (functionp 'json-rpc-connection))
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let ((command-from-exec-path (executable-find (car orig-result))))
            (setcar orig-result command-from-exec-path))
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))

(defun mzacuna/lsp-booster-status ()
  "Report whether `emacs-lsp-booster' is active for local LSP commands."
  (interactive)
  (require 'lsp-mode)
  (let* ((json-parser (if (fboundp 'json-parse-buffer)
                          'json-parse-buffer
                        'json-read))
         (resolved-command
          (let ((default-directory (expand-file-name "~/")))
            (lsp-resolve-final-command '("basedpyright-langserver" "--stdio"))))
         (wrapped (equal (car resolved-command) "emacs-lsp-booster")))
    (message
     "lsp-booster: executable=%s, command-advice=%s, json-advice=%s, plists=%s, sample-command=%S"
     (or (executable-find "emacs-lsp-booster") "missing")
     (if (advice-member-p #'lsp-booster--advice-final-command
                          'lsp-resolve-final-command)
         "yes"
       "no")
     (if (advice-member-p #'lsp-booster--advice-json-parse json-parser)
         "yes"
       "no")
     lsp-use-plists
     (if wrapped resolved-command "not wrapped"))))

(defun mzacuna/lsp-reset-project-root ()
  "Forget the LSP session root containing this buffer and restart LSP.
Use this when `lsp-mode' remembered a parent directory, such as a monorepo
root, but the current buffer belongs to a nested project."
  (interactive)
  (require 'lsp-mode)
  (let* ((file (or (buffer-file-name) default-directory))
         (folder (lsp-find-session-folder (lsp-session) file)))
    (unless folder
      (user-error "No LSP session folder contains %s" file))
    (when (yes-or-no-p (format "Remove LSP session folder %s? " folder))
      (lsp-workspace-folders-remove folder)
      (message "Removed %s from the LSP session; restarting LSP for this buffer" folder)
      (lsp-deferred))))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  ;; Per-language hooks.
  :hook ((typescript-ts-mode . lsp-deferred)
         (tsx-ts-mode         . lsp-deferred)
         (js-ts-mode          . lsp-deferred)
         (rust-ts-mode        . lsp-deferred)
         (nix-ts-mode         . lsp-deferred)
         (lsp-mode            . lsp-enable-which-key-integration)
         (lsp-completion-mode . mzacuna/lsp-mode-setup-completion))
  :init
  (setq lsp-keymap-prefix "C-c l"
        lsp-use-plists t)
  ;; Wire up lsp-booster. The advice functions don't do anything if the
  ;; emacs-lsp-booster binary is not found on PATH.
  (advice-add (if (progn (require 'json) (fboundp 'json-parse-buffer))
                  'json-parse-buffer
                'json-read)
              :around #'lsp-booster--advice-json-parse)
  (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)
  ;; Completion: hand off to Corfu via capf rather than lsp-mode's own UI.
  (defun mzacuna/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless))
    ;; Wrap lsp-completion-at-point with cape-capf-buster for consistency
    ;; when the completion prefix changes mid-symbol.
    (setq-local completion-at-point-functions
                (list (cape-capf-buster #'lsp-completion-at-point)
                      #'cape-file
                      #'cape-dabbrev)))
  :config
  (setq lsp-completion-provider :none          ; Corfu handles completion
        lsp-idle-delay 0.5
        lsp-keep-workspace-alive nil            ; shut down server with last buffer
        lsp-enable-snippet nil                  ; no yasnippet in this config
        lsp-headerline-breadcrumb-enable nil    ; handled by mode line / consult-imenu
        lsp-modeline-code-actions-enable nil
        lsp-modeline-diagnostics-enable nil
        lsp-signature-auto-activate t
        lsp-eldoc-enable-hover t
        ;; For .nix files, prefer nixd over nil. nil's default priority is
        ;; higher and would otherwise win. Harmless if nil isn't installed.
        lsp-disabled-clients '((nix-ts-mode . nix-nil))))

;; Sideline diagnostics, hover docs, peek definitions.
(use-package lsp-ui
  :after lsp-mode
  :config
  (setq lsp-ui-sideline-enable t
        lsp-ui-sideline-show-diagnostics t
        lsp-ui-sideline-show-code-actions nil   ; too noisy inline; use C-c l a
        lsp-ui-doc-enable t
        lsp-ui-doc-position 'at-point))

(defun mzacuna/lsp-pyright-deferred ()
  "Load Pyright support and start LSP for the current Python buffer."
  (require 'lsp-pyright)
  (lsp-deferred))

(use-package lsp-pyright
  :custom
  (lsp-pyright-langserver-command "basedpyright")
  :hook (python-ts-mode . mzacuna/lsp-pyright-deferred))


;;; -- Format-on-save --

;; Asynchronous code formatting on save.
(use-package apheleia
  :config
  (apheleia-global-mode 1))


;;; -- Tree-sitter --

(defun mzacuna/treesit-auto-maybe-install-for-buffer ()
  "Ask `treesit-auto' about only the current buffer's grammar."
  (when (treesit-auto--get-mode-recipe)
    (treesit-auto--maybe-install-grammar)))

;; Automatically install and use tree-sitter grammars.
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  ;; Each missing grammar is expensive to probe on macOS, so keep automatic
  ;; tree-sitter handling scoped to languages we use.
  (treesit-auto-langs '(bash javascript json nix python rust toml tsx typescript yaml))
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  ;; Avoid `global-treesit-auto-mode': it advises `set-auto-mode-0' and
  ;; rebuilds the full tree-sitter remap list on every file open.
  (add-hook 'after-change-major-mode-hook
            #'mzacuna/treesit-auto-maybe-install-for-buffer))


;;; -- Language modes --

;; rust-ts-mode's built-in Flymake backend runs rustc against the current file
;; as a standalone crate, so Cargo dependencies look missing. Use LSP
;; diagnostics from rust-analyzer instead.
(defun mzacuna/rust-ts-mode-setup ()
  "Use rust-analyzer diagnostics instead of single-file `rustc' Flymake checks."
  (remove-hook 'flymake-diagnostic-functions #'rust-ts-flymake t))

(use-package rust-ts-mode
  :ensure nil
  :hook (rust-ts-mode . mzacuna/rust-ts-mode-setup))

(use-package nix-ts-mode
  :mode "\\.nix\\'")

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"        . markdown-mode)
         ("\\.markdown\\'"  . markdown-mode))
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
              ("C-c C-e" . markdown-do)))


;;; -- Writing --

;; Centered, soft-wrapped text for writing.
(use-package olivetti
  :commands olivetti-mode
  :config
  (setq olivetti-body-width 74))

(use-package emacs
  :ensure nil
  :config
  (dolist (hook '(markdown-mode-hook gfm-mode-hook org-mode-hook rst-mode-hook))
    (add-hook hook #'mixed-pitch-mode)
    (add-hook hook #'olivetti-mode)))

;; Spell-checking.
(use-package jinx
  :ensure nil
  :bind (("C-c s c" . jinx-correct)
         ("C-c s l" . jinx-languages)
         ("C-c s d" . mzacuna/jinx-save-word-dir-local)
         ("C-c s p" . mzacuna/jinx-save-word-personal))
  :hook (emacs-startup . global-jinx-mode)
  :custom
  (jinx-languages "en_US es_MX")
  :config
  ;; Helper function.
  (defun mzacuna/jinx--act-on-word (action-fn success-message)
    "Extract Jinx word, check validity, and execute ACTION-FN."
    (if-let* ((bounds (jinx--bounds-of-word))
              (word (buffer-substring-no-properties (car bounds) (cdr bounds))))
        (if (jinx--word-valid-p word)
            (message "'%s' is already spelled correctly!" word)
          (progn
            ;; Run whatever specific saving logic we passed to this helper.
            (funcall action-fn word)
            ;; Universally clear the squiggly lines.
            (jinx--recheck-overlays)
            ;; Print the success message.
            (message success-message word)))
      (user-error "No word found at point.")))

  ;; Directory-local save.
  (defun mzacuna/jinx-save-word-dir-local ()
    "Save Jinx word at point to directory-local variables if misspelled."
    (interactive)
    (mzacuna/jinx--act-on-word
     (lambda (word)
       (jinx--save-dir t nil word)
       (dolist (buf (buffer-list))
         (when (and (buffer-file-name buf)
                    (string-suffix-p ".dir-locals.el" (buffer-file-name buf))
                    (buffer-modified-p buf))
           (with-current-buffer buf (save-buffer)))))
     "Added '%s' to directory-local Jinx words!"))

  ;; Personal dictionary save.
  (defun mzacuna/jinx-save-word-personal ()
    "Save Jinx word at point to the primary personal dictionary if misspelled."
    (interactive)
    (mzacuna/jinx--act-on-word
     (lambda (word)
       (jinx--save-personal t ?@ word))
     "Added '%s' to personal dictionary!")))


;;; -- Persist minibuffer history --

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))


;;; init.el ends here

;; Local Variables:
;; no-byte-compile: t
;; no-native-compile: t
;; no-update-autoloads: t
;; End:
