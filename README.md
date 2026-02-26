# nix-config

This repository contains my personal and professional Nix-based configuration system for macOS machines using [`nix-darwin`](https://github.com/LnL7/nix-darwin), [`home-manager`](https://github.com/nix-community/home-manager), and [`nix-homebrew`](https://github.com/zhaofengli/nix-homebrew). It is optimized for reproducibility, scalability across architectures, and clarity.

## Install

```sh
curl -sL https://raw.githubusercontent.com/MaelitoP/nix-config/main/scripts/install.sh | bash
```

The script is idempotent and can be re-run safely if it fails partway through.

## Daily use

```sh
just rebuild   # apply configuration changes
just update    # update flake inputs
just check     # dry-run build to validate
just clean     # garbage-collect the Nix store
just format    # format all .nix files
```

## Layout

```
.
├── flake.nix                # Flake entry point
├── flake.lock               # Locked dependencies
├── justfile                 # Task runner
├── hosts/                   # Per-device configurations
│   ├── maelito-arm.nix      # M1/M2 (aarch64)
│   └── maelito-x86.nix      # Intel (x86_64)
├── modules/                 # Reusable Nix modules
├── scripts/                 # Bootstrap & helper scripts
└── secrets/                 # Encrypted secrets (sops-nix)
```
