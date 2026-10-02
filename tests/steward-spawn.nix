{ pkgs }:
let
  spawn = pkgs.writeScriptBin "steward-spawn" (
    builtins.readFile ../modules/home-manager/dev/coding-agents/agent-steward/spawn.sh
  );
in
pkgs.runCommand "steward-spawn-check"
  {
    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.bash
      pkgs.coreutils
      pkgs.python3
    ];
  }
  ''
    node ${./steward-spawn.mjs} ${spawn}/bin/steward-spawn ${pkgs.bash}/bin/bash ${../modules/home-manager/dev/coding-agents/agent-steward/herdr-plugin/dispatch.sh}
    touch "$out"
  ''
