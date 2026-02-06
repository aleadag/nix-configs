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
  options.home-manager.nix.niks3.enable = lib.mkEnableOption "niks3 config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ flake.inputs.niks3.packages.${pkgs.system}.default ];

    sops = {
      secrets = {
        niks3_auth_token.path = "${config.home.homeDirectory}/.config/niks3/auth-token";
        # Define secrets for AWS credentials
        niks3_aws_access_key_id = { };
        niks3_aws_secret_access_key = { };
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
  };
}
