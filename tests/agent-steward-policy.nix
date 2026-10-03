{ flake, pkgs }:
let
  system = pkgs.stdenv.hostPlatform.system;
  raw = flake.inputs.agent-steward.packages.${system}.default;
  bun = "${raw}/lib/agent-steward/bun/bin/bun";
  config = import ./agent-steward-home.nix { inherit flake pkgs; };
  skills = config.home-manager.dev.coding-agents.skills;
  approvedRev = "677c62cd3e6b88aee432b7dc13efb3ba201eb0dc";
  approvedRef = "v0.1.0-alpha.7";
  beforeLock = ./fixtures/agent-steward-before.lock;
  afterLock = ./fixtures/agent-steward-after.lock;
in
assert raw.system == system;
assert skills.agent-steward == flake.inputs.agent-steward + "/skills/agent-steward";
assert flake.inputs.agent-steward.sourceInfo.rev == approvedRev;
assert toString flake.inputs.agent-steward.inputs.nixpkgs == toString flake.inputs.nixpkgs;
assert
  builtins.hashString "sha256" (builtins.readFile beforeLock)
  == "2f6e17944417dedc636b85a743d4b1fb9d43a22fbf7d746386c36727bba99a01";
pkgs.runCommand "agent-steward-policy-check"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    fixture = pkgs.writeText "agent-steward-policy-fixture.json" (
      builtins.toJSON {
        inherit system;
        raw = toString raw;
        inherit bun;
        bunPackage = toString pkgs.bun;
        expectedBunVersion = pkgs.bun.version;
        coordinator =
          if skills ? agent-to-agent then builtins.readFile (skills.agent-to-agent + "/SKILL.md") else "";
        spawn = builtins.readFile ../modules/home-manager/dev/coding-agents/agent-steward/spawn.sh;
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
    python3 ${./agent-steward-lock.test.py} \
      ${beforeLock} ${afterLock} ${approvedRev} ${./agent-steward-lock.py} ${approvedRef}
    python3 ${./agent-steward-lock-live.py} ${../flake.lock} ${approvedRev} ${approvedRef}
    python3 ${./agent-steward-lock-live.test.py} \
      ${./agent-steward-lock-live.py} ${../flake.lock} ${approvedRev} ${approvedRef}
    touch "$out"
  ''
