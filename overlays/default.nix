{ flake }:
final: prev:

let
  inherit (flake) outputs inputs;
in
outputs.lib.recursiveMergeAttrs [
  (inputs.nixgl.overlays.default final prev)
  {
    # namespaces
    libEx = flake.outputs.lib;

    # # custom packages
    # arandr = prev.arandr.overrideAttrs (_: { src = flake.inputs.arandr; });

    anime4k = prev.callPackage ../packages/anime4k { };

    change-res = prev.callPackage ../packages/change-res { };

    inherit (flake.inputs.home-manager.packages.${prev.system}) home-manager;

    open-browser = prev.callPackage ../packages/open-browser { };

    nix-cleanup = prev.callPackage ../packages/nix-cleanup { };

    nix-whereis = prev.callPackage ../packages/nix-whereis { };

    run-bg-alias = name: command: prev.callPackage ../packages/run-bg-alias { inherit name command; };
  }
]
