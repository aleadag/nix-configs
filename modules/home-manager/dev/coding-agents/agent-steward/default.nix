{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.agent-steward;
  waybarEnabled = pkgs.stdenv.hostPlatform.isLinux && config.programs.waybar.enable;
  jsonFormat = pkgs.formats.json { };
  configFile = jsonFormat.generate "agent-steward.json" cfg.settings;
  waybarPools = lib.imap0 (index: pool: pool // { name = "agent-steward-${toString index}"; }) (
    lib.unique (
      map
        (candidate: {
          bucket = candidate.quota_bucket;
          pool = candidate.quota_pool;
        })
        (
          lib.filter (
            candidate:
            lib.elem candidate.tool cfg.settings.tools
            && (candidate.billing or "subscription") == "subscription"
          ) cfg.settings.candidates
        )
    )
  );
  waybarModules = lib.listToAttrs (
    map (
      pool:
      lib.nameValuePair "custom/${pool.name}" {
        exec = lib.getExe (
          pkgs.writeShellApplication {
            name = "${pool.name}-waybar";
            text = ''
              exec ${pkgs.python3}/bin/python3 ${./waybar.py} ${configFile} ${
                lib.escapeShellArgs [
                  pool.bucket
                  pool.pool
                ]
              }
            '';
          }
        );
        return-type = "json";
        escape = false;
        interval = 30;
      }
    ) waybarPools
  );
  waybarSelectors =
    suffix: lib.concatMapStringsSep ", " (pool: "#custom-${pool.name}${suffix}") waybarPools;
  approvalConfigFile = jsonFormat.generate "agent-steward-targets.json" {
    auto_approve = cfg.autoApprove;
  };
  package = flake.inputs.agent-steward.packages.${pkgs.stdenv.hostPlatform.system}.default;
  spawn = flake.inputs.agent-steward.packages.${pkgs.stdenv.hostPlatform.system}.steward-spawn;
  argvPlugin = "${package}/share/agent-steward/herdr-plugins/agent-steward-launcher";
  secretFile = config.sops.secrets.typesafe_api_key.path;
  recoverPlugin = "${package}/share/agent-steward/herdr-plugins/agent-steward-recover";
  stopPlugin =
    pkgs.runCommandLocal "agent-steward-recover-plugin"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p "$out"
        cp -f ${recoverPlugin}/herdr-plugin.toml "$out/herdr-plugin.toml"
        makeWrapper ${pkgs.runtimeShell} "$out/run.sh" \
          --add-flags ${lib.escapeShellArg "${recoverPlugin}/run.sh"} \
          --set TYPESAFE_API_KEY_FILE ${lib.escapeShellArg (toString secretFile)} \
          --prefix PATH : ${pkgs.coreutils}/bin
      '';
  wrapper = import ./wrapper.nix {
    inherit pkgs package;
    inherit secretFile;
  };
in
{
  options.home-manager.dev.coding-agents.agent-steward = {
    enable = lib.mkEnableOption "agent-steward" // {
      default = agentsCfg.enable;
    };
    autoApprove = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable best-effort permission approval through the Herdr recover plugin";
    };
    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Declarative nonsensitive agent-steward inventory and settings";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.home-manager.sops.enable;
        message = "agent-steward requires home-manager.sops.enable.";
      }
    ];
    sops.secrets.typesafe_api_key = {
      key = "typesafe_api_key";
      mode = "0600";
    };
    home.packages = [
      wrapper
      spawn
    ];
    home.shellAliases.stw = "agent-steward";
    xdg.configFile."agent-steward/config.json".source = configFile;
    xdg.configFile."herdr/plugins/config/agent-steward-recover/targets.json".source =
      approvalConfigFile;
    programs.waybar.settings = lib.mkIf waybarEnabled {
      top = {
        modules-right = lib.mkBefore (map (pool: "custom/${pool.name}") waybarPools);
      }
      // waybarModules;
    };
    programs.waybar.style = lib.mkIf (waybarEnabled && waybarPools != [ ]) (
      lib.mkAfter ''
        ${waybarSelectors ""} {
          background: @base0C;
          color: @base00;
          border-radius: 4px;
          padding: 0 6px;
          margin: 0 2px;
        }
        ${waybarSelectors ".critical"} {
          background: @base08;
        }
        ${waybarSelectors ".unknown"} {
          background: @base01;
          color: @base04;
        }
      ''
    );
    systemd.user.services.agent-steward-quota-refresh = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "Refresh agent-steward quota snapshots";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${wrapper}/bin/agent-steward quota refresh";
        Nice = 10;
      };
    };
    systemd.user.timers.agent-steward-quota-refresh = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit.Description = "Hourly agent-steward quota refresh";
      Timer = {
        OnCalendar = "*:0/15";
        Persistent = true;
        RandomizedDelaySec = 300;
      };
      Install.WantedBy = [ "timers.target" ];
    };
    home-manager.dev.coding-agents.herdr.plugins = lib.mkIf agentsCfg.herdr.enable [
      argvPlugin
      stopPlugin
    ];
    home-manager.dev.coding-agents.agent-steward.settings = lib.mapAttrsRecursive (
      _: value: lib.mkDefault value
    ) (import ./config.nix);
    home-manager.dev.coding-agents.skills.agent-to-agent = ../skills/agent-to-agent;
    home-manager.dev.coding-agents.skills.agent-steward =
      flake.inputs.agent-steward + "/skills/agent-steward";
  };
}
