{
  config,
  lib,
  username,
  ...
}:

let
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) hasInfix;
in
mkIf config.flags.profiles.interactive {
  programs = {
    bash.interactiveShellInit = ''
      if shopt -q login_shell && [ -z "''${NO_NU-}" ] && command -v nu > /dev/null; then
        exec nu
      fi
    '';

    zsh.interactiveShellInit = ''
      if [[ -o login && -z "''${NO_NU-}" ]] && command -v nu > /dev/null; then
        exec nu
      fi
    '';
  };

  home-manager.users.${username} =
    { config, ... }:
    {
      programs = {
        nushell = {
          enable = true;

          configDir = "${config.xdg.configHome}/nushell";

          settings.show_banner = false;

          environmentVariables = filterAttrs (
            _name: value: !(hasInfix "$" (toString value))
          ) config.home.sessionVariables;

          extraConfig = ''
            def value [column: string] {
              get $column | get 0
            }

            def ngc [age: string = "7d"] {
              sudo nix-collect-garbage --delete-older-than $age
            }
          '';
        };

        carapace.enable = true;
      };
    };
}
