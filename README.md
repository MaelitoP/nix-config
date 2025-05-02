# nix-config

> ✨ Modular, reproducible, and architecture-aware `nix-darwin` configuration for macOS

This repository contains my personal and professional Nix-based configuration system for macOS machines using [`nix-darwin`](https://github.com/LnL7/nix-darwin), [`home-manager`](https://github.com/nix-community/home-manager), and [`nix-homebrew`](https://github.com/zhaofengli/nix-homebrew). It is optimized for reproducibility, scalability across architectures, and clarity.

---

## 🗂️ Layout

```console
.
├── flake.nix                # Flake entry point
├── flake.lock               # Locked dependencies
├── justfile                 # Task runner using `just`
├── machines/                # Per-device configurations
│   ├── maelito-arm.nix      # M1/M2 (aarch64) config
│   └── maelito-x86.nix      # Intel (x86_64) config
├── modules/                 # Reusable Nix modules (e.g., zsh, git, tmux, etc.)
├── scripts/                 # Helper scripts (e.g., rebuild selector)
└── secrets/                 # Encrypted secrets managed via sops-nix
```
