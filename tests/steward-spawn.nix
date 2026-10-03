{ pkgs, flake }:
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
    node ${./steward-spawn.mjs} ${spawn}/bin/steward-spawn ${pkgs.bash}/bin/bash ${
      flake.inputs.agent-steward + "/herdr-plugins/agent-steward-launcher/dispatch.sh"
    }
    touch "$out"
  ''
