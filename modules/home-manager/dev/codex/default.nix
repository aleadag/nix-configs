{
  config,
  lib,
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

    home.activation.codexDescribeSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="$HOME/.codex/skills/describe"
      src="${./skills/describe}"
      tmp="$(mktemp -d)"

      cp -R "$src/." "$tmp/"

      if [ -L "$target" ] || [ -d "$target" ]; then
        chmod -R u+w "$target" 2>/dev/null || true
        rm -rf "$target"
      fi

      mkdir -p "$(dirname "$target")"
      mv "$tmp" "$target"
    '';
  };
}
