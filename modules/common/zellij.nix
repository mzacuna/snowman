{
  config,
  lib,
  username,
  ...
}:

lib.mkIf config.flags.profiles.interactive {
  home-manager.users.${username} = {
    home.shellAliases = {
      zj = "zellij";
      zja = "zellij attach --create";
      zjl = "zellij list-sessions";
    };

    programs.zellij.enable = true;
  };
}
