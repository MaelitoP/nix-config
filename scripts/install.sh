#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/MaelitoP/nix-config.git"
REPO_DIR="$HOME/dev/nix-config"
AGE_KEY_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"
NIX_CONF="$HOME/.config/nix/nix.conf"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

if xcode-select -p &>/dev/null; then
  ok "Xcode CLT already installed"
else
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Press enter once the installation is complete."
  read -r < /dev/tty
fi

# Clean up stale backups from a previous Nix install
for f in /etc/bashrc.backup-before-nix /etc/zshrc.backup-before-nix /etc/bash.bashrc.backup-before-nix; do
  if [ -f "$f" ]; then
    warn "Removing stale Nix backup: $f"
    sudo rm "$f"
  fi
done

if command -v nix &>/dev/null; then
  ok "Nix already installed"
else
  info "Installing Nix..."
  NIX_INSTALLER="$(mktemp)"
  curl -L -o "$NIX_INSTALLER" https://nixos.org/nix/install
  sh "$NIX_INSTALLER" < /dev/tty
  rm -f "$NIX_INSTALLER"
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if [ -f "$NIX_CONF" ] && grep -q "flakes" "$NIX_CONF"; then
  ok "Flakes already enabled"
else
  info "Enabling flakes..."
  mkdir -p "$(dirname "$NIX_CONF")"
  echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
fi

if command -v brew &>/dev/null; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -d "$REPO_DIR" ]; then
  info "Pulling latest changes..."
  git -C "$REPO_DIR" pull --ff-only
else
  info "Cloning nix-config..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

if [ -f "$AGE_KEY_FILE" ]; then
  ok "Age key already present"
else
  warn "sops-nix needs your age secret key to decrypt secrets."
  printf "Path to your age keys.txt: "
  read -r AGE_KEY_SRC < /dev/tty
  mkdir -p "$AGE_KEY_DIR"
  cp "$AGE_KEY_SRC" "$AGE_KEY_FILE"
  chmod 600 "$AGE_KEY_FILE"
  ok "Age key copied to $AGE_KEY_FILE"
fi

info "Running bootstrap..."
cd "$REPO_DIR"
nix-shell -p just --run "just bootstrap"

ok "Done! Open a new terminal to pick up the new environment."
