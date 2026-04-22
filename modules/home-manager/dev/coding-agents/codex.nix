{
  config,
  flake,
  lib,
  options,
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
  stopHooksFile = builtins.toJSON {
    hooks = {
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
  };
  mergeTomlScript = pkgs.writeText "codex-merge-config.py" (builtins.readFile ./merge-config.py);
  tomlMergePython = lib.getExe (pkgs.python3.withPackages (ps: [ ps.tomlkit ]));
  renderPrefixRule = pattern: ''prefix_rule(pattern=${builtins.toJSON pattern}, decision="allow")'';
  basicRules =
    lib.concatMapStringsSep "\n" renderPrefixRule sharedPermissions.codexAllowedPrefixRules + "\n";
  hasCodexRulesOption = options.programs.codex ? rules;
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
  superpowersSkills = loadSkills (flake.inputs.superpowers + "/skills");
  obsidianSkills = loadSkills flake.inputs.obsidian-skills;
  mySkills = loadSkills ./skills;

  openaiCuratedSkillsDir = flake.inputs.openai-skills + "/skills/.curated";
  openaiSkillNames = [
    "playwright"
    "playwright-interactive"
    "pdf"
    "frontend-skill"
    "security-best-practices"
    "security-threat-model"
  ];
  openaiSkills = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = openaiCuratedSkillsDir + "/${name}";
    }) openaiSkillNames
  );
in
{
  options.home-manager.dev.coding-agents.codex = {
    enable = lib.mkEnableOption "Codex config" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      file =
        lib.optionalAttrs (!hasCodexRulesOption) {
          "${codexConfigDir}/rules/basic.rules".text = basicRules;
        }
        // lib.optionalAttrs config.home-manager.cli.jujutsu.enable {
          "${codexConfigDir}/hooks.json".text = stopHooksFile;
        };
      activation.mergeCodexConfig = lib.mkIf (isTomlConfig && config.programs.codex.settings != { }) (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          set -euo pipefail

          config_path="${codexConfigPath}"
          backup_ext="''${HOME_MANAGER_BACKUP_EXT:-}"
          backup_path="$config_path''${backup_ext:+.$backup_ext}"
          tmp="$(mktemp)"

          if [ -z "$backup_ext" ] || [ ! -e "$backup_path" ] || [ ! -e "$config_path" ]; then
            rm -f "$tmp"
            exit 0
          fi

          ${tomlMergePython} "${mergeTomlScript}" "$backup_path" "$config_path" "$tmp"

          $DRY_RUN_CMD mv "$tmp" "$config_path"
          $DRY_RUN_CMD rm -f "$backup_path"
        ''
      );
    };

    programs.codex = {
      enable = true;
      enableMcpIntegration = false;
      package = codexPackage;
      settings = {
        analytics.enabled = false;
        approval_policy = "on-request";
        check_for_update_on_startup = false;
        features = {
          codex_hooks = true;
        };
        personality = "pragmatic";
        plugins."github@openai-curated" = {
          enabled = true;
        };
        project_doc_fallback_filenames = [ "CLAUDE.md" ];
        tui = {
          notifications = true;
          status_line = [
            "model-with-reasoning"
            "current-dir"
            "context-remaining"
            "five-hour-limit"
          ];
        };
      };
      context = builtins.readFile ./CONTEXT.md;
      skills = superpowersSkills // obsidianSkills // openaiSkills // jujutsuSkills // mySkills;
    }
    // lib.optionalAttrs hasCodexRulesOption {
      rules = {
        basic = basicRules;
      };
    };
  };
}
