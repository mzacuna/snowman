{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (lib.lists) optionals;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) escapeShellArg toJSON;

  linuxGraphical = config.flags.system.linux && config.flags.profiles.graphical;
  claude = pkgs.llm-agents.claude-code;
  t3code = pkgs.t3code.override { enableCodex = false; };
in
mkIf config.flags.profiles.ai {
  home-manager.users.${username} =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Managed settings for Claude Code's settings.json. Changes to
      # these keys are overwritten on rebuild. Keys not listed here are
      # left untouched, so new keys persist across rebuilds.
      settings = {
        model = "opus";
        effortLevel = "xhigh";
        theme = "auto";
        alwaysThinkingEnabled = true;
        # Transcripts are deleted after this many days.
        cleanupPeriodDays = 3650;
        attribution = {
          commit = "";
          pr = "";
        };
        includeCoAuthoredBy = false; # Deprecated.
      };

      settingsDir = "${config.home.homeDirectory}/.config/claude";
      settingsJSONPath = "${settingsDir}/settings.json";
    in
    {
      programs.codex = {
        enable = true;
        package = pkgs.llm-agents.codex;
      };

      programs.nushell.extraConfig = ''
        def --wrapped claude2 [...args] {
          with-env { CLAUDE_CONFIG_DIR: "${config.home.homeDirectory}/.config/claude-personal" } {
            ${getExe claude} ...$args
          }
        }
      '';

      programs.claude-code = {
        enable = true;
        package = claude;
      };

      home = {
        packages = [
          pkgs.llm-agents.opencode
          pkgs.llm-agents.pi
        ];
        # ++ optionals linuxGraphical [ t3code ];

        sessionVariables.CLAUDE_CONFIG_DIR = settingsDir;

        activation.claudeCodeSettings =
          let
            inherit (lib.hm.dag) entryAfter;

            jq = getExe pkgs.jq;
          in
          entryAfter [ "writeBoundary" ] ''
            _path="${settingsJSONPath}"
            _declared=${escapeShellArg (toJSON settings)}

            # A regular file may hold keys Claude added itself — keep them. A
            # read-only store symlink from a prior generation has nothing worth
            # keeping (it was unwritable), so drop it and rebuild from scratch.
            _existing='{}'
            if [ -L "$_path" ]; then
              $DRY_RUN_CMD rm -f "$_path"
            elif [ -f "$_path" ]; then
              _read="$(${jq} -c . "$_path" 2>/dev/null || true)"
              if [ -n "$_read" ]; then _existing="$_read"; fi
            fi

            # Declared keys win; every other key already in the file is preserved.
            _merged="$(printf '%s' "$_existing" | ${jq} \
              --argjson declared "$_declared" \
              '(. * $declared)
               + { "$schema": "https://json.schemastore.org/claude-code-settings.json" }' \
              2>/dev/null || true)"

            # Only write when the merge produced something, so a transient error
            # never clobbers a good file with an empty one.
            if [ -n "$_merged" ]; then
              mkdir -p "$(dirname "$_path")"
              _tmp="$(mktemp)"
              printf '%s\n' "$_merged" > "$_tmp"
              chmod 600 "$_tmp"
              $DRY_RUN_CMD mv "$_tmp" "$_path"
            fi
          '';
      };
    };
}
