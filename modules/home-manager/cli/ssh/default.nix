{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.cli.ssh.enable = lib.mkEnableOption "SSH config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.ssh.enable {
    home.packages = with pkgs; [ mosh ];

    programs = {
      ssh = {
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
            identityFile = config.sops.secrets.ssh_gh_key.path;
            # This need to set per request
            # proxyCommand = "nc -x 127.0.0.1:7890 %h %p";
          };
          "hf.co" = {
            identityFile = config.sops.secrets.ssh_hf_key.path;
          };
        };
      };

      zsh.initContent =
        # Checks if SSH_AUTH_SOCK is set and the socket is working, or start a
        # new ssh-agent otherwise (works in any OS)
        # bash
        ''
          source ${./ssh-agent.zsh}
        '';
    };

    sops.secrets = {
      ssh_key.path = "${config.home.homeDirectory}/.ssh/id_rsa";
      ssh_pub.path = "${config.home.homeDirectory}/.ssh/id_rsa.pub";

      ssh_gh_key = { };
      ssh_gh_pub = { };

      ssh_hf_key = { };
      ssh_hf_pub = { };
    };
  };
}
