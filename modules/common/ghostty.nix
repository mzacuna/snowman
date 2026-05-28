{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.isPC {
  home-manager.sharedModules = [
    {
      programs.ghostty = {
        enable = true;
        package = lib.mkIf config.isDarwin null;
        settings = {
          command = "${pkgs.fish}/bin/fish";
          font-family = "Inconsolata Nerd Font";
          font-size = 22;
          theme = "Carbonfox";
          background-opacity = 0.93;
          background-blur = config.isDarwin;
          window-padding-x = 8;
        };
      };
    }
  ];
}
