{ config, lib, pkgs, ... }:
let
  # load the configuration that we was generated the first
  # time zsh were loaded with powerlevel enabled.
  # Make sure to comment this part (and the sourcing part below)
  # before you ran powerlevel for the first time or if you want to run
  # again 'p10k configure'. Then, copy the generated file as:
  # $ mv ~/.p10k.zsh p10k-config/p10k.zsh
  configThemeNormal = ./p10k-config/p10k.zsh;
  configThemeTTY = ./p10k-config/p10k_tty.zsh;
in {
  # fonts.fontconfig.enable = true;
  # home.packages = with pkgs; [
  #   # Meslo Nerd Font patched for Powerlevel10k
  #   # Restart Konsole and configure it (profile) to choose MesloLGS NF
  #   meslo-lgs-nf
  # ];
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      # The powerlevel theme I'm using is distgusting in TTY, let's default
      # to something else
      # See https://github.com/romkatv/powerlevel10k/issues/325
      # Instead of sourcing this file you could also add another plugin as
      # this, and it will automatically load the file for us
      # (but this way it is not possible to conditionally load a file)
      # {
      #   name = "powerlevel10k-config";
      #   src = lib.cleanSource ./p10k-config;
      #   file = "p10k.zsh";
      # }
      if zmodload zsh/terminfo && (( terminfo[colors] >= 256 )); then
        [[ ! -f ${configThemeNormal} ]] || source ${configThemeNormal}
      else
        [[ ! -f ${configThemeTTY} ]] || source ${configThemeTTY}
      fi
    '';
    # https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
    profileExtra = ''
      # Brew, for macOS
      if [ -e '/opt/homebrew/bin/brew' ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
      fi
      # End Brew

      # Nix
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
      # End Nix
    '';
    plugins = [
      {
        # A prompt will appear the first time to configure it properly
        # make sure to select MesloLGS NF as the font in Konsole
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-proxy";
        src = pkgs.fetchFromGitHub {
          owner = "SukkaW";
          repo = "zsh-proxy";
          rev = "2c15588a1585ea07c0673f551dd39e904a7d504a";
          sha256 = "M01m50VNkjc6Fgo9KaETlINJYkLttaRMrkBsCgqRJ4c=";
        };
      }
      {
        name = "nixify";
        src = ./plugins;
      }
    ];
  };
}
