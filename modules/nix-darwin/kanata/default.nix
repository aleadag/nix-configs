{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix-darwin.kanata;
in
{
  options.nix-darwin.kanata = {
    enable = lib.mkEnableOption "kanata sudoers configuration" // {
      default = true;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kanata;
      description = "The kanata package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create sudoers file for kanata to run without password
    environment.etc."sudoers.d/kanata".source = pkgs.runCommand "sudoers-kanata" { } ''
      KANATA_BIN="${cfg.package}/bin/kanata"
      SHASUM=$(sha256sum "$KANATA_BIN" | cut -d' ' -f1)
      cat <<EOF > "$out"
      %admin ALL=(root) NOPASSWD: sha256:$SHASUM $KANATA_BIN
      EOF
    '';
  };
}
