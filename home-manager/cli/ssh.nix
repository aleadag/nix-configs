{ config, lib, pkgs, ... }:

{
  options.home-manager.cli.ssh.enable = lib.mkEnableOption "SSH config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.ssh.enable {
    home.packages = with pkgs; [ mosh ];

    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
      compression = true;
      forwardAgent = true;
      serverAliveCountMax = 2;
      serverAliveInterval = 300;
      includes = [ "local.d/*" ];
      extraConfig = lib.optionalString pkgs.stdenv.isDarwin ''
        IgnoreUnknown UseKeychain
        UseKeychain yes
      '';
      matchBlocks = {
        "*" = {
          sendEnv = [ "COLORTERM" ];
        };
        "github.com" = {
          identityFile = with config.home; "${homeDirectory}/.ssh/github";
          # This need to set per request
          # proxyCommand = "nc -x 127.0.0.1:7890 %h %p";
        };
        "hf.co" = {
          identityFile = with config.home; "${homeDirectory}/.ssh/hugging_face";
        };
      };
    };
  };
}
