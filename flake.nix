{
  description = "My configuration files";

  inputs = {
    # main
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    hardware.url = "github:NixOS/nixos-hardware";

    # CC-Tools - Claude Code smart hooks
    cc-tools = {
      url = "github:Veraticus/cc-tools";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # helpers
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zsh-proxy = {
      url = "github:SukkaW/zsh-proxy";
      flake = false;
    };

    omf-proxy = {
      url = "github:oh-my-fish/plugin-proxy";
      flake = false;
    };

    nix-proxy-manager = {
      url = "github:aleadag/nix-proxy-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niks3 = {
      url = "github:Mic92/niks3";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        nur.follows = "nur";
        systems.follows = "systems";
        tinted-schemes.follows = "tinted-schemes";
      };
    };

    systems.url = "github:nix-systems/default";

    tinted-schemes = {
      flake = false;
      url = "github:tinted-theming/schemes";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      libEx = import ./lib inputs;
    in
    libEx.recursiveMergeAttrs (
      [
        {
          lib = libEx;
          internal = {
            configs = import ./configs;
            sharedModules = {
              default = import ./modules/shared;
              helpers = import ./modules/shared/helpers;
            };
          };
          darwinModules.default = import ./modules/nix-darwin;
          homeModules.default = import ./modules/home-manager;
          nixosModules.default = import ./modules/nixos;
          overlays.default = import ./overlays self;
        }

        (libEx.eachDefaultSystem (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config = self.outputs.internal.configs.nixpkgs;
              overlays = [
                self.overlays.default
                inputs.nur.overlays.default
              ];
            };
            treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
          in
          {
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                fd
                neovim-standalone
                nil
                nixfmt
                ripgrep
                statix
              ];
            };
            checks.formatting = treefmtEval.config.build.check self;
            formatter = treefmtEval.config.build.wrapper;
            legacyPackages = pkgs;
          }
        ))
      ]
      ++
        # NixOS configs
        (libEx.mapDir (
          hostName:
          libEx.mkNixOSConfig {
            inherit hostName;
            configuration = ./hosts/nixos/${hostName};
          }
        ) ./hosts/nixos)
      ++
        # nix-darwin configs
        (libEx.mapDir (
          hostName:
          libEx.mkNixDarwinConfig {
            inherit hostName;
            configuration = ./hosts/nix-darwin/${hostName};
          }
        ) ./hosts/nix-darwin)
      ++
        # Home-Manager configs
        (libEx.mapDir (
          hostName:
          libEx.mkHomeConfig {
            inherit hostName;
            configuration = ./hosts/home-manager/${hostName};
            system = import ./hosts/home-manager/${hostName}/system.nix;
          }
        ) ./hosts/home-manager)
    );

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://aleadag-nix-configs.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "aleadag-nix-configs.cachix.org-1:Dj7/n2rktn8tDPLfT+pEavG3wJfLkkOVBpd25O0+V/Q="
    ];
  };
}
