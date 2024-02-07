{
  actions = {
    checkout = "actions/checkout@v4";
    cachix-action = "cachix/cachix-action@v12";
    install-nix-action = "cachix/install-nix-action@v22";
    maximize-build-space = "easimon/maximize-build-space@v7";
    create-pull-request = "peter-evans/create-pull-request@v5";
    command-output = "mathiasvr/command-output@v2.0.0";
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
