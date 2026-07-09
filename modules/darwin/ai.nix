{
  config,
  lib,
  username,
  ...
}:

let
  homeDirectory = config.users.users.${username}.home;
in
lib.mkIf config.flags.profiles.ai {
  homebrew.casks = [
    "claude"
    "codex-app"
    "t3-code"
  ];

  launchd.user.envVariables.CLAUDE_CONFIG_DIR = "${homeDirectory}/.config/claude";
}
