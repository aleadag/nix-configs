{ flake, pkgs }:
let
  system = pkgs.stdenv.hostPlatform.system;
  raw = flake.inputs.agent-steward.packages.${system}.default;
  bun = "${raw}/lib/agent-steward/bun/bin/bun";
  config = import ./agent-steward-home.nix { inherit flake pkgs; };
  skills = config.home-manager.dev.coding-agents.skills;
in
assert raw.system == system;
assert skills.agent-steward == flake.inputs.agent-steward + "/skills/agent-steward";
assert toString flake.inputs.agent-steward.inputs.nixpkgs == toString flake.inputs.nixpkgs;
pkgs.runCommand "agent-steward-policy-check"
  {
    fixture = pkgs.writeText "agent-steward-policy-fixture.json" (
      builtins.toJSON {
        inherit system;
        raw = toString raw;
        inherit bun;
        bunPackage = toString pkgs.bun;
        expectedBunVersion = pkgs.bun.version;
        coordinator =
          if skills ? agent-to-agent then builtins.readFile (skills.agent-to-agent + "/SKILL.md") else "";
        spawn = builtins.readFile (flake.inputs.agent-steward + "/src/herdr-spawn.ts");
        policyNix = builtins.readFile ./agent-steward-policy.nix;
        subagents = builtins.readFile ../modules/home-manager/dev/coding-agents/pi/skills/subagents/SKILL.md;
        piModule = builtins.readFile ../modules/home-manager/dev/coding-agents/pi/default.nix;
        roles = builtins.mapAttrs (_: path: builtins.readFile path) {
          explore = ../modules/home-manager/dev/coding-agents/pi/skills/subagents/agents/explore.md;
          planner = ../modules/home-manager/dev/coding-agents/pi/skills/subagents/agents/planner.md;
          worker = ../modules/home-manager/dev/coding-agents/pi/skills/subagents/agents/worker.md;
          reviewer = ../modules/home-manager/dev/coding-agents/pi/skills/subagents/agents/reviewer.md;
        };
      }
    );
  }
  ''
    ${bun} ${./agent-steward-policy.mjs} "$fixture"
    touch "$out"
  ''
