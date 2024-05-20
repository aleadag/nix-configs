{
  actions = {
    cachix-action = "cachix/cachix-action@v14";
    checkout = "actions/checkout@v4";
    create-pull-request = "peter-evans/create-pull-request@v6";
    free-disk-space = "jlumbroso/free-disk-space@v1.3.1";
    install-nix-action = "cachix/install-nix-action@v26";
  };
  ubuntu.runs-on = "ubuntu-latest";
  # M1 macOS
  macos.runs-on = "macos-14";
  home-manager = {
    linux.hostnames = [
      "mbx"
    ];
    darwin.hostnames = [
      "t0"
    ];
  };
  nixos.hostnames = [
  ];
}
