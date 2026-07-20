{
  config,
  pkgs,
  lib,
  username,
  ...
}:

let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;

  nushellWithSystemEnvironment = pkgs.writeShellScript "nushell-with-system-environment" ''
    . ${config.system.build.setEnvironment}
    exec ${getExe pkgs.nushell} "$@"
  '';
in
mkIf config.flags.profiles.graphical {
  home-manager.users.${username}.programs.ghostty = {
    enable = true;
    package = mkIf config.flags.system.darwin null;

    settings = {
      command = "${nushellWithSystemEnvironment}";
      font-family = "Inconsolata Nerd Font";
      font-size = 22;
      theme = "Carbonfox";
      background-opacity = 0.93;
      background-blur = config.flags.system.darwin;
      window-padding-x = 8;
    };
  };
}
