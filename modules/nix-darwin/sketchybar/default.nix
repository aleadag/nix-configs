{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.nix-darwin.sketchybar;
  sketchybar-helpers =
    pkgs.callPackage
      (
        { stdenv }:
        stdenv.mkDerivation {
          name = "sketchybar-helper";
          src = ./helpers;
          installPhase = ''
            mkdir -p $out/bin
            find . -type f -executable -exec cp "{}" $out/bin \;
          '';
        }
      )
      {
        stdenv = pkgs.clangStdenv;
      };
  bar-cfg =
    {
      lua,
      toLuaModule,
      stdenv,
      ...
    }:
    toLuaModule (
      stdenv.mkDerivation {
        name = "sketchybar-config";
        src = lib.sourceFilesBySuffices ./. [ ".lua" ];
        installPhase = # bash
          ''
            runHook preInstall

            target=$out/share/lua/${lua.luaversion}
            mkdir -p $target
            cp -r $src/* $target

            runHook postInstall
          '';
      }
    );
  lua = pkgs.lua54Packages.lua.withPackages (ps: [
    pkgs.sbarlua
    (pkgs.callPackage bar-cfg ps)
  ]);
in
{
  options.nix-darwin.sketchybar.enable = lib.mkEnableOption "sketchybar config" // {
    default = config.nix-darwin.yabai.enable;
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [ sketchybar-app-font ];
    system.defaults.NSGlobalDomain._HIHideMenuBar = true; # Disable menu bar
    services.sketchybar = {
      enable = true;
      extraPackages = [
        sketchybar-helpers
      ];
      # https://github.com/FelixKratz/dotfiles
      config = # bash
        ''
          #!${lua}/bin/lua
          require('init')
        '';
    };
  };
}
