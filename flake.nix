{
  description = "My configuration files";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # build helix from the source
    # https://github.com/helix-editor/helix/discussions/6062
    # helix = {
    #   url = "github:helix-editor/helix";
    #   inputs.flake-utils.follows = "flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # helpers
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";

    # custom packages
    arandr = {
      url = "gitlab:thiagokokada/arandr";
      flake = false;
    };

    # hyprland
    hyprland-go = {
      url = "github:thiagokokada/hyprland-go";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ZSH plugins
    zim-completion = {
      url = "github:zimfw/completion";
      flake = false;
    };
    zim-environment = {
      url = "github:zimfw/environment";
      flake = false;
    };
    zim-input = {
      url = "github:zimfw/input";
      flake = false;
    };
    zim-git = {
      url = "github:zimfw/git";
      flake = false;
    };
    zim-ssh = {
      url = "github:zimfw/ssh";
      flake = false;
    };
    zim-utility = {
      url = "github:zimfw/utility";
      flake = false;
    };
    pure = {
      url = "github:sindresorhus/pure";
      flake = false;
    };
    zsh-autopair = {
      url = "github:hlissner/zsh-autopair";
      flake = false;
    };
    zsh-completions = {
      url = "github:zsh-users/zsh-completions";
      flake = false;
    };
    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
      flake = false;
    };
    zsh-proxy = {
      url = "github:SukkaW/zsh-proxy";
      flake = false;
    };

    omf-proxy = {
      url = "github:oh-my-fish/plugin-proxy";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    let
      lib = import ./lib inputs;
      inherit (lib) recursiveMergeAttrs mkGHActionsYAMLs mkHomeConfig;
    in
    recursiveMergeAttrs [
      {
        inherit lib;
        overlays.default = import ./overlays { flake = self; };
        darwinModules.default = import ./modules/nix-darwin;
        homeModules.default = import ./modules/home-manager;
        nixosModules.default = import ./modules/nixos;
      }
      (mkHomeConfig {
        hostname = "t0";
        username = "alexander";
        system = "aarch64-darwin";
        homePath = "/Users";
        extraModules = [
          {
            home-manager = {
              cli.git.git-sync.enable = true;
              dev.enable = true;
            };
          }
        ];
      })

      (mkHomeConfig {
        hostname = "mbx";
        username = "awang";
        system = "x86_64-linux";
        homePath = "/home";
        extraModules = [
          {
            home-manager = {
              cli.git.git-sync.enable = true;
              desktop = {
                enable = true;
                x11.enable = false;
              };
              dev.enable = true;
            };
          }
        ];
      })

      (mkHomeConfig {
        hostname = "with-cuda";
        username = "alexander";
        system = "x86_64-linux";
        homePath = "/home";
        extraModules = [
          {
            home-manager = {
              desktop = {
                enable = false;
                nixgl = {
                  enable = true;
                };
                theme = {
                  enable = true;
                  gtk.enable = false;
                  qt.enable = false;
                };
                wezterm.enable = true;
              };
              gui.enable = false;
            };
          }
        ];
      })

      (mkHomeConfig {
        hostname = "ticos-with-cuda";
        username = "ticos";
        system = "x86_64-linux";
        homePath = "/home";
        extraModules = [
          {
            home-manager = {
              desktop = {
                enable = false;
                nixgl = {
                  enable = true;
                };
                theme = {
                  enable = true;
                  gtk.enable = false;
                  qt.enable = false;
                };
                wezterm.enable = true;
              };
              gui.enable = false;
            };
          }
        ];
      })

      (mkHomeConfig {
        hostname = "ticos-without-cuda";
        username = "ticos";
        system = "x86_64-linux";
        homePath = "/home";
        extraModules = [
          {
            home-manager = {
              desktop = {
                enable = false;
                theme = {
                  enable = true;
                  gtk.enable = false;
                  qt.enable = false;
                };
                wezterm.enable = true;
              };
              gui.enable = false;
            };
          }
        ];
      })

      (mkHomeConfig {
        hostname = "firefly";
        username = "ticos";
        system = "aarch64-linux";
        homePath = "/home";
        extraModules = [
          {
            home-manager = {
              desktop = {
                enable = false;
                theme = {
                  enable = true;
                  gtk.enable = false;
                  qt.enable = false;
                };
                wezterm.enable = true;
              };
              gui.enable = false;
            };
          }
        ];
      })

      # GitHub Actions
      (mkGHActionsYAMLs [
        "build-and-cache"
        "update-flakes"
        "update-flakes-darwin"
        "validate-flakes"
      ])

      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          inherit (import ./patches { inherit self system; }) pkgs;
        in
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              fd
              neovim-standalone
              nil
              nixfmt-rfc-style
              ripgrep
              statix
            ];
          };
          checks = import ./checks.nix { inherit pkgs; };
          formatter = pkgs.nixfmt-rfc-style;
          legacyPackages = pkgs;
        }
      ))
    ]; # END recursiveMergeAttrs
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
