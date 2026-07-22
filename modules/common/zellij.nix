{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
in
mkIf config.flags.profiles.interactive {
  home-manager.users.${username} = {
    home.shellAliases = {
      zj = "zellij";
      zja = "zellij attach --create";
      zjl = "zellij list-sessions";
    };

    programs.zellij = {
      enable = true;

      settings = {
        default_shell = getExe pkgs.nushell;
        default_layout = "compact";
        pane_frames = false;
        theme = "gruvbox-dark";
      };
    };
  };
}
