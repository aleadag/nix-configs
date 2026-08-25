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
  inherit (shared.permissions)
    allowedShellCommands
    commonNetworkDomains
    deniedShellCommands
    ;

  codexDomains = lib.concatMap (domain: [
    domain
    "*.${domain}"
  ]) commonNetworkDomains;
  codexNetworkDomains = lib.genAttrs codexDomains (lib.const "allow");

  codexPackage = pkgs.llm-agents.codex;
  codexVersion = lib.getVersion codexPackage;
  isTomlConfig = lib.versionAtLeast codexVersion "0.2.0";
  useXdgDirectories = config.home.preferXdgDirectories && isTomlConfig;
  xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
  codexConfigDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
  codexConfigPath = "${config.home.homeDirectory}/${codexConfigDir}/config.toml";
  renderPrefixRule =
    decision: pattern:
    "prefix_rule(pattern=${builtins.toJSON pattern}, decision=${builtins.toJSON decision})";
  codexPrefixRules = map (command: lib.strings.splitString " " command);
  basicRules =
    lib.concatMapStringsSep "\n" (renderPrefixRule "allow") (codexPrefixRules allowedShellCommands)
    + "\n"
    + lib.concatMapStringsSep "\n" (renderPrefixRule "forbidden") (codexPrefixRules deniedShellCommands)
    + "\n";
in
{
  options.home-manager.dev.coding-agents.codex = {
    enable = lib.mkEnableOption "Codex config" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    mutableConfig.files.${codexConfigPath} = lib.mkIf isTomlConfig {
      source = config.home.file."${codexConfigDir}/config.toml".source;
    };

    # The home-manager codex module writes `rules` as symlinks into the store,
    # but codex's execpolicy loader skips symlinked `.rules` files, so the
    # rules are silently ignored. Write a regular file via activation instead.
    home.activation.writeCodexRules = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rules_dir="${config.home.homeDirectory}/${codexConfigDir}/rules"
      mkdir -p "$rules_dir"
      rm -f "$rules_dir/basic.rules"
      install -m 644 ${pkgs.writeText "codex-basic.rules" basicRules} "$rules_dir/basic.rules"
    '';

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      package = codexPackage;
      plugins = shared.pluginSources;
      hooks = lib.optionalAttrs config.home-manager.cli.jujutsu.enable {
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = shared.jjStopHook;
              }
            ];
          }
        ];
      };
      settings = {
        analytics.enabled = false;
        approval_policy = "on-request";
        approvals_reviewer = "auto_review";
        check_for_update_on_startup = false;
        features = {
          apps = false;
          code_mode_host = true;
          hooks = true;
          memories = true;
          network_proxy = {
            enabled = true;
            domains = codexNetworkDomains;
          };
        };
        model = "gpt-5.6-sol";
        model_reasoning_effort = "medium";
        plan_mode_reasoning_effort = "high";
        personality = "pragmatic";
        plugins = {
          "build-web-apps@openai-curated".enabled = true;
          "github@openai-curated".enabled = true;
        };
        project_doc_fallback_filenames = [ "CLAUDE.md" ];
        sandbox_workspace_write.network_access = true;
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
      context = shared.defaultContext;
      skills = shared.guardedSkills;
    };
  };
}
