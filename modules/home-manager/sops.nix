{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.home-manager.sops;
in
{
  imports = [
    flake.inputs.sops-nix.homeManagerModules.sops
  ];

  options.home-manager.sops.enable = lib.mkEnableOption "Sops config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    # https://dl.thalheim.io/
    sops = {
      age = {
        keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        generateKey = false;
      };
      defaultSopsFile = ../../secrets/secrets.yaml;
      secrets = {
        attic.path = "${config.home.homeDirectory}/.config/attic/config.toml";

        ssh_key.path = "${config.home.homeDirectory}/.ssh/id_rsa";
        ssh_pub.path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";

        ssh_gh_key.path = "${config.home.homeDirectory}/.ssh/github";
        ssh_gh_pub.path = "${config.home.homeDirectory}/.ssh/github.pub";

        ssh_hf_key.path = "${config.home.homeDirectory}/.ssh/huggingface";
        ssh_hf_pub.path = "${config.home.homeDirectory}/.ssh/huggingface.pub";

        clash_remotes = { };
      };
    };
  };
}
