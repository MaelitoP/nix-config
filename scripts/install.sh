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
  read -r
fi

if command -v nix &>/dev/null; then
  ok "Nix already installed"
else
  info "Installing Nix..."
  curl -L https://nixos.org/nix/install | sh
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
  ok "Repo already cloned at $REPO_DIR"
else
  info "Cloning nix-config..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

if [ -f "$AGE_KEY_FILE" ]; then
  ok "Age key already present"
else
  warn "sops-nix needs your age secret key to decrypt secrets."
  echo "Paste the key contents below, then press Ctrl-D:"
  mkdir -p "$AGE_KEY_DIR"
  cat > "$AGE_KEY_FILE"
  chmod 600 "$AGE_KEY_FILE"
  ok "Age key written to $AGE_KEY_FILE"
fi

info "Running bootstrap..."
cd "$REPO_DIR"
nix-shell -p just --run "just bootstrap"

ok "Done! Open a new terminal to pick up the new environment."
