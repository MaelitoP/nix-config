# nix-config

> ✨ Modular, reproducible, and cross-platform Nix configuration for macOS and Ubuntu

This repository contains a personal and professional Nix-based configuration system for both macOS and Ubuntu machines. It is optimized for reproducibility, multi-platform support, and clear organization.

## Features

- 🍎 **macOS Support**: Uses [`nix-darwin`](https://github.com/LnL7/nix-darwin), [`home-manager`](https://github.com/nix-community/home-manager), and [`nix-homebrew`](https://github.com/zhaofengli/nix-homebrew)
- 🐧 **Ubuntu Support**: Uses NixOS modules on top of Ubuntu with home-manager
- 🔄 **Cross-Platform**: Core configurations shared between platforms
- 🧩 **Modular**: Organized by functionality and platform 
- 🔒 **Secure**: Secret management with sops-nix
- 🛠️ **Architecture-Aware**: Supports both ARM and x86 architectures

## Directory Structure

```console
.
├── flake.nix                # Flake entry point with platform detection
├── flake.lock               # Locked dependencies
├── justfile                 # Task runner with platform-specific commands
├── docs/                    # Documentation
│   ├── macos.md             # macOS-specific setup guide
│   ├── ubuntu.md            # Ubuntu-specific setup guide
│   └── secrets.md           # Secrets management (platform-agnostic)
├── hosts/                   # Host configurations
│   ├── common/              # Common host configuration options
│   ├── darwin/              # macOS-specific host configurations
│   │   ├── maelito-arm.nix  # M1/M2 (aarch64) config
│   │   └── maelito-x86.nix  # Intel (x86_64) config
│   └── nixos/               # NixOS configurations for Linux
│       └── maelito-ubuntu.nix # Ubuntu configuration
├── modules/                 # Home-manager modules
│   ├── core/                # Platform-agnostic modules (git, ssh, etc.)
│   ├── darwin/              # macOS-specific modules
│   ├── nixos/               # NixOS/Ubuntu-specific modules
│   └── dev/                 # Development environment modules
│       ├── languages/       # Programming language configurations
│       └── tools/           # Development tools configurations
├── pkgs/                    # Custom package configurations
├── scripts/                 # Helper scripts
│   ├── darwin/              # macOS-specific scripts
│   └── nixos/               # Ubuntu-specific scripts
└── secrets/                 # Encrypted secrets managed via sops-nix
```

## Getting Started

### For macOS

See [docs/macos.md](docs/macos.md) for detailed installation instructions.

```bash
# Clone repository
git clone https://github.com/yourusername/nix-config.git ~/nix-config
cd ~/nix-config

# Install and build
just darwin-rebuild
```

### For Ubuntu

See [docs/ubuntu.md](docs/ubuntu.md) for detailed installation instructions.

```bash
# Clone repository
git clone https://github.com/yourusername/nix-config.git ~/nix-config
cd ~/nix-config

# Install and build
just nixos-rebuild
```

## Secret Management

This configuration uses sops-nix for managing secrets. See [docs/secrets.md](docs/secrets.md) for more information.

## Customization

To customize this configuration for your own use:

1. Fork this repository
2. Update user information in:
   - `hosts/darwin/*.nix` for macOS hosts
   - `hosts/nixos/*.nix` for Ubuntu hosts
   - `modules/core/git.nix` for Git configuration
3. Update or add modules in the appropriate platform directory
4. Set up your own secrets using sops-nix

## License

MIT