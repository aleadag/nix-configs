{
  actions = {
    # https://github.com/marketplace/actions/cachix
    cachix-action = "cachix/cachix-action@v16";
    # https://github.com/marketplace/actions/checkout
    checkout = "actions/checkout@v4";
    # https://github.com/marketplace/actions/create-pull-request
    create-pull-request = "peter-evans/create-pull-request@v7";
    # https://github.com/marketplace/actions/free-disk-space-ubuntu
    free-disk-space = "thiagokokada/free-disk-space@main";
    # https://github.com/marketplace/actions/install-nix
    install-nix-action = "cachix/install-nix-action@v31";
  };

  ubuntu.runs-on = "ubuntu-latest";
  ubuntu-arm.runs-on = "ubuntu-24.04-arm";
  macos.runs-on = "macos-latest";

  home-manager = {
    x86_64-linux.hostnames = [
      "mbx"
    ];
    aarch64-linux.hostnames = [ "lckfb" ];
    aarch64-darwin.hostnames = [ "home-mac" ];
  };

  nix-darwin.aarch64-darwin.hostnames = [ "t0" ];

  nixos = {
    aarch64-linux.hostnames = [
      "jetson-nixos"
    ];
    x86_64-linux.hostnames = [
      "pvg1-nixos"
    ];
  };
}
