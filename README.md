# nix-configs - Configuration as Code

My Nix{OS} configuration files to help me setup my machine in minutes using
[HM](https://github.com/nix-community/home-manager).

## Overview

- nix configuration for my laptops, desktops and more
- nix flake-powered
- guaranteed to be reproducible

## Disclaimer

This config is mainly based on
[nix-configs](https://github.com/thiagokokada/nix-configs). Some of the
repositories that helped me to build this config:

- https://github.com/thiagokokada/nix-configs
- https://github.com/wimpysworld/nix-config
- https://github.com/bqv/nixrc
- https://github.com/colemickens/nixcfg
- https://github.com/hlissner/dotfiles
- https://github.com/Mic92/dotfiles
- https://github.com/nrdxp/nixflk
- https://github.com/anujc4/dotfiles

Also, some extra resources and documentation about Flakes:

- [Flakes in NixOS Wiki](https://nixos.wiki/wiki/Flakes)
- [Nix Flakes blog posts from @eldostra](https://www.tweag.io/blog/2020-05-25-flakes/)
- [Nix documentation](https://nixos.org/manual/nix/unstable/)

**Remember**: Flakes is _experimental_, so you shouldn't try this approach until
you have some experience in Nix.

## Rules

- Automate everything, configuration as code.
- Prefer to `nix` whenever possible.
  - `yay` or `brew` only for OS specific packages.

## Installation

### Home Manager (standalone)

Start by installing Nix:

```console
$ sh <(curl -L https://nixos.org/nix/install) --daemon
```

To build the Home Manager standalone and activate its configuration, run:

```console
$ nix run '.#homeActivations/<hostname>' --accept-flake-config
```

Happy hacking!

## Setting up swaylock on non-NixOS systems

If you're using swaylock on a non-NixOS system, you'll need to perform the following setup:

1. Install PAM configuration:
```console
$ cp $(nix path-info nixpkgs#swaylock.out)/etc/pam.d/swaylock /etc/pam.d/swaylock
```

2. Set up the `/run/wrappers/bin/unix_chkpwd` suid binary. Since some distributions mount `/run` with the nosuid flag, you need to:

   a. Add the following to `/etc/fstab`:
   ```
   tmpfs /run/wrappers tmpfs defaults,nodev,noatime,mode=755 0 0
   ```

   b. Create a systemd oneshot unit to create a symlink from `/sbin/unix_chkpwd` to `/run/wrappers/bin`:
   ```console
   $ cat <<EOF > /usr/local/lib/systemd/system/install-unix_chkpwd-wrapper.service
   [Unit]
   After=run-wrappers.mount
   Wants=run-wrappers.mount

   [Service]
   Type=oneshot
   ExecStart=/usr/bin/mkdir -p /run/wrappers/bin
   ExecStart=/usr/bin/ln -sf /sbin/unix_chkpwd /run/wrappers/bin/unix_chkpwd

   [Install]
   WantedBy=multi-user.target
   EOF
   ```

Reference: [NixOS/nixpkgs#158025](https://github.com/NixOS/nixpkgs/issues/158025#issuecomment-1616807870)
