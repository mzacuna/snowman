{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (lib.lists) singleton;

  emacsPkgs = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).overrideScope config.emacs.packageOverrides;

  emacs = emacsPkgs.emacsWithPackages (
    epkgs:
    config.emacs.packages epkgs
    ++ [
      # Keep in sync with `treesit-auto-langs' in init.el.
      (epkgs.treesit-grammars.with-grammars (grammars: [
        grammars.tree-sitter-bash
        grammars.tree-sitter-javascript
        grammars.tree-sitter-json
        grammars.tree-sitter-nix
        grammars.tree-sitter-python
        grammars.tree-sitter-rust
        grammars.tree-sitter-toml
        grammars.tree-sitter-tsx
        grammars.tree-sitter-typescript
        grammars.tree-sitter-yaml
      ]))
    ]
  );
in
lib.mkIf config.flags.profiles.graphical {
  # For jinx/enchant.
  environment.sessionVariables.DICPATH = "${config.emacs.spellingDictionaries}/share/hunspell";

  home-manager.users.${username}.home = {
    packages = singleton emacs;
    file.".config/emacs/early-init.el".source = ../common/emacs/early-init.el;
  };
}
