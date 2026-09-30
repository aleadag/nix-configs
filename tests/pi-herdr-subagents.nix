{ flake, pkgs }:

let
  inherit (pkgs) lib;
  host =
    {
      x86_64-linux = "pvg1";
      aarch64-linux = "lckfb";
      aarch64-darwin = "home-mac";
    }
    .${pkgs.stdenv.hostPlatform.system};
  withAgents =
    pi: herdr:
    (flake.homeConfigurations.${host}.extendModules {
      modules = [
        {
          home-manager.dev.coding-agents = {
            pi-coding-agent.enable = lib.mkForce pi;
            herdr.enable = lib.mkForce herdr;
            beads.enable = lib.mkForce false;
          };
        }
      ];
    }).config;
  enabled = withAgents true true;
  codexAgents = enabled.programs.codex.settings.agents or { };
  plannerPath = "${enabled.programs.pi-coding-agent.configDir}/agents/planner.md";
  workerPath = "${enabled.programs.pi-coding-agent.configDir}/agents/worker.md";
  reviewerPath = "${enabled.programs.pi-coding-agent.configDir}/agents/reviewer.md";
  source = flake.inputs.pi-herdr-subagents;
  packageSources =
    config: map (package: package.source) (config.programs.pi-coding-agent.settings.packages or [ ]);
  disabled = [
    (withAgents true false)
    (withAgents false true)
    (withAgents false false)
  ];
  absent =
    config:
    !(builtins.hasAttr plannerPath config.home.file)
    && !(builtins.hasAttr workerPath config.home.file)
    && !(builtins.hasAttr reviewerPath config.home.file)
    && !(lib.elem (toString source) (packageSources config))
    && config.home-manager.dev.coding-agents.herdr.plugins == [ ];
in
assert lib.assertMsg (
  !(enabled.home-manager.dev.coding-agents ? models)
) "Keep model settings local to each harness, without a shared matrix";
assert lib.assertMsg (
  !(codexAgents ? planner) && !(codexAgents ? worker) && !(codexAgents ? reviewer)
) "Pi integration must not generate Codex roles";
assert lib.assertMsg (builtins.hasAttr plannerPath enabled.home.file)
  "Pi Herdr planner definition is missing";
assert lib.assertMsg (builtins.hasAttr workerPath enabled.home.file)
  "Pi Herdr worker definition is missing";
assert lib.assertMsg (builtins.hasAttr reviewerPath enabled.home.file)
  "Pi Herdr reviewer definition is missing";
assert lib.assertMsg (lib.all absent disabled)
  "Pi Herdr integration must require both Pi and Herdr";
assert lib.assertMsg (
  lib.head (packageSources enabled) == toString source
) "Pi Herdr package must load first";
assert lib.assertMsg (
  enabled.programs.pi-coding-agent.settings.defaultModel == "gpt-6.1-sol"
) "The coordinator must use Sol";
assert lib.assertMsg (
  builtins.length enabled.home-manager.dev.coding-agents.herdr.plugins == 1
) "The bundled Herdr plugin must be linked";
assert lib.assertMsg (
  (lib.head enabled.home-manager.dev.coding-agents.herdr.plugins).system
  == pkgs.stdenv.hostPlatform.system
) "The plugin check must use the target platform";
pkgs.runCommand "pi-herdr-subagents-check"
  {
    nativeBuildInputs = [ pkgs.nodejs ];
    configFile = pkgs.writeText "pi-herdr-test-config.json" (
      builtins.toJSON {
        upstream = toString source;
        planner = builtins.readFile enabled.home.file.${plannerPath}.source;
        worker = builtins.readFile enabled.home.file.${workerPath}.source;
        reviewer = builtins.readFile enabled.home.file.${reviewerPath}.source;
        plugin = toString (lib.head enabled.home-manager.dev.coding-agents.herdr.plugins);
      }
    );
  }
  ''
    node ${./pi-herdr-subagents.mjs} "$configFile"
    touch "$out"
  ''
