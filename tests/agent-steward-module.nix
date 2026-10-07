{ flake, pkgs }:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  inventory = import ../modules/home-manager/dev/coding-agents/agent-steward/config.nix;
  jsonFormat = pkgs.formats.json { };
  fakeAdapter = pkgs.writeShellScriptBin "agent-steward-herdr-adapter" ''
    printf '%s\n' "$TYPESAFE_API_KEY" "$@"
  '';
  fakePackage = pkgs.symlinkJoin {
    name = "fake-agent-steward";
    src = flake.inputs.agent-steward.packages.${system}.default.src;
    paths = [
      (pkgs.runCommand "fake-steward-recover-plugin" { } ''
        plugin="$out/share/agent-steward/herdr-plugins/agent-steward-recover"
        mkdir -p "$plugin"
        cp -f ${flake.inputs.agent-steward}/herdr-plugins/agent-steward-recover/herdr-plugin.toml "$plugin/herdr-plugin.toml"
        cp -f ${flake.inputs.agent-steward}/herdr-plugins/agent-steward-recover/run.sh "$plugin/run.sh"
        ln -s ${fakeAdapter}/bin/agent-steward-herdr-adapter "$plugin/agent-steward-herdr-adapter"
      '')
      (pkgs.writeShellScriptBin "agent-steward" "exit 0")
      fakeAdapter
    ];
  };
  testFlake = flake // {
    inputs = flake.inputs // {
      agent-steward = flake.inputs.agent-steward // {
        packages.${system} = flake.inputs.agent-steward.packages.${system} // {
          default = fakePackage;
        };
      };
    };
  };
  home =
    args:
    import ./agent-steward-home.nix (
      {
        flake = testFlake;
        inherit pkgs;
      }
      // args
    );
  enabled = home { };
  withHerdr = home { extra.home-manager.dev.coding-agents.herdr.enable = true; };
  withPackagedHerdr = home {
    inherit flake;
    extra.home-manager.dev.coding-agents.herdr.enable = true;
  };
  approvalEnabled = home {
    extra.home-manager.dev.coding-agents.agent-steward.autoApprove = true;
  };
  approvalDisabled = home {
    extra.home-manager.dev.coding-agents.agent-steward.autoApprove = false;
  };
  approvalMissing = home {
    extra.home-manager.dev.coding-agents.agent-steward.settings = lib.mkForce { };
  };
  passthrough = home {
    extra.home-manager.dev.coding-agents.agent-steward.settings.auto_approve = true;
  };
  approvalJson =
    c:
    c.xdg.configFile."herdr/plugins/config/agent-steward-recover/targets.json".source
      or (jsonFormat.generate "missing-targets.json" { });
  withWaybar = home {
    extra.programs.waybar = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      settings.top.modules-right = [ "network" ];
    };
  };
  disabledWithWaybar = home {
    extra = {
      programs.waybar.enable = pkgs.stdenv.hostPlatform.isLinux;
      home-manager.dev.coding-agents.agent-steward.enable = false;
    };
  };
  disabledWithHerdr = home {
    extra.home-manager.dev.coding-agents = {
      herdr.enable = true;
      agent-steward.enable = false;
    };
  };
  override = inventory // {
    thresholds = inventory.thresholds // {
      risky = 0.7;
    };
    candidates = map (
      c:
      if c.id == "gemini-flash-agy" then
        c
        // {
          capabilities = c.capabilities + "; declarative override";
        }
      else
        c
    ) inventory.candidates;
  };
  changed = home {
    extra.home-manager.dev.coding-agents.agent-steward.settings = {
      thresholds.risky = 0.7;
      inherit (override) candidates;
    };
  };
  partial = home {
    extra.home-manager.dev.coding-agents.agent-steward.settings.thresholds.risky = 0.8;
  };
  lists = home {
    extra.home-manager.dev.coding-agents.agent-steward.settings = {
      tools = [ "agy" ];
      candidates = lib.filter (c: c.tool == "agy") inventory.candidates;
    };
  };
  poisonFlake = testFlake // {
    inputs = testFlake.inputs // {
      agent-steward = throw "disabled steward forced its source/package";
    };
  };
  disabled = home {
    flake = poisonFlake;
    secretPath = throw "disabled steward forced its secret path";
    extra.home-manager.dev.coding-agents.agent-steward = {
      enable = false;
      settings = throw "disabled steward generated its settings";
    };
  };
  parentDisabled = home { extra.home-manager.dev.coding-agents.enable = false; };
  sopsDisabledModule = import ../modules/home-manager/dev/coding-agents/agent-steward/default.nix {
    inherit pkgs;
    flake = testFlake;
    inherit (pkgs) lib;
    config = {
      home-manager.dev.coding-agents = {
        enable = true;
        herdr.enable = false;
        agent-steward = {
          enable = true;
          settings = inventory;
        };
      };
      home-manager.sops.enable = false;
      sops.secrets.typesafe_api_key.path = "synthetic secret.key";
    };
  };
  wrappers = config: lib.filter (p: lib.getName p == "agent-steward") config.home.packages;
  defaultJson = enabled.xdg.configFile."agent-steward/config.json".source;
  overrideJson = changed.xdg.configFile."agent-steward/config.json".source;
  partialJson = partial.xdg.configFile."agent-steward/config.json".source;
  listsJson = lists.xdg.configFile."agent-steward/config.json".source;
  absent =
    c:
    wrappers c == [ ]
    && !(c.home.shellAliases ? stw)
    && !(c.home-manager.dev.coding-agents.skills ? agent-steward)
    && !(c.sops.secrets ? typesafe_api_key);
in
assert
  !pkgs.stdenv.hostPlatform.isLinux
  || (
    (withWaybar.programs.waybar.settings.top.modules-right or [ ]) == [
      "custom/agent-steward"
      "network"
    ]
    && withWaybar.programs.waybar.settings.top."custom/agent-steward".return-type == "json"
    && withWaybar.programs.waybar.style != null
  );
assert enabled.programs.waybar.settings == [ ];
assert disabledWithWaybar.programs.waybar.settings == [ ];
assert enabled.programs.waybar.style == null;
assert disabledWithWaybar.programs.waybar.style == null;
assert enabled.home-manager.dev.coding-agents.agent-steward.enable;
assert enabled.home-manager.dev.coding-agents.agent-steward.settings == inventory;
assert lib.length (wrappers enabled) == 1;
assert enabled.home.shellAliases.stw == "agent-steward";
assert lib.any (p: lib.getName p == "steward-spawn") enabled.home.packages;
assert enabled.home-manager.dev.coding-agents.herdr.plugins == [ ];
assert disabledWithHerdr.home-manager.dev.coding-agents.herdr.plugins == [ ];
assert lib.length withHerdr.home-manager.dev.coding-agents.herdr.plugins == 2;
assert
  toString (lib.head withHerdr.home-manager.dev.coding-agents.herdr.plugins)
  == "${fakePackage}/share/agent-steward/herdr-plugins/agent-steward-launcher";
assert enabled.xdg.configFile."agent-steward/config.json".source != null;
assert
  enabled.home-manager.dev.coding-agents.skills.agent-steward
  == flake.inputs.agent-steward + "/skills/agent-steward";
assert enabled.sops.secrets.typesafe_api_key.key == "typesafe_api_key";
assert enabled.sops.secrets.typesafe_api_key.mode == "0600";
assert !(enabled.home.sessionVariables ? TYPESAFE_API_KEY_FILE);
assert !(enabled.home.sessionVariables ? AGENT_STEWARD_HERDR_ADAPTER);
assert !(enabled.home.sessionVariables ? TYPESAFE_API_KEY);
assert
  !pkgs.stdenv.hostPlatform.isLinux
  || (
    enabled.systemd.user.timers ? agent-steward-quota-refresh
    && enabled.systemd.user.services ? agent-steward-quota-refresh
  );
assert !(disabled.systemd.user.timers or { } ? agent-steward-quota-refresh);
assert absent disabled && absent parentDisabled;
assert !(disabled.xdg.configFile ? "herdr/plugins/config/agent-steward-recover/targets.json");
assert lib.any (
  a: !a.assertion && a.message == "agent-steward requires home-manager.sops.enable."
) sopsDisabledModule.config.content.assertions;
assert builtins.readFile ../modules/home-manager/dev/coding-agents/pi/default.nix != "";
pkgs.runCommand "agent-steward-module-check"
  {
    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.python3
    ];
    waybarStyle = pkgs.writeText "agent-steward-waybar.css" (
      if withWaybar.programs.waybar.style == null then "" else withWaybar.programs.waybar.style
    );
    waybarExec =
      if pkgs.stdenv.hostPlatform.isLinux then
        withWaybar.programs.waybar.settings.top."custom/agent-steward".exec
      else
        "${pkgs.python3}/bin/python3 ${../modules/home-manager/dev/coding-agents/agent-steward/waybar.py} ${defaultJson}";
    fixture = pkgs.writeText "agent-steward-module-fixture.json" (
      builtins.toJSON {
        inherit system;
        upstreamRecover = flake.inputs.agent-steward + "/herdr-plugins/agent-steward-recover";
        argvPlugin = toString (lib.head withPackagedHerdr.home-manager.dev.coding-agents.herdr.plugins);
        packagedLauncher = "${
          flake.inputs.agent-steward.packages.${system}.default
        }/share/agent-steward/herdr-plugins/agent-steward-launcher";
        shell = pkgs.runtimeShell;
        packagedRecover = "${fakePackage}/share/agent-steward/herdr-plugins/agent-steward-recover";
        stopPlugin = toString (lib.elemAt withHerdr.home-manager.dev.coding-agents.herdr.plugins 1);
        approvalEnabledJson = toString (approvalJson approvalEnabled);
        approvalDisabledJson = toString (approvalJson approvalDisabled);
        approvalMissingJson = toString (approvalJson approvalMissing);
        approvalEnabledCliJson = toString approvalEnabled.xdg.configFile."agent-steward/config.json".source;
        passthroughJson = toString passthrough.xdg.configFile."agent-steward/config.json".source;
        passthroughApprovalJson = toString (approvalJson passthrough);
        defaultJson = toString defaultJson;
        overrideJson = toString overrideJson;
        partialJson = toString partialJson;
        listsJson = toString listsJson;
        defaultWrapper = "${lib.head (wrappers enabled)}/bin/agent-steward";
        overrideWrapper = "${lib.head (wrappers changed)}/bin/agent-steward";
        piModule = builtins.readFile ../modules/home-manager/dev/coding-agents/pi/default.nix;
        stewardModule = builtins.readFile ../modules/home-manager/dev/coding-agents/agent-steward/default.nix;
        defaultModule = builtins.readFile ../modules/home-manager/dev/coding-agents/default.nix;
        newModule = builtins.pathExists ../modules/home-manager/dev/coding-agents/agent-steward/default.nix;
        newConfig = builtins.pathExists ../modules/home-manager/dev/coding-agents/agent-steward/config.nix;
        newWrapper = builtins.pathExists ../modules/home-manager/dev/coding-agents/agent-steward/wrapper.nix;
        oldModule = builtins.pathExists ../modules/home-manager/dev/coding-agents/agent-steward.nix;
        oldConfig = builtins.pathExists ../configs/agent-steward.nix;
        oldWrapper = builtins.pathExists ../modules/home-manager/dev/coding-agents/scripts/agent-steward.nix;
        sopsModule = builtins.readFile ../modules/home-manager/sops.nix;
      }
    );
  }
  ''
    node ${./agent-steward-module.mjs} "$fixture"
    python3 ${./agent-steward-waybar.test.py} "$waybarExec" \
      ${lib.getLib pkgs.pango}/lib/libpango-1.0${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}
    ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      mkdir -p "$TMPDIR/gtk-cache"
      XDG_CACHE_HOME="$TMPDIR/gtk-cache" ${pkgs.xvfb-run}/bin/xvfb-run -a python3 ${./agent-steward-waybar-css.test.py} \
        "$waybarStyle" ${lib.getLib pkgs.gtk3}/lib/libgtk-3.so
    ''}
    touch "$out"
  ''
