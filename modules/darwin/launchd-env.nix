{ config, lib, ... }:

let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatLines escapeShellArg;
in
{
  # nix-darwin applies launchd.user.envVariables only during activation,
  # so apply them at login too.
  launchd.user.agents.envVariables.serviceConfig = {
    ProgramArguments = [
      "/bin/sh"
      "-c"
      (
        config.launchd.user.envVariables
        |> mapAttrsToList (name: value: "/bin/launchctl setenv ${name} ${escapeShellArg value}")
        |> concatLines
      )
    ];
    RunAtLoad = true;
  };
}
