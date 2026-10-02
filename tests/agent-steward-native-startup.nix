{ flake, pkgs }:
let
  raw = flake.inputs.agent-steward.packages.${pkgs.stdenv.hostPlatform.system}.default;
  bun = "${raw}/lib/agent-steward/bun/bin/bun";
  fakeCli = pkgs.writeText "agent-steward-native-startup-fake-cli.mjs" (
    builtins.readFile ./agent-steward-native-startup-fake-cli.mjs
  );
  entry = pkgs.writeScriptBin "agent-steward" ''
    #!${bun}
    await import(${builtins.toJSON (toString fakeCli)});
  '';
  makeWrapper =
    effort:
    let
      configFile = (pkgs.formats.json { }).generate "synthetic-startup.json" {
        tools = [
          "codex"
          "pi"
          "agy"
        ];
        candidates =
          map
            (tool: {
              id = "fixture-${tool}";
              inherit tool;
              provider =
                if tool == "pi" then
                  "openai-codex"
                else if tool == "agy" then
                  "google"
                else
                  "openai";
              model = "requested-${tool}";
              quota_bucket =
                if tool == "pi" then
                  "pi_codex"
                else if tool == "agy" then
                  "antigravity"
                else
                  "codex";
              quota_pool = "primary";
              cost = 1;
              capabilities = "Synthetic offline fixture";
              thinking_levels = [
                {
                  id = effort;
                  description = "Fixture effort";
                }
              ];
            })
            [
              "codex"
              "pi"
              "agy"
            ];
        jev.model = "jev-1.13.0";
        thresholds = {
          risky = 0.6;
          choiceConfidence = 0.45;
        };
      };
    in
    import ../modules/home-manager/dev/coding-agents/agent-steward/wrapper.nix {
      inherit pkgs configFile;
      package = entry;
      secretFile = "synthetic.key";
    };
in
assert raw.system == pkgs.stdenv.hostPlatform.system;
pkgs.runCommand "agent-steward-native-startup-check"
  {
    fixture = pkgs.writeText "startup-fixture.json" (
      builtins.toJSON {
        raw = toString raw;
        inherit bun;
        spawn = "${pkgs.writeScriptBin "steward-spawn" (builtins.readFile ../modules/home-manager/dev/coding-agents/agent-steward/spawn.sh)}/bin/steward-spawn";
        spawnSource = builtins.readFile ../modules/home-manager/dev/coding-agents/agent-steward/spawn.sh;
        runtimePath = pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
        ];
        wrappers = {
          default = "${makeWrapper "default"}/bin/agent-steward";
          high = "${makeWrapper "high"}/bin/agent-steward";
        };
      }
    );
  }
  ''
    ${bun} ${./agent-steward-native-startup.mjs} "$fixture"
    touch "$out"
  ''
