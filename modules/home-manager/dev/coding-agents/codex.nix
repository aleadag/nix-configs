{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.codex;
  sharedPermissions = import ./permissions.nix { inherit lib; };
  codexPackage = pkgs.llm-agents.codex;
  codexVersion = lib.getVersion codexPackage;
  isTomlConfig = lib.versionAtLeast codexVersion "0.2.0";
  useXdgDirectories = config.home.preferXdgDirectories && isTomlConfig;
  xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
  codexConfigDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
  codexConfigPath = "${config.home.homeDirectory}/${codexConfigDir}/config.toml";
  jjStopHook = pkgs.writeShellScript "codex-jj-stop-hook" ''
    if jj root >/dev/null 2>&1 && [ -n "$(jj diff --summary 2>/dev/null)" ]; then
      jj new >/dev/null 2>&1 || true
    fi
    printf '%s\n' '{"continue":true}'
  '';
  mergeTomlScript = pkgs.writeText "codex-merge-config.py" (builtins.readFile ./merge-config.py);
  tomlMergePython = lib.getExe (pkgs.python3.withPackages (ps: [ ps.tomlkit ]));
  renderPrefixRule = pattern: ''prefix_rule(pattern=${builtins.toJSON pattern}, decision="allow")'';
  basicRules =
    lib.concatMapStringsSep "\n" renderPrefixRule sharedPermissions.codexAllowedPrefixRules + "\n";
  loadSkills =
    dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = dir + "/${name}";
      }) (builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries))
    );
  jujutsuSkills = loadSkills flake.inputs.jujutsu-skills;
  obsidianSkills = loadSkills flake.inputs.obsidian-skills;
  mySkills = loadSkills ./skills;
in
{
  options.home-manager.dev.coding-agents.codex = {
    enable = lib.mkEnableOption "Codex config" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        llm-agents.beads
        llm-agents.beads-viewer
        codexctl
        defuddle
      ];
      activation.mergeCodexConfig = lib.mkIf (isTomlConfig && config.programs.codex.settings != { }) (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          set -euo pipefail

          config_path="${codexConfigPath}"
          backup_ext="''${HOME_MANAGER_BACKUP_EXT:-}"
          backup_path="$config_path''${backup_ext:+.$backup_ext}"
          tmp="$(mktemp)"

          if [ ! -e "$config_path" ]; then
            rm -f "$tmp"
          elif [ -n "$backup_ext" ] && [ -e "$backup_path" ]; then
            ${tomlMergePython} "${mergeTomlScript}" "$backup_path" "$config_path" "$tmp"

            if ! ${pkgs.diffutils}/bin/cmp -s "$backup_path" "$tmp"; then
              echo "Merged Codex config changes:"
              ${pkgs.diffutils}/bin/diff -u "$backup_path" "$tmp" || true
            fi

            $DRY_RUN_CMD mv "$tmp" "$config_path"
            $DRY_RUN_CMD rm -f "$backup_path"
          elif [ -L "$config_path" ] && [[ "$(readlink "$config_path")" == /nix/store/* ]]; then
            if [[ -v DRY_RUN ]]; then
              echo "cat '$config_path' > '$tmp'"
            else
              cat "$config_path" > "$tmp"
            fi

            $DRY_RUN_CMD mv "$tmp" "$config_path"
          else
            rm -f "$tmp"
          fi
        ''
      );
    };

    systemd.user.services.codexctl-headless = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit.Description = "codexctl headless";

      Install.WantedBy = [ "default.target" ];

      Service = {
        Environment = [
          "PATH=${lib.makeBinPath [ codexPackage ]}:${config.home.profileDirectory}/bin"
        ];
        ExecStart = "${lib.getExe pkgs.codexctl} --headless --json --interval 2000";
        Restart = "on-failure";
      };
    };

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      package = codexPackage;
      plugins = [
        (pkgs.fetchFromGitHub {
          name = "beads-superpowers";
          owner = "DollarDill";
          repo = "beads-superpowers";
          rev = "d48ccb9ea91a1ffa485965c7efbaa98f63e8bfbe";
          hash = "sha256-MHgKiCE5rn4L3ZcdTiDTeTXTo81dFBXccTR7GHbrlsk=";
        })
      ];
      rules.basic = basicRules;
      hooks = lib.optionalAttrs config.home-manager.cli.jujutsu.enable {
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = jjStopHook;
              }
            ];
          }
        ];
      };
      settings = {
        analytics.enabled = false;
        approval_policy = "on-request";
        check_for_update_on_startup = false;
        features = {
          apps = false;
          code_mode_host = false;
          hooks = true;
          memories = true;
        };
        model = "gpt-5.6-sol";
        model_reasoning_effort = "high";
        plan_mode_reasoning_effort = "xhigh";
        personality = "pragmatic";
        plugins = {
          "build-web-apps@openai-curated".enabled = true;
          "github@openai-curated".enabled = true;
        };
        project_doc_fallback_filenames = [ "CLAUDE.md" ];
        tui = {
          notifications = true;
          status_line = [
            "model-with-reasoning"
            "git-branch"
            "context-remaining"
            "five-hour-limit"
            "weekly-limit"
          ];
        };
      };
      context = builtins.readFile ./CONTEXT.md;
      skills = obsidianSkills // jujutsuSkills // mySkills;
    };
  };
}
