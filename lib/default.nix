{ nixpkgs, ... }@inputs:

nixpkgs.lib.mergeAttrsList [
  (import ./attrsets.nix inputs)
  (import ./flake-helpers.nix inputs)
  (import ./skill-scripts.nix inputs)
  (import ./modules.nix inputs)
]
