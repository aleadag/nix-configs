{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    shellAliases = {
      # git
      gs = "${pkgs.git}/bin/git status";

      # bat
      cat = "${pkgs.bat}/bin/bat";
    };

    plugins = [
      
      {
        name = "plugin-proxy";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-proxy";
          rev = "f5ba6c770112dddcc526e3685fd563814c1c3414";
          sha256 = "sha256-OJfUbT9h5gQGWP/v6BWiDAwfUjgIrbGLXZzdr6fsCyY=";
        };
      }
    ];

    interactiveShellInit =
      ''
        # proxy
        set proxy_host 127.0.0.1:7890
        set proxy_auth false
        
        # nix
        if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        end
      '';
  };

  # Better 'ls'
  programs.eza = {
    enable = true;
    enableAliases = true;
  };

  programs.man.generateCaches = true;
}
