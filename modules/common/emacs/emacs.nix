{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (lib.lists) singleton;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) package raw;
in
{
  options.emacs = {
    packageOverrides = mkOption {
      type = raw;
      readOnly = true;
      internal = true;
      description = "Extension applied to the emacsPackages scope on every platform.";
      default = _final: prev: {
        # lsp-mode needs this env var at byte-compile time to use
        # plists, which are faster.
        lsp-mode = prev.lsp-mode.overrideAttrs (old: {
          env = (old.env or { }) // {
            LSP_USE_PLISTS = "true";
          };
        });
      };
    };

    packages = mkOption {
      type = raw;
      readOnly = true;
      internal = true;
      description = "Shared package selection, as a function of the emacsPackages scope.";
      default = epkgs: [
        epkgs.apheleia
        epkgs.cape
        epkgs.compat
        epkgs.consult
        epkgs.corfu
        epkgs.doom-themes
        epkgs.ef-themes
        epkgs.embark
        epkgs.embark-consult
        epkgs.envrc
        epkgs.exec-path-from-shell
        epkgs.ghostel
        epkgs.jinx
        epkgs.lsp-mode
        epkgs.lsp-pyright
        epkgs.lsp-ui
        epkgs.magit
        epkgs.marginalia
        epkgs.markdown-mode
        epkgs.mixed-pitch
        epkgs.modus-themes
        epkgs.nix-ts-mode
        epkgs.no-littering
        epkgs.olivetti
        epkgs.orderless
        epkgs.transient
        epkgs.treesit-auto
        epkgs.ultra-scroll
        epkgs.vertico
        epkgs.wgrep
      ];
    };

    spellingDictionaries = mkOption {
      type = package;
      readOnly = true;
      internal = true;
      description = "Hunspell dictionaries for jinx/enchant; point DICPATH at share/hunspell.";
      default = pkgs.buildEnv {
        name = "emacs-spelling-dictionaries";
        paths = [
          pkgs.hunspellDicts.en_US
          pkgs.hunspellDicts.es_MX
        ];
        pathsToLink = [
          "/share/hunspell"
          "/share/myspell"
        ];
      };
    };
  };

  config = mkIf config.flags.profiles.graphical {
    home-manager.users.${username}.home = {
      packages = singleton pkgs.emacs-lsp-booster;

      file.".config/emacs/init.el".source = ./init.el;

      sessionVariables = {
        EDITOR = "emacsclient -t";
        ALTERNATE_EDITOR = "emacs -nw";
      };
    };
  };
}
