{ pkgs, ... }:

{
  home.file.".hammerspoon" = {
    source = ./config/hammerspoon;
    recursive = true;
  };

  # macOS 上无法编译 man pages
  # https://github.com/NixOS/nixpkgs/issues/196651
  manual.manpages.enable = false;
}
