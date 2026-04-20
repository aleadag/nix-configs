{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.openclaw;
  homeDir = config.home.homeDirectory;
  activeConfigPath = "${homeDir}/.openclaw/openclaw.active.json";
  collectSkillPaths =
    baseDir:
    let
      entries = builtins.readDir baseDir;
      names = builtins.attrNames entries;
      isSkillDir =
        name: entries.${name} == "directory" && builtins.pathExists (baseDir + "/${name}/SKILL.md");
    in
    map (name: builtins.unsafeDiscardStringContext (toString (baseDir + "/${name}"))) (
      lib.filter isSkillDir names
    );
  lifewikiSkillsPluginSource =
    let
      input = flake.inputs.lifewiki-skills;
    in
    "github:aleadag/lifewiki-skills/${input.rev}?narHash=${input.narHash}";
  obsidianSkillsDir =
    if builtins.pathExists (flake.inputs.obsidian-skills.outPath + "/skills") then
      flake.inputs.obsidian-skills.outPath + "/skills"
    else
      flake.inputs.obsidian-skills.outPath;
  obsidianSkillPaths = collectSkillPaths obsidianSkillsDir;
  realiseSymlink = "${pkgs.realise-symlink}/bin/realise-symlink";
  secretOpts = lib.optionalAttrs (cfg.sopsFile != null) {
    inherit (cfg) sopsFile;
  };

  # Helper to convert feishu account id to env var name part (e.g. "main" -> "MAIN")
  toEnv = id: lib.toUpper (lib.replaceStrings [ "-" "." ] [ "_" "_" ] id);
  feishuAccount = "main";
in
{
  options.home-manager.openclaw = {
    enable = lib.mkEnableOption "openclaw";

    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional SOPS file for OpenClaw secrets. When null, uses the global
        `sops.defaultSopsFile`.
      '';
    };

    gatewayPort = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "The port the OpenClaw gateway will listen on.";
    };

    workspace = lib.mkOption {
      type = lib.types.str;
      default = "~/.openclaw/workspace";
      description = "The workspace directory for the OpenClaw agent.";
    };

    extraAgentConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra configuration merged into the OpenClaw agent config.";
    };

    extraInstanceConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra configuration merged into the OpenClaw instance config.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = lib.mkMerge [
        { "openclaw/token" = secretOpts; }
        { "openclaw/zai_api_key" = secretOpts; }
        { "openclaw/feishu/${feishuAccount}/app_id" = secretOpts; }
        { "openclaw/feishu/${feishuAccount}/app_secret" = secretOpts; }
      ];

      templates.openclaw-env = {
        content = ''
          OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder."openclaw/token"}
          FEISHU_${toEnv feishuAccount}_APP_ID=${
            config.sops.placeholder."openclaw/feishu/${feishuAccount}/app_id"
          }
          FEISHU_${toEnv feishuAccount}_APP_SECRET=${
            config.sops.placeholder."openclaw/feishu/${feishuAccount}/app_secret"
          }
        '';
        path = "${config.home.homeDirectory}/.openclaw/.env";
      };
    };

    programs.openclaw = {
      package = pkgs.llm-agents.openclaw;
      documents = ./docs;
      skills = map (source: {
        name = builtins.baseNameOf source;
        inherit source;
        mode = "copy";
      }) obsidianSkillPaths;
      customPlugins = [
        {
          source = lifewikiSkillsPluginSource;
          config.env = {
            LIFEWIKI_VAULT = toString (
              pkgs.writeText "openclaw-lifewiki-vault-path" "${config.home.homeDirectory}/Lifewiki"
            );
          };
        }
      ];

      instances.default = {
        inherit (cfg) gatewayPort;
        package = pkgs.llm-agents.openclaw;
        workspaceDir = cfg.workspace;

        enable = true;
        config = lib.recursiveUpdate {
          agents.defaults = lib.recursiveUpdate {
            inherit (cfg) workspace;
            model = {
              primary = "openai-codex/gpt-5.4";
              fallbacks = [
                "openai-codex/gpt-5.3-codex-spark"
              ];
            };
          } cfg.extraAgentConfig;

          auth = {
            profiles."openai-codex:default" = {
              provider = "openai-codex";
              mode = "oauth";
            };

            order."openai-codex" = [ "openai-codex:default" ];
          };

          channels.feishu = {
            enabled = true;
            dmPolicy = "open";
            allowFrom = [ "*" ];
            accounts.${feishuAccount} = {
              appId = "\${FEISHU_${toEnv feishuAccount}_APP_ID}";
              appSecret = "\${FEISHU_${toEnv feishuAccount}_APP_SECRET}";
            };
          };

          gateway = {
            mode = "local";
            port = cfg.gatewayPort;
            auth = {
              mode = "token";
              token = "\${OPENCLAW_GATEWAY_TOKEN}";
            };
          };

          session.dmScope = "per-channel-peer";

          browser.executablePath = lib.getExe pkgs.google-chrome;

          plugins.entries.feishu.enabled = true;
        } cfg.extraInstanceConfig;
      };
    };

    home.packages = [
      (pkgs.writeShellScriptBin "openclaw-local" ''
        set -euo pipefail

        export OPENCLAW_GATEWAY_TOKEN="$(cat "${config.sops.secrets."openclaw/token".path}")"
        export OPENCLAW_CONFIG_PATH="${activeConfigPath}"

        exec ${pkgs.llm-agents.openclaw}/bin/openclaw "$@"
      '')
      pkgs.nur.repos.josh.defuddle
    ];

    home.activation.openclawCopiedSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      skills_dir="${homeDir}/.openclaw/workspace/skills"
      if [ -d "$skills_dir" ]; then
        for skill_dir in "$skills_dir"/*; do
          if [ -L "$skill_dir" ]; then
            run ${realiseSymlink} "$skill_dir"
          fi
          if [ -d "$skill_dir" ]; then
            while IFS= read -r -d "" path; do
              run ${realiseSymlink} "$path"
            done < <(find "$skill_dir" -type l -print0)
          fi
        done
      fi
    '';

    home.activation.openclawLocalConfig =
      let
        jq = lib.getExe pkgs.jq;
        generateActiveConfig = pkgs.writeShellScript "openclaw-generate-active" ''
          set -e
          src="$1"
          dst="$2"
          if [ -L "$src" ]; then
            store_path="$(readlink "$src")"
          elif [ -f "$src" ]; then
            store_path="$src"
          else
            exit 1
          fi
          ${jq} '. + {"$include": ["./openclaw.local.json"]}' "$store_path" > "$dst.tmp"
          mv "$dst.tmp" "$dst"
        '';
        seedLocal = pkgs.writeShellScript "openclaw-seed-local" ''
          set -e
          mkdir -p "$(dirname "$1")"
          printf '{}\n' > "$1"
        '';
      in
      lib.hm.dag.entryAfter [ "openclawConfigFiles" ] ''
        LOCAL="${homeDir}/.openclaw/openclaw.local.json"
        if [[ ! -f "$LOCAL" ]]; then
          run ${seedLocal} "$LOCAL"
        fi

        CONFIG="${homeDir}/.openclaw/openclaw.json"
        ACTIVE="${activeConfigPath}"
        if [ -e "$CONFIG" ]; then
          run ${generateActiveConfig} "$CONFIG" "$ACTIVE"
        else
          warnEcho "openclaw: $CONFIG not found - openclawConfigFiles may not have run"
        fi
      '';

    home.sessionVariables.OPENCLAW_CONFIG_PATH = activeConfigPath;

    systemd.user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      ${config.programs.openclaw.instances.default.systemd.unitName}.Service.Environment = lib.mkAfter [
        "OPENCLAW_CONFIG_PATH=${activeConfigPath}"
      ];
    };
  };
}
