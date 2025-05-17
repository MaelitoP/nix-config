# Ubuntu Setup with Nix Configuration

This guide helps you set up a new Ubuntu machine using this Nix configuration.

## Prerequisites

1. Install Ubuntu (recommended: Ubuntu 24.04 LTS or newer)
2. Install Nix package manager:
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```
3. Enable flakes:
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
   ```
4. Install Git:
   ```bash
   sudo apt update && sudo apt install -y git
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

### 3. Install NixOS Dependencies

Before the initial installation, you need to make sure your system has the necessary bootstrap dependencies:

```bash
nix-env -iA nixpkgs.just nixpkgs.git
```

### 4. Run the NixOS Installation

```bash
# For first-time setup, this will install NixOS components on your Ubuntu system
just nixos-rebuild
```

## Post-Installation

1. Log out and log back in to ensure all environment variables are set correctly.
2. Test functionality of all configured tools (e.g., test that your development environment works).
3. Review the logs for any errors or warnings.

## Updating Your System

To update your system:

```bash
cd ~/nix-config
git pull  # If you want to pull changes from remote
just flake-update  # Update flake inputs
just nixos-rebuild  # Apply the configuration
```

## Troubleshooting

- If you encounter permission issues, make sure your user has sudo privileges.
- If the rebuild fails, check the error messages and fix any configuration issues.
- For issues with secrets, make sure your age key is correctly set up and has access to the secrets.