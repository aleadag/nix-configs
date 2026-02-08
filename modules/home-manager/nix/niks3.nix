{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.home-manager.nix.niks3;
in
{
  options.home-manager.nix.niks3 = {
    enable = lib.mkEnableOption "niks3 config" // {
      default = true;
    };

    gc = {
      enable = lib.mkEnableOption "niks3 automatic garbage collection";
      olderThan = lib.mkOption {
        type = lib.types.str;
        default = "720h";
        description = "Delete closures older than this duration";
      };
      failedUploadsOlderThan = lib.mkOption {
        type = lib.types.str;
        default = "6h";
        description = "Delete failed uploads older than this duration";
      };
      frequency = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "How often to run the garbage collection (systemd OnCalendar format)";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ flake.inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      sops = {
        secrets = {
          niks3_auth_token.path = "${config.home.homeDirectory}/.config/niks3/auth-token";
          # Define secrets for AWS credentials
          niks3_aws_access_key_id = { };
          niks3_aws_secret_access_key = { };
        };

        templates."niks3-aws-env" = {
          content = ''
            AWS_ACCESS_KEY_ID=${config.sops.placeholder.niks3_aws_access_key_id}
            AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.niks3_aws_secret_access_key}
          '';
          path = "${config.home.homeDirectory}/.config/niks3/aws_env";
        };

        templates."niks3-aws-credentials" = {
          content = ''
            [default]
            aws_access_key_id=${config.sops.placeholder.niks3_aws_access_key_id}
            aws_secret_access_key=${config.sops.placeholder.niks3_aws_secret_access_key}
          '';
          path = "${config.home.homeDirectory}/.config/niks3/aws_credentials";
        };
      };

      # Point Nix/AWS SDKs to these specific files
      home.sessionVariables = {
        NIKS3_SERVER_URL = "http://cache.dev.ticos.cloud:7788";
        AWS_SHARED_CREDENTIALS_FILE = config.sops.templates."niks3-aws-credentials".path;
      };
    })

    (lib.mkIf (cfg.enable && cfg.gc.enable) {
      systemd.user.services.niks3-gc = {
        Unit = {
          Description = "niks3 garbage collection";
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "oneshot";
          Environment = "NIKS3_SERVER_URL=${config.home.sessionVariables.NIKS3_SERVER_URL}";
          ExecStart = "${
            lib.getExe' flake.inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.default "niks3"
          } gc --older-than=${cfg.gc.olderThan} --failed-uploads-older-than=${cfg.gc.failedUploadsOlderThan}";
        };
      };

      systemd.user.timers.niks3-gc = {
        Unit.Description = "Run niks3 garbage collection";
        Timer = {
          OnCalendar = cfg.gc.frequency;
          Persistent = true;
          RandomizedDelaySec = 1800;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })
  ];
}
