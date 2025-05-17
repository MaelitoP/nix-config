# macOS Setup with Nix Configuration

This guide helps you set up a new macOS machine using this Nix configuration.

## Prerequisites

1. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

2. Install Nix package manager:
   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

3. Enable flakes:
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
   ```

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/nix-config.git ~/nix-config
cd ~/nix-config
```

### 2. Set Up Secrets

Copy your age key to `~/.config/sops/age/keys.txt` or generate a new one:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

If using a new age key, update your secrets:

```bash
sops updatekeys secrets/default.yaml
```

### 3. Install Dependencies

```bash
nix-env -iA nixpkgs.just
```

### 4. Run the Installation

The script automatically detects your macOS hardware architecture (ARM or x86):

```bash
just darwin-rebuild
```

## Post-Installation

1. Restart your machine to ensure all system settings are applied.
2. Test functionality of all configured tools and applications.
3. Review the logs for any errors or warnings.

## Updating Your System

To update your system:

```bash
cd ~/nix-config
git pull  # If you want to pull changes from remote
just flake-update  # Update flake inputs
just darwin-rebuild  # Apply the configuration
```

## Architecture-Specific Configurations

This configuration supports both Apple Silicon (M1/M2) and Intel-based Macs:

- For ARM-based Macs (M1, M2, etc.): Uses the `maelito-arm` configuration
- For Intel-based Macs: Uses the `maelito-x86` configuration

The build script automatically detects your architecture and applies the appropriate configuration.

## Troubleshooting

- If Homebrew apps aren't installing, try running the rebuild command again.
- For issues with secrets, make sure your age key is correctly set up and has access to the secrets.
- If you encounter errors with nix-darwin, try running the full command directly: `nix run nix-darwin -- switch --flake .#maelito-arm`