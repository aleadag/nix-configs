{ flake, pkgs }:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  raw = flake.inputs.agent-steward.packages.${system}.default;
  jsonFormat = pkgs.formats.json { };
  enabled = import ./agent-steward-home.nix {
    inherit flake pkgs;
    secretPath = "synthetic key '\nfile";
  };
  inventory = enabled.home-manager.dev.coding-agents.agent-steward.settings;
  changed = import ./agent-steward-home.nix {
    inherit flake pkgs;
    secretPath = "synthetic key '\nfile";
    extra.home-manager.dev.coding-agents.agent-steward.settings = {
      thresholds.risky = 0.7;
      jev.model = "jev-declarative-override";
    };
  };
  generated = jsonFormat.generate "agent-steward.json" inventory;
  overridden = jsonFormat.generate "agent-steward.json" changed.home-manager.dev.coding-agents.agent-steward.settings;
  wrapper = lib.head (lib.filter (p: lib.getName p == "agent-steward") enabled.home.packages);
  fakeCli = pkgs.writeText "agent-steward-fake-cli.mjs" (
    builtins.readFile ./agent-steward-fake-cli.mjs
  );
  fakeEntry = pkgs.writeScriptBin "agent-steward" ''
    #!${raw}/lib/agent-steward/bun/bin/bun
    await import("${fakeCli}");
  '';
  integrated = import ../modules/home-manager/dev/coding-agents/agent-steward/wrapper.nix {
    inherit pkgs;
    package = fakeEntry;
    secretFile = enabled.sops.secrets.typesafe_api_key.path;
  };
  integratedOverride = import ../modules/home-manager/dev/coding-agents/agent-steward/wrapper.nix {
    inherit pkgs;
    package = fakeEntry;
    secretFile = changed.sops.secrets.typesafe_api_key.path;
  };
in
assert raw.system == system;
assert
  builtins.hashString "sha256" (builtins.readFile (flake.inputs.agent-steward + "/bun.lock"))
  == "6ae6d867b56a2af6e216bc0dcb5abf98c2b9e4b4a986b03b06d4b3a4939bff3e";
assert toString flake.inputs.agent-steward.inputs.nixpkgs == toString flake.inputs.nixpkgs;
pkgs.runCommand "agent-steward-cli-check"
  {
    nativeBuildInputs = [ pkgs.coreutils ];
    fixture = pkgs.writeText "agent-steward-cli-fixture.json" (
      builtins.toJSON {
        inherit system;
        raw = toString raw;
        bun = "${raw}/lib/agent-steward/bun/bin/bun";
        bunPackage = toString pkgs.bun;
        expectedBunVersion = pkgs.bun.version;
        generated = toString generated;
        overridden = toString overridden;
        wrapper = "${wrapper}/bin/agent-steward";
        integrated = "${integrated}/bin/agent-steward";
        integratedOverride = "${integratedOverride}/bin/agent-steward";
        secretFile = enabled.sops.secrets.typesafe_api_key.path;
        skillSource = toString (enabled.home-manager.dev.coding-agents.skills.agent-steward + "/SKILL.md");
      }
    );
  }
  ''
    ${raw}/lib/agent-steward/bun/bin/bun ${./agent-steward-cli.mjs} "$fixture"
    touch "$out"
  ''
