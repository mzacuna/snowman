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
            def search [term: string] {
              ls **/* | where { ($in.name | path basename) =~ $term }
            }

            def value [column: string] {
              get $column | get 0
            }
          '';
        };

        carapace.enable = true;
      };
    };
}
