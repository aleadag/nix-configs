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
        clash_remotes = { };
      };
    };
  };
}
