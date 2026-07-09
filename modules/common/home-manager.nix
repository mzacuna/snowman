{
  config,
  lib,
  system,
  username,
  ...
}:

let
  homeDirectory = config.users.users.${username}.home;
  isDarwin = lib.hasSuffix "-darwin" system;
  xdgSessionVariables = {
    XDG_CACHE_HOME = "${homeDirectory}/.cache";
    XDG_CONFIG_HOME = "${homeDirectory}/.config";
    XDG_DATA_HOME = "${homeDirectory}/.local/share";
    XDG_STATE_HOME = "${homeDirectory}/.local/state";
  };
in

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit username; };

    # Rename pre-existing files instead of failing activation when home-manager
    # wants to manage a path that already exists.
    backupFileExtension = "backup";

    users.${username}.home = {
      homeDirectory = homeDirectory;

      sessionVariables = xdgSessionVariables;
    };
  };
}
// lib.optionalAttrs isDarwin {
  launchd.user.envVariables = xdgSessionVariables;
}
