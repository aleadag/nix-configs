{ config, lib, pkgs, ... }:

let
  # The idea comes from here:
  # https://github.com/berbiche/dotfiles/blob/master/user/nicolas/home.nix
  # https://github.com/treffynnon/nix-setup/blob/master/home-configs/default.nix
  inherit (lib) mkIf optionals;
  inherit (builtins) currentSystem;
  inherit (lib.systems.elaborate { system = currentSystem; }) isLinux isDarwin;

  secrets = import ./secrets.nix { };
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = lib.mkMerge [ (mkIf isDarwin "alexander") (mkIf (!isDarwin) "awang") ];
  home.homeDirectory = lib.mkMerge [
    (mkIf isDarwin "/Users/alexander")
    (mkIf (!isDarwin) "/home/awang")
  ];

  # script-directory
  home.file."sd" = {
    source = ./sd;
    recursive = true;
  };

  home.packages = with pkgs; [
    # Need to test it!
    # pkgs.clash

    # 暂时移除，尚不知道如何设置：allowUnfree = true
    # pkgs.microsoft-edge

    git-crypt
    dig
    keepassxc
    anki-bin
  ];

  home.shellAliases = {
    ls = "ls --color=auto";
    ll = "ls -l --color=auto";
    cat = "bat";
    s = "kitty +kitten ssh";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = secrets;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  nix = {
    package = pkgs.nix;
    settings = { experimental-features = [ "nix-command" "flakes" ]; };
  };

  imports = [ ./aria2.nix ./fish.nix ./git.nix ./helix.nix ./httpie.nix ./irssi.nix ./kitty.nix ./newsboat.nix ./nix-zsh ]
    ++ optionals isDarwin [ ./macOS.nix ] ++ optionals isLinux [ ./linux.nix ];

  # Disable for now, as still cannot figure now how to make it work!
  # i18n.inputMethod.enabled = "fcitx5";
  # i18n.inputMethod.fcitx.engines = with pkgs.fcitx-engines; [ libpinyin cloudpinyin ];
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    bat = {
      enable = true;
      # This should pick up the correct colors for the generated theme. Otherwise
      # it is possible to generate a custom bat theme to ~/.config/bat/config
      config = {
        theme = "base16";
        tabs = "2";
        pager = "less -FR";
      };
    };

    dircolors = {
      enable = true;
      enableZshIntegration = true;
    };

    # Use direnv to manage development environments
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      # optional for nix flakes support in home-manager 21.11, not required in home-manager unstable or 22.05
      # nix-direnv.enableFlakes = true;
    };

    fzf.enable = true;

    gh = {
      enable = true;
      settings = {
        # Workaround for https://github.com/nix-community/home-manager/issues/4744
        version = 1;
        git_protocol = "ssh";
        prompt = "enabled";
        pager = "less -RF";
      };
    };

    gpg.enable = true;

    htop.enable = true;

    jq.enable = true;

    sioyek.enable = true;

    script-directory = {
      enable = true;
      settings = {
        # SD_ROOT = "${config.home.homeDirectory}/.sd";
        SD_EDITOR = "hx";
        SD_CAT = "bat";
      };
    };

    ripgrep.enable = true;
  };
}
