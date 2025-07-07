# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix configuration repository using flakes to manage system configurations for multiple platforms:
- **NixOS**: Linux desktop/server configurations
- **nix-darwin**: macOS system configurations  
- **Home Manager**: User environment configurations (cross-platform)

The configuration supports multiple hosts and provides a unified interface for managing system state across different machines.

## Common Commands

### Development Environment
```bash
# Enter development shell with tools
nix develop
```

### Formatting and Linting
```bash
# Format all code
nix fmt

# Check formatting
nix run '.#checks.x86_64-linux.formatting'  # or appropriate system

# Run statix linter
statix check
```

### Building and Activating Configurations

#### Home Manager (standalone)
```bash
# Build and activate Home Manager configuration
nix run '.#homeActivations/<hostname>' --accept-flake-config

# Example hostnames: home-mac, lckfb, mbx, with-cuda
```

#### NixOS
```bash
# Build NixOS configuration
nix build '.#nixosConfigurations.<hostname>.config.system.build.toplevel'

# Activate NixOS configuration
nix run '.#nixosActivations/<hostname>'

# Test in VM
nix run '.#nixosVMs/<hostname>'

# Example hostnames: jetson-nixos, pvg1-nixos
```

#### nix-darwin (macOS)
```bash
# Build and activate nix-darwin configuration
nix run '.#darwinActivations/<hostname>'

# Example hostnames: t0
```

## Architecture

### Directory Structure
- `hosts/`: Host-specific configurations organized by platform
  - `home-manager/`: Standalone Home Manager configurations
  - `nix-darwin/`: macOS system configurations
  - `nixos/`: Linux system configurations
- `modules/`: Reusable configuration modules organized by platform
  - `home-manager/`: User environment modules (CLI, desktop, dev tools, etc.)
  - `nix-darwin/`: macOS-specific system modules
  - `nixos/`: Linux-specific system modules
  - `shared/`: Cross-platform shared modules
- `lib/`: Custom Nix library functions and flake helpers
- `overlays/`: Nixpkgs overlays for custom packages
- `configs/`: Base configuration files
- `actions/`: GitHub Actions related Nix files

### Key Files
- `flake.nix`: Main flake configuration with inputs and outputs
- `lib/flake-helpers.nix`: Helper functions for creating configurations
- `treefmt.nix`: Formatting configuration (nixfmt, statix, etc.)
- `shell.nix`: Development shell via flake-compat

### Configuration Pattern
Each host configuration follows this pattern:
1. Base modules are imported from the appropriate platform directory
2. Host-specific configuration is defined in `hosts/<platform>/<hostname>/`
3. Shared modules provide common functionality across hosts
4. Platform-specific modules handle OS-specific configuration

### Module Organization
- **CLI modules**: Shell, terminal tools, development utilities
- **Desktop modules**: Window managers, applications, theming
- **Dev modules**: Programming languages, development tools
- **System modules**: Core system configuration, networking, services

## Host Examples
- `home-mac`: macOS Home Manager configuration
- `t0`: nix-darwin macOS system configuration
- `jetson-nixos`: NixOS configuration for Jetson devices
- `with-cuda`: Home Manager configuration with CUDA support

## Development Tools Available
- `neovim-standalone`: Text editor
- `nil`: Nix language server
- `nixfmt-rfc-style`: Nix formatter
- `statix`: Nix linter
- `fd`: File finder
- `ripgrep`: Text search