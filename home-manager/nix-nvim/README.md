# Neovim configuration for Nix

The settings were borrowed from [here](https://framagit.org/vegaelle/nix-nvim);

This repository contains my configuration for the [Neovim](https://neovim.io)
text editor, ready to be applied on a [NixOS](https://nixos.org) system or any
POSIX system with the Nix package manager. It uses
[Home-manager](https://nix-community.github.io/home-manager/) to apply the configuration to any user.

It depends on Neovim 0.5 or later.

## Usage

You need a working Nix or NixOS, and Home-Manager environment.

You can either activate this config in the global `configuration.nix` file (and
define per-user home-manager config) or in `home.nix` in your home directory.

For `configuration.nix`:

```nix
{ lib, config, pkgs, ... }:
let
  # […]
  nix-nvim = builtins.fetchGit {
    url = "https://github.com/aleadag/nix-nvim.git";
    ref = "main";
  };
in
{
  imports = [
    # your existing imports
    <home-manager/nixos>
  ];
  home-manager.users.your_user = import "${nix-nvim}";
}
```

Then run `nixos-rebuild switch`, and `rehash` if your current shell is `zsh`.

For `home.nix`:

```nix
{ lib, config, pkgs, ... }:
let
  # […]
  nix-nvim = builtins.fetchGit {
    url = "https://github.com/aleadag/nix-nvim.git";
    ref = "main";
  };
in
{
  imports = [ (import "${nix-nvim}") ];
}
```

Then run `home-manager switch`. There is no need for `rehash` even with `zsh`.
