{
  config,
  lib,
  username,
  ...
}:

let
  inherit (lib.modules) mkIf;
in
mkIf config.flags.profiles.interactive {
  home-manager.users.${username}.programs.zoxide = {
    enable = true;

    options = [
      "--cmd"
      "cd"
    ];
  };
}
