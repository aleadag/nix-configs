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
  package = flake.inputs.agent-steward.packages.${pkgs.stdenv.hostPlatform.system}.default;
  spawn = flake.inputs.agent-steward.packages.${pkgs.stdenv.hostPlatform.system}.steward-spawn;
  argvPlugin = flake.inputs.agent-steward + "/herdr-plugins/agent-steward-launcher";
  secretFile = config.sops.secrets.typesafe_api_key.path;
  recoverSource = flake.inputs.agent-steward + "/herdr-plugins/agent-steward-recover";
  stopPlugin =
    pkgs.runCommandLocal "agent-steward-recover-plugin"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p "$out"
        cp -f ${recoverSource}/herdr-plugin.toml "$out/herdr-plugin.toml"
        makeWrapper ${pkgs.runtimeShell} "$out/run.sh" \
          --add-flags ${lib.escapeShellArg "${recoverSource}/run.sh"} \
          --set TYPESAFE_API_KEY_FILE ${lib.escapeShellArg (toString secretFile)} \
          --set AGENT_STEWARD_HERDR_ADAPTER ${lib.escapeShellArg "${package}/bin/agent-steward-herdr-adapter"} \
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
    xdg.configFile."agent-steward/config.json".source = configFile;
    programs.waybar.settings = lib.mkIf waybarEnabled {
      top = {
        modules-right = lib.mkBefore [ "custom/agent-steward" ];
        "custom/agent-steward" = {
          exec = lib.getExe (
            pkgs.writeShellApplication {
              name = "agent-steward-waybar";
              text = ''
                exec ${pkgs.python3}/bin/python3 ${./waybar.py} ${configFile}
              '';
            }
          );
          return-type = "json";
          interval = 30;
        };
      };
    };
    programs.waybar.style = lib.mkIf waybarEnabled (
      lib.mkAfter ''
        #custom-agent-steward {
          background: @base0C;
          color: @base00;
          border-radius: 4px;
          padding: 0 2px;
          margin: 0;
        }
        #custom-agent-steward.warning {
          background: @base0A;
        }
        #custom-agent-steward.critical {
          background: @base08;
        }
        #custom-agent-steward.unknown {
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
        OnCalendar = "hourly";
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
