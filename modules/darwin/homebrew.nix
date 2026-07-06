{
  config,
  inputs,
  lib,
  username,
  ...
}:

let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) elem;

  homebrewEnv = {
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_ENV_HINTS = "1";
    HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
  };

  trustedTaps = [ "jimeh/homebrew-emacs-builds" ];

  mkTap =
    name:
    if elem name trustedTaps then
      {
        inherit name;
        trusted = true;
      }
    else
      name;
in
{
  homebrew = {
    enable = true;

    taps = config.nix-homebrew.taps |> attrNames |> map mkTap;

    onActivation = {
      cleanup = "uninstall";
      extraEnv = homebrewEnv;
    };
    global.autoUpdate = false;
  };

  nix-homebrew = {
    enable = true;

    user = username;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "jimeh/homebrew-emacs-builds" = inputs.homebrew-emacs-builds;
    };
    mutableTaps = false;
  };

  environment.variables = homebrewEnv;
}
