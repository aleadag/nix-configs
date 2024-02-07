{ ... }:

{
  home.file.".hammerspoon" = {
    source = ./config/hammerspoon;
    recursive = true;
  };

  # macOS 上无法编译 man pages
  # https://github.com/NixOS/nixpkgs/issues/196651
  # https://github.com/nix-community/home-manager/issues/4142
  # manual.manpages.enable = false;
}
