{
  experimental-features = [
    "nix-command"
    "flakes"
  ];

  substituters = [
    "https://nix-community.cachix.org"
    "https://aleadag-nix-configs.cachix.org"
  ];

  trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "aleadag-nix-configs.cachix.org-1:Dj7/n2rktn8tDPLfT+pEavG3wJfLkkOVBpd25O0+V/Q="
  ];

  max-jobs = "auto";
}
