(import ../flake.nix).nixConfig
// {
  accept-flake-config = true;
  experimental-features = [
    "nix-command"
    "flakes"
  ];

  max-jobs = "auto";
}
