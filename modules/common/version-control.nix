{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (lib.lists) singleton;
in
lib.mkIf config.flags.profiles.interactive {
  home-manager.users.${username} = {
    home.packages = singleton pkgs.gh;

    programs = {
      git = {
        enable = true;

        settings = {
          user = {
            name = "Martín Zamorano";
            email = "martin@mzamorano.com";
          };

          init.defaultBranch = "main";
          color.ui = "auto";
          pull.rebase = false;

          alias = {
            "a" = "add";
            "aa" = "add -A";
            "s" = "status";
            "d" = "diff";
            "co" = "checkout";
            "br" = "branch";
            "cf" = "commit"; # commit full; as in, a full message
            "cc" = "commit -m"; # commit concise
            "unstage" = "restore --staged";
            "unstage-all" = "restore --staged :/";
            "last" = "log -1 HEAD";
            "lg" =
              "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          };
        };

        ignores = [
          ".idea"
          ".direnv"
          ".envrc"
          ".env"
          "*~"
          ".fuse_hidden*"
          ".directory"
          ".Trash-*"
          ".nfs*"
          "nohup.out"
          ".DS_Store"
          ".AppleDouble"
          ".LSOverride"
          "Icon"
          "._*"
          "Thumbs.db"
          ".Spotlight-V100"
          ".Trashes"
          ".claude/settings.local.json"
        ];
      };

      fish.functions.ppick.body = ''
        set worktree_path (mktemp -d)
        or return

        git worktree add --detach $worktree_path upstream/main
        or return

        set -l commits $argv
        set -q commits[1]; or set commits (git rev-parse HEAD)
        or return

        git -C $worktree_path cherry-pick $commits
        or return

        git -C $worktree_path push publish HEAD:main
        and git worktree remove $worktree_path
        and git fetch upstream
        and git merge upstream/main -m "sync"
      '';
    };
  };
}
