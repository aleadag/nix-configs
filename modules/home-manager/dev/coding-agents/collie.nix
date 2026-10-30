{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.collie;
  package = pkgs.llm-agents.collie;
  publicHosts = lib.concatStringsSep "," cfg.publicHosts;
in
{
  options.home-manager.dev.coding-agents.collie = {
    enable = lib.mkEnableOption "Collie";
    publicHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Hostnames allowed to reach Collie through a reverse proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    home.activation.startCollie = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      envFile="${config.xdg.configHome}/collie/.env"
      if [ -z "''${DRY_RUN-}" ]; then
        umask 077
        mkdir -p "$(dirname "$envFile")"
        touch "$envFile"
        chmod 600 "$envFile"
        tmp="$envFile.tmp"
        grep -vE '^(COLLIE_HOST|COLLIE_TRUSTED_USER|COLLIE_PUBLIC_HOSTS|COLLIE_MUX)=' "$envFile" > "$tmp" || true
        {
          echo 'COLLIE_HOST=127.0.0.1'
          echo 'COLLIE_TRUSTED_USER=${config.meta.email}'
          echo 'COLLIE_PUBLIC_HOSTS=${publicHosts}'
          echo 'COLLIE_MUX=herdr'
        } >> "$tmp"
        mv "$tmp" "$envFile"
        chmod 600 "$envFile"
      fi
      ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        $DRY_RUN_CMD systemctl --user reset-failed collie.service 2>/dev/null || true
      ''}
      $DRY_RUN_CMD ${lib.getExe package} restart --plain
    '';
  };
}
