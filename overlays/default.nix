{ flake }:
final: prev:

(flake.inputs.nixgl.overlays.default final prev) //
{
  # namespaces
  libEx = prev.lib.extend (finalLib: prevLib:
    (import ../lib { lib = finalLib; pkgs = final; })
  );

  # gaming = flake.inputs.nix-gaming.packages.${prev.system};

  # wallpapers = prev.callPackage ../packages/wallpapers { };

  # # custom packages
  # arandr = prev.arandr.overrideAttrs (_: { src = flake.inputs.arandr; });

  # anime4k = prev.callPackage ../packages/anime4k { };

  # change-res = prev.callPackage ../packages/change-res { };

  # inherit (flake.inputs.home-manager.packages.${prev.system}) home-manager;

  # open-browser = prev.callPackage ../packages/open-browser { };

  nix-cleanup = prev.callPackage ../packages/nix-cleanup { };

  # nixos-cleanup = prev.callPackage ../packages/nix-cleanup {
  #   isNixOS = true;
  # };

  nix-whereis = prev.callPackage ../packages/nix-whereis { };

  # nom-rebuild = prev.callPackage ../packages/nom-rebuild { };

  # run-bg-alias = name: command: prev.callPackage ../packages/run-bg-alias { inherit name command; };

  # inherit (flake.inputs.twenty-twenty-twenty.packages.${prev.system}) twenty-twenty-twenty;
}
