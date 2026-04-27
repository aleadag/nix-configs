{ lib, ... }:

{
  home.stateVersion = "26.05";

  home-manager = {
    crostini.enable = true;
    dev.enable = lib.mkForce false;
  };
}
