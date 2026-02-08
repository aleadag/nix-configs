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

### NixOS

After following the instructions in
[manual](https://nixos.org/manual/nixos/stable/#sec-installation) to prepare the
system and partition the disk, run the following process to install:

```shell
sudo git clone https://github.com/thiagokokada/nix-configs/ /mnt/etc/nixos
sudo chown -R 1000:100 /mnt/etc/nixos # optional if you want to edit your config without root
nix flake new --template '.#new-host' # if this is a new hardware
sudo nixos-install --flake /mnt/etc/nixos#hostname
```

After installing it successfully and rebooting, you can uncomment everything
and trigger a rebuild.

#### Remote installations

You can also do remote installations by using `--target-host` flag in
`nixos-rebuild` (from any machine that already has NixOS installed):

```shell
nixos-rebuild switch --flake '.#hostname' --target-host root@hostname --use-substitutes
```

Or if you don't have `root` access via SSH (keep in kind that the user needs to
have `sudo` permissions instead):

```shell
nixos-rebuild switch --flake '.#hostname' --target-host user@hostname --use-substitutes --use-remote-sudo
```

Another option for a few hosts is to use
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere). This need to
be a host with [disko](https://github.com/nix-community/disko/) configured. In
this case, you can just run:

```shell
nix run github:numtide/nixos-anywhere -- --flake '.#hostname' root@hostname
```

### nix-darwin

Start by installing Nix:

```shell
# Using experimental installer since it handles macOS updates better
curl --proto '=https' --tlsv1.2 -sSf -L https://artifacts.nixos.org/experimental-installer | \
  sh -s -- install
```

To build the Home Manager standalone and activate its configuration, run:

```shell
nix run '.#darwinActivations/<hostname>'
```

### Home Manager (standalone)

Start by installing Nix:

```console
$ sh <(curl -L https://nixos.org/nix/install) --daemon
```

To build the Home Manager standalone and activate its configuration, run:

```console
$ nix run '.#homeActivations/<hostname>' --accept-flake-config
```

### Packages

This repository also exports its modified `nixpkgs`, so it can be used to run
my custom packages. For example, to use my customized `neovim` without
installing:

```
nix run '.#neovim-standalone'
```

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

## Note for non-NixOS systems

### AWS credentials for Nix daemon (e.g. Arch Linux)

If you run Home Manager without root access, it can only configure your user
environment. For Nix daemon access to S3 binary caches, you must configure the
daemon as root.

Option A (single-user / no daemon):
- Ensure your user env sets `AWS_SHARED_CREDENTIALS_FILE` (Home Manager already
  does this via the `niks3` template).

Option B (multi-user daemon, recommended for Arch):
1. Create a root-readable credentials file (can be generated by sops outside HM).
2. Add a systemd drop-in for `nix-daemon`:

```ini
# /etc/systemd/system/nix-daemon.service.d/aws-credentials.conf
[Service]
Environment=AWS_SHARED_CREDENTIALS_FILE=/etc/nix/aws_credentials
```

Then run:
```console
sudo systemctl daemon-reload
sudo systemctl restart nix-daemon
```

If you're using this configuration on a non-NixOS system, you'll need to manually install the following packages:

- greetd: The login manager
- tuigreeter: The TUI greeter for greetd
  ```bash
  # Catppuccin Frappe Theme
  tuigreet --time --cmd sway --theme 'text=lightcyan;prompt=green;input=lightblue;border=lightmagenta;title=magenta;greet=lightmagenta;action=lightblue;button=lightred;container=black;time=lightgreen'
  ```

Please refer to your distribution's package manager to install these dependencies.

## Installing Catppuccin GRUB theme

To install the [Catppuccin GRUB theme](https://github.com/catppuccin/grub), follow these steps:

1. Clone the repository:
   ```console
   $ git clone https://github.com/catppuccin/grub.git && cd grub
   ```

2. Install the theme:
   ```console
   $ sudo cp -r src/* /boot/grub/themes/
   ```

3. Edit your GRUB configuration (`/etc/default/grub`):
   ```console
   $ sudo nano /etc/default/grub
   ```
   Add or modify these lines:
   ```
   GRUB_THEME="/boot/grub/themes/catppuccin-frappe-grub-theme/theme.txt"
   GRUB_GFXMODE="1920x1080,auto"
   ```

4. Update GRUB configuration:
   ```console
   $ sudo update-grub  # For Debian/Ubuntu
   # OR
   $ sudo grub-mkconfig -o /boot/grub/grub.cfg  # For other distributions
   ```

Note: The default flavor is `frappe`. You can replace it with other flavors if preferred (latte, macchiato, or mocha).
