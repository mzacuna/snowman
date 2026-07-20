{
  config,
  lib,
  username,
  ...
}:

let
  inherit (lib.attrsets) optionalAttrs;
in
{
  home-manager.users.${username} = {
    home.shellAliases = optionalAttrs config.flags.profiles.interactive {
      g = "git";
      o = "bat --plain";
      p = "bat --plain --paging=auto";
    };

    programs.starship = {
      enable = true;

      settings = {
        cmd_duration.min_time = 30000; # 30 seconds.
        add_newline = false;
        status.disabled = false;
        directory.truncation_length = 4;
        git_branch.truncation_length = 24;
      };
    };
  };
}
