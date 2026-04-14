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
  useXdgDirectories =
    config.home.preferXdgDirectories && lib.versionAtLeast (lib.getVersion codexPackage) "0.2.0";
  xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
  codexConfigDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
  jjStopHook = pkgs.writeShellScript "codex-jj-stop-hook" ''
    jj new >/dev/null 2>&1 || true
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
  renderPrefixRule = pattern: ''prefix_rule(pattern=${builtins.toJSON pattern}, decision="allow")'';
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
      file = {
        "${codexConfigDir}/rules/basic.rules".text =
          lib.concatMapStringsSep "\n" renderPrefixRule sharedPermissions.codexAllowedPrefixRules + "\n";
      }
      // lib.optionalAttrs config.home-manager.cli.jujutsu.enable {
        "${codexConfigDir}/hooks.json".text = stopHooksFile;
      };
    };

    programs.codex = {
      enable = true;
      enableMcpIntegration = false;
      package = codexPackage;
      settings = { };
      context = builtins.readFile ./CONTEXT.md;
      skills = superpowersSkills // obsidianSkills // openaiSkills // jujutsuSkills // mySkills;
    };
  };
}
