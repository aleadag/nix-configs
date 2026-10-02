{ flake, pkgs }:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  inventory = import ../modules/home-manager/dev/coding-agents/agent-steward/config.nix;
  jsonFormat = pkgs.formats.json { };
  fakePackage = pkgs.writeShellScriptBin "agent-steward" "exit 0";
  testFlake = flake // {
    inputs = flake.inputs // {
      agent-steward = flake.inputs.agent-steward // {
        packages.${system}.default = fakePackage;
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
      if c.id == "gemini-flash-high-agy" then
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
      accounts = lib.filter (a: a.source == "antigravity") inventory.accounts;
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
  defaultJson = jsonFormat.generate "agent-steward.json" enabled.home-manager.dev.coding-agents.agent-steward.settings;
  overrideJson = jsonFormat.generate "agent-steward.json" changed.home-manager.dev.coding-agents.agent-steward.settings;
  partialJson = jsonFormat.generate "agent-steward.json" partial.home-manager.dev.coding-agents.agent-steward.settings;
  listsJson = jsonFormat.generate "agent-steward.json" lists.home-manager.dev.coding-agents.agent-steward.settings;
  absent =
    c:
    wrappers c == [ ]
    && !(c.home-manager.dev.coding-agents.skills ? agent-steward)
    && !(c.sops.secrets ? typesafe_api_key);
in
assert enabled.home-manager.dev.coding-agents.agent-steward.enable;
assert enabled.home-manager.dev.coding-agents.agent-steward.settings == inventory;
assert lib.length (wrappers enabled) == 1;
assert lib.any (p: lib.getName p == "steward-spawn") enabled.home.packages;
assert enabled.home-manager.dev.coding-agents.herdr.plugins == [ ];
assert disabledWithHerdr.home-manager.dev.coding-agents.herdr.plugins == [ ];
assert lib.length withHerdr.home-manager.dev.coding-agents.herdr.plugins == 1;
assert
  enabled.home-manager.dev.coding-agents.skills.agent-steward
  == flake.inputs.agent-steward + "/skills/agent-steward";
assert enabled.sops.secrets.typesafe_api_key.key == "typesafe_api_key";
assert enabled.sops.secrets.typesafe_api_key.mode == "0600";
assert !(enabled.home.sessionVariables ? TYPESAFE_API_KEY);
assert absent disabled && absent parentDisabled;
assert lib.any (
  a: !a.assertion && a.message == "agent-steward requires home-manager.sops.enable."
) sopsDisabledModule.config.content.assertions;
assert builtins.readFile ../modules/home-manager/dev/coding-agents/pi.nix != "";
pkgs.runCommand "agent-steward-module-check"
  {
    nativeBuildInputs = [ pkgs.nodejs ];
    fixture = pkgs.writeText "agent-steward-module-fixture.json" (
      builtins.toJSON {
        inherit system;
        argvPlugin = toString (lib.head withHerdr.home-manager.dev.coding-agents.herdr.plugins);
        defaultJson = toString defaultJson;
        overrideJson = toString overrideJson;
        partialJson = toString partialJson;
        listsJson = toString listsJson;
        defaultWrapper = "${lib.head (wrappers enabled)}/bin/agent-steward";
        overrideWrapper = "${lib.head (wrappers changed)}/bin/agent-steward";
        piModule = builtins.readFile ../modules/home-manager/dev/coding-agents/pi.nix;
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
    touch "$out"
  ''
