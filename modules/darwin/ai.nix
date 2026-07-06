{ config, lib, ... }:

lib.mkIf config.flags.profiles.ai {
  homebrew.casks = [
    "claude"
    "codex-app"
    "t3-code"
  ];
}
