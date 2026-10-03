{ pkgs }:
let
  fake = pkgs.writeScriptBin "agent-steward" ''
    #!${pkgs.nodejs}/bin/node
    const fs = require("node:fs");
    fs.writeFileSync(process.env.TEST_CAPTURE, JSON.stringify({
      argv: process.argv.slice(2), cwd: process.cwd(),
      key: process.env.TYPESAFE_API_KEY, provider: process.env.OPENAI_API_KEY
    }), { mode: 0o600 });
    process.exit(Number(process.env.TEST_STATUS || "0"));
  '';
  secretFile = "secret 'quoted'\n$(touch secret-path-executed).key";
  templatedSecretFile = "%r/agent-steward-synthetic-${
    builtins.substring 0 20 (builtins.hashString "sha256" (toString fake))
  }.key";
  templatedWrapper = import ../modules/home-manager/dev/coding-agents/agent-steward/wrapper.nix {
    inherit pkgs;
    package = fake;
    secretFile = templatedSecretFile;
  };
  wrapper = import ../modules/home-manager/dev/coding-agents/agent-steward/wrapper.nix {
    inherit pkgs secretFile;
    package = fake;
  };
in
pkgs.runCommand "agent-steward-wrapper-check"
  {
    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.bash
    ];
    fixture = pkgs.writeText "agent-steward-wrapper-fixture.json" (
      builtins.toJSON {
        wrapper = "${wrapper}/bin/agent-steward";
        bash = "${pkgs.bash}/bin/bash";
        inherit secretFile templatedSecretFile;
        templatedWrapper = "${templatedWrapper}/bin/agent-steward";
      }
    );
  }
  ''
    node ${./agent-steward-wrapper.mjs} "$fixture"
    touch "$out"
  ''
