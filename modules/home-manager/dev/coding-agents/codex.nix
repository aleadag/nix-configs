{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.codex;
  beadsSuperpowersPlugin = agentsCfg.plugins."beads-superpowers" or null;
  inherit (agentsCfg.permissions)
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
  skillCommands = lib.concatMap (rel: [
    "bash ${config.home.homeDirectory}/${codexConfigDir}/skills/${rel}"
    "${config.home.homeDirectory}/${codexConfigDir}/skills/${rel}"
  ]) agentsCfg.skillScriptRelativePaths;
  renderPrefixRule =
    decision: pattern:
    "prefix_rule(pattern=${builtins.toJSON pattern}, decision=${builtins.toJSON decision})";
  allAllowedShellCommands = allowedShellCommands ++ skillCommands;
  codexPrefixRules = map (command: lib.strings.splitString " " command);
  basicRules =
    lib.concatMapStringsSep "\n" (renderPrefixRule "allow") (codexPrefixRules allAllowedShellCommands)
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
      install -m 644 ${
        config.home.file."${codexConfigDir}/rules/basic.rules".source
      } "$rules_dir/basic.rules"
    '';

    programs.codex = {
      enable = true;
      package = codexPackage;
      rules.basic = basicRules;
      hooks = lib.optionalAttrs (beadsSuperpowersPlugin != null) {
        SessionStart = [
          {
            matcher = "startup|resume|clear|compact";
            hooks = [
              {
                type = "command";
                command = "CODEX_PLUGIN_ROOT=${beadsSuperpowersPlugin} ${beadsSuperpowersPlugin}/hooks/run-hook.cmd session-start";
                async = false;
              }
            ];
          }
        ];
      };
      settings =
        lib.recursiveUpdate
          {
            agents = {
              default_subagent_model = "gpt-5.6-luna";
              default_subagent_reasoning_effort = "xhigh";
            };
            analytics.enabled = false;
            approval_policy = "on-request";
            approvals_reviewer = "auto_review";
            check_for_update_on_startup = false;
            features = {
              apps = false;
              code_mode_host = true;
              context_management.experimental_mode = true;
              hooks = true;
              memories = true;
              network_proxy = {
                enabled = true;
                allow_local_binding = true;
                domains = codexNetworkDomains;
              };
            };
            feedback.enabled = false;
            file_opener = "none";
            model = "gpt-5.6-luna";
            model_reasoning_effort = "xhigh";
            model_reasoning_summary = "auto";
            personality = "none";
            plugins = {
              "build-web-apps@openai-curated".enabled = true;
              "github@openai-curated".enabled = true;
            };
            project_doc_fallback_filenames = [ "CLAUDE.md" ];
            sandbox_workspace_write.network_access = true;
            shell_environment_policy = {
              "inherit" = "all";
              ignore_default_excludes = true;
            };
            suppress_unstable_features_warning = true;
            tui = {
              status_line = [
                "model-with-reasoning"
                "git-branch"
                "context-remaining"
                "five-hour-limit"
                "weekly-limit"
              ];
            };
          }
          (
            lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
              tui = {
                notifications = [ "agent-turn-complete" ];
                notification_condition = "unfocused";
                notification_method = "auto";
              };
            }
          );
      inherit (agentsCfg) context;
      inherit (agentsCfg) skills;
      plugins = lib.attrValues agentsCfg.plugins;
    };
  };
}
