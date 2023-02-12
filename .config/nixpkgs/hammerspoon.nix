{ pkgs, ... }:

{
  home.file.".hammerspoon" = {
    source = ./config/hammerspoon;
    recursive = true;
  };
}
