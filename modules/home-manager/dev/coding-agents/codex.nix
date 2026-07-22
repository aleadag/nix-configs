{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.codex;
  shared = import ./shared.nix {
    inherit
      config
      lib
      pkgs
      flake
      ;
  };
  inherit (shared.permissions) allowedShellCommands;

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
  renderPrefixRule = pattern: ''prefix_rule(pattern=${builtins.toJSON pattern}, decision="allow")'';
  codexAllowedPrefixRules = map (command: lib.strings.splitString " " command) allowedShellCommands;
  basicRules = lib.concatMapStringsSep "\n" renderPrefixRule codexAllowedPrefixRules + "\n";
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
        defuddle
      ];
      activation.mergeCodexConfig = lib.mkIf (isTomlConfig && config.programs.codex.settings != { }) (
        shared.mkWritableConfigActivation {
          name = "Codex";
          path = codexConfigPath;
          format = "toml";
        }
      );
    };

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      package = codexPackage;
      inherit (shared) plugins;
      profiles.yegge.developer_instructions = shared.yeggeInstructions;
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
      inherit (shared) context;
      skills =
        shared.obsidianSkills
        // lib.optionalAttrs config.home-manager.cli.jujutsu.enable shared.jujutsuSkills
        // shared.localSkills;
    };
  };
}
