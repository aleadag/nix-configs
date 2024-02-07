{ pkgs, ... }:

let configData = { default_options = [ "--style=paraiso-dark" ]; };
in {
  home.packages = with pkgs; [ httpie ];

  xdg.configFile."httpie/config.json".text = builtins.toJSON (configData);
}
