{
  description = "My configuration files";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      inherit (import ./lib/attrsets.nix { inherit (nixpkgs) lib; }) recursiveMergeAttrs;
      inherit (import ./lib/flake-helpers.nix inputs) mkGHActionsYAMLs mkRunCmd mkNixOSConfig mkHomeConfig;
      inherit (import ./lib/impure.nix { }) getEnvOrDefault;
    in
    recursiveMergeAttrs [
      (mkHomeConfig {
        hostname = "t0";
        username = "alexander";
        system = "aarch64-darwin";
        homePath = "/Users";
      })

      (mkHomeConfig {
        hostname = "mbx";
        username = "awang";
        system = "x86_64-linux";
        homePath = "/home";
      })

      # GitHub Actions
      (mkGHActionsYAMLs [
        "build-and-cache"
        "update-flakes"
        "update-flakes-darwin"
        "validate-flakes"
      ])

      (flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          legacyPackages = pkgs;
        }))
    ]; # END recursiveMergeAttrs
}
