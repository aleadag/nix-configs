{ lib, ... }:

{
  home.stateVersion = "26.11";

  home-manager = {
    crostini.enable = true;
    dev.enable = lib.mkForce false;
  };

  stylix.cursor = lib.mkForce null;
}
