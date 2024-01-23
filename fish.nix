{ ... }:
{
  programs.fish = {
    enable = true;

    shellInit =
      ''
        # nix
        if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        end
      '';
  };
  programs.man.generateCaches = true;
}
