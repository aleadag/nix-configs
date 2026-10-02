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
    pi: herdr: steward:
    (flake.homeConfigurations.${host}.extendModules {
      modules = [
        {
          home-manager.dev.coding-agents = {
            pi-coding-agent.enable = lib.mkForce pi;
            herdr.enable = lib.mkForce herdr;
            agent-steward.enable = lib.mkForce steward;
            beads.enable = lib.mkForce false;
          };
        }
      ];
    }).config;
  enabled = withAgents true true true;
  stewardDisabled = withAgents true true false;
  codexAgents = enabled.programs.codex.settings.agents or { };
  subagentsSkillPath = "${enabled.programs.pi-coding-agent.configDir}/skills/subagents";
  source = flake.inputs.pi-herdr-subagents;
  packageSources =
    config: map (package: package.source) (config.programs.pi-coding-agent.settings.packages or [ ]);
  piDisabled = withAgents false true true;
  herdrDisabled = withAgents true false true;
  disabled = [
    herdrDisabled
    piDisabled
    (withAgents false false true)
    (withAgents true false false)
    (withAgents false true false)
    (withAgents false false false)
  ];
  retired =
    config:
    !(lib.elem (toString source) (packageSources config))
    && lib.all (
      plugin: !(lib.hasInfix "pi-herdr-subagents" (toString plugin))
    ) config.home-manager.dev.coding-agents.herdr.plugins;
  absent = config: !(builtins.hasAttr subagentsSkillPath config.home.file) && retired config;
in
assert lib.assertMsg (
  !(enabled.home-manager.dev.coding-agents ? models)
) "Keep model settings local to each harness, without a shared matrix";
assert lib.assertMsg (
  !(codexAgents ? planner) && !(codexAgents ? worker) && !(codexAgents ? reviewer)
) "Pi integration must not generate Codex roles";
assert lib.assertMsg (builtins.hasAttr subagentsSkillPath enabled.home.file)
  "Pi subagents skill is missing when Herdr is enabled";
assert lib.assertMsg (lib.all absent disabled)
  "Pi Herdr integration must require both Pi and Herdr";
assert lib.assertMsg (lib.all retired (
  [
    enabled
    stewardDisabled
  ]
  ++ disabled
)) "The retired Pi Herdr package/plugin must not be installed, independently of steward";
assert lib.assertMsg (builtins.hasAttr subagentsSkillPath stewardDisabled.home.file)
  "Pi subagents skill must remain available when steward is disabled";
assert lib.assertMsg (
  !(stewardDisabled.home-manager.dev.coding-agents.skills ? agent-to-agent)
  && !(stewardDisabled.home-manager.dev.coding-agents.skills ? agent-steward)
  && !(builtins.hasAttr "${stewardDisabled.programs.pi-coding-agent.configDir}/skills/agent-to-agent" stewardDisabled.home.file)
) "Steward-disabled configurations must not install the coordinator or steward skills";
assert lib.assertMsg (
  enabled.home-manager.dev.coding-agents.skills.agent-steward
  == flake.inputs.agent-steward + "/skills/agent-steward"
) "The steward skill must match the pinned steward source";
assert lib.assertMsg (lib.all
  (
    config:
    config.home-manager.dev.coding-agents.skills.agent-to-agent
    == ../modules/home-manager/dev/coding-agents/skills/agent-to-agent
  )
  [
    enabled
    piDisabled
    herdrDisabled
  ]
) "The shared coordinator skill must remain available independently of Pi and Herdr";
assert lib.assertMsg (
  enabled.home.file."${enabled.programs.pi-coding-agent.configDir}/skills/agent-to-agent".source
  == enabled.home-manager.dev.coding-agents.skills.agent-to-agent
) "Pi must install the shared coordinator skill without rewriting it";
assert lib.assertMsg (lib.all
  (
    program:
    !(program.enable or false)
    || program.skills.agent-to-agent == enabled.home-manager.dev.coding-agents.skills.agent-to-agent
  )
  [
    enabled.programs.codex
    enabled.programs.opencode
    enabled.programs.antigravity-cli
  ]
) "Every enabled shared-skill harness must receive the same coordinator skill";
assert lib.assertMsg (
  piDisabled.home-manager.dev.coding-agents.skills.agent-steward
  == flake.inputs.agent-steward + "/skills/agent-steward"
) "The steward skill must remain available when Pi is disabled";
assert lib.assertMsg (
  herdrDisabled.home-manager.dev.coding-agents.skills.agent-steward
  == flake.inputs.agent-steward + "/skills/agent-steward"
) "The steward skill must remain available when Herdr is disabled";
assert lib.assertMsg (
  !(enabled.home.sessionVariables ? TYPESAFE_API_KEY)
) "Instruction routing must not globally export the TypeSafe key";
assert lib.assertMsg (
  enabled.programs.pi-coding-agent.settings.defaultModel == "gpt-6.1-sol"
) "The coordinator must use Sol";
pkgs.runCommand "pi-herdr-subagents-check"
  {
    nativeBuildInputs = [ pkgs.nodejs ];
    configFile = pkgs.writeText "pi-herdr-test-config.json" (
      builtins.toJSON {
        retiredPackage = toString source;
        piSettings = builtins.toJSON enabled.programs.pi-coding-agent.settings;
        herdrPlugins = map toString enabled.home-manager.dev.coding-agents.herdr.plugins;
        explore = builtins.readFile (enabled.home.file.${subagentsSkillPath}.source + "/agents/explore.md");
        planner = builtins.readFile (enabled.home.file.${subagentsSkillPath}.source + "/agents/planner.md");
        worker = builtins.readFile (enabled.home.file.${subagentsSkillPath}.source + "/agents/worker.md");
        reviewer = builtins.readFile (
          enabled.home.file.${subagentsSkillPath}.source + "/agents/reviewer.md"
        );
        context = enabled.programs.pi-coding-agent.context;
        subagentsSkill = builtins.readFile ../modules/home-manager/dev/coding-agents/pi/skills/subagents/SKILL.md;
        coordinatorSkill = builtins.readFile (
          enabled.home-manager.dev.coding-agents.skills.agent-to-agent + "/SKILL.md"
        );
        stewardSkill =
          if enabled.home-manager.dev.coding-agents.skills ? agent-steward then
            builtins.readFile (enabled.home-manager.dev.coding-agents.skills.agent-steward + "/SKILL.md")
          else
            null;
      }
    );
  }
  ''
    node ${./pi-herdr-subagents.mjs} "$configFile"
    touch "$out"
  ''
