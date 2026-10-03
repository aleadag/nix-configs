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
  jsonFormat = pkgs.formats.json { };
  configFile = jsonFormat.generate "agent-steward.json" cfg.settings;
  package = flake.inputs.agent-steward.packages.${pkgs.stdenv.hostPlatform.system}.default;
  spawn = pkgs.writeScriptBin "steward-spawn" (builtins.readFile ./spawn.sh);
  argvPlugin = pkgs.runCommandLocal "steward-argv-plugin" { } ''
    mkdir -p "$out"
    cp -f ${./herdr-plugin/herdr-plugin.toml} "$out/herdr-plugin.toml"
    cp -f ${./herdr-plugin/dispatch.sh} "$out/dispatch.sh"
    chmod 0644 "$out/herdr-plugin.toml"
    chmod 0755 "$out/dispatch.sh"
  '';
  secretFile = config.sops.secrets.typesafe_api_key.path;
  stopRun = pkgs.writeShellScript "agent-steward-herdr-plugin-run" ''
    set -eu
    case "''${1-}" in
      event|scheduler) ;;
      *) exit 2 ;;
    esac
    secret_file=${lib.escapeShellArg (toString secretFile)}
    if [ -r "$secret_file" ]; then
      TYPESAFE_API_KEY=$(${pkgs.coreutils}/bin/cat -- "$secret_file")
      export TYPESAFE_API_KEY
    fi
    exec ${lib.escapeShellArg "${package}/bin/agent-steward-herdr-adapter"} "$1"
  '';
  stopPlugin = pkgs.runCommandLocal "agent-steward-stop-plugin" { } ''
    mkdir -p "$out"
    cp -f ${
      flake.inputs.agent-steward + "/plugins/agent-steward/herdr-plugin.toml"
    } "$out/herdr-plugin.toml"
    cp -f ${stopRun} "$out/run.sh"
    ln -s ${package}/bin/agent-steward-herdr-adapter "$out/agent-steward-herdr-adapter"
    chmod 0644 "$out/herdr-plugin.toml"
    chmod 0755 "$out/run.sh"
  '';
  wrapper = import ./wrapper.nix {
    inherit pkgs package configFile;
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
