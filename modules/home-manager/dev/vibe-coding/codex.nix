{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.codex;
in
{
  options.home-manager.dev.codex = {
    enable = lib.mkEnableOption "Codex config" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.codex = {
      enable = true;
    };

    home.activation.codexDescribeSkill =
      let
        describeSkill = pkgs.writeText "SKILL.md" ''
          ---
          name: describe
          description: Generate a conventional commit description with emoji from jj diff and apply it with jj describe
          ---

          ${builtins.readFile ./commands/describe.md}
        '';
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        target="$HOME/.codex/skills/describe"
        tmp="$(mktemp -d)"

        cp "${describeSkill}" "$tmp/SKILL.md"

        if [ -L "$target" ] || [ -d "$target" ]; then
          chmod -R u+w "$target" 2>/dev/null || true
          rm -rf "$target"
        fi

        mkdir -p "$(dirname "$target")"
        mv "$tmp" "$target"
      '';
  };
}
