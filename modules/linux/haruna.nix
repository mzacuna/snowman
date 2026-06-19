{
  config,
  lib,
  username,
  ...
}:

let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep;
in
mkIf config.flags.profiles.graphical {
  home-manager.users.${username} =
    { lib, pkgs, ... }:
    {
      home = {
        packages = singleton pkgs.haruna;

        # Merge defaults into mimeapps.list
        activation.harunaMimeDefaults =
          let
            desktop = "org.kde.haruna.desktop";
            types = [
              "video/mp4"
              "video/x-msvideo" # .avi
              "video/quicktime" # .mov
              "video/x-matroska" # .mkv
              "video/webm"
              "video/x-flv"
              "video/x-ms-wmv"
              "application/x-matroska"
            ];
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run ${getExe' pkgs.xdg-utils "xdg-mime"} default ${desktop} ${concatStringsSep " " types}
          '';
      };
    };
}
