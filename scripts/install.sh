#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/MaelitoP/nix-config.git"
REPO_DIR="$HOME/dev/nix-config"
AGE_KEY_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"
NIX_CONF="$HOME/.config/nix/nix.conf"
NIX_PROFILE="/nix/var/nix/profiles/default"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

if xcode-select -p &> /dev/null; then
  ok "Xcode Command Line Tools already installed"
else
  info "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  until xcode-select -p &> /dev/null; do
    sleep 10
  done
  ok "Xcode Command Line Tools installed"
fi

# Clean up stale backups from a previous Nix install
for f in /etc/bashrc.backup-before-nix /etc/zshrc.backup-before-nix /etc/bash.bashrc.backup-before-nix; do
  if [ -f "$f" ]; then
    warn "Removing stale Nix backup: $f"
    sudo rm "$f"
  fi
done

if [ -x "$NIX_PROFILE/bin/nix" ]; then
  ok "Nix already installed"
else
  info "Installing Nix..."
  NIX_INSTALLER="$(mktemp)"
  curl -L -o "$NIX_INSTALLER" https://nixos.org/nix/install
  sh "$NIX_INSTALLER" --yes
  rm -f "$NIX_INSTALLER"
fi

# shellcheck disable=SC1091
. "$NIX_PROFILE/etc/profile.d/nix-daemon.sh"
command -v nix > /dev/null || { echo "error: nix not on PATH" >&2; exit 1; }

if [ -f "$NIX_CONF" ] && grep -q "flakes" "$NIX_CONF"; then
  ok "Flakes already enabled"
else
  info "Enabling flakes..."
  mkdir -p "$(dirname "$NIX_CONF")"
  echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
fi

if [ -x /opt/homebrew/bin/brew ]; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

if [ -d "$REPO_DIR/.git" ]; then
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
  AGE_KEY_SRC="${AGE_KEY_SRC/#\~/$HOME}"
  [ -f "$AGE_KEY_SRC" ] || { echo "error: $AGE_KEY_SRC not found" >&2; exit 1; }
  mkdir -p "$AGE_KEY_DIR"
  cp "$AGE_KEY_SRC" "$AGE_KEY_FILE"
  chmod 600 "$AGE_KEY_FILE"
  ok "Age key copied to $AGE_KEY_FILE"
fi

if [ -d /Applications/Xcode.app ]; then
  ok "Xcode already installed"
else
  warn "Xcode is installed from the Mac App Store during the switch; sign in to the App Store now."
  printf "Press enter once signed in (or to skip): "
  read -r < /dev/tty
fi

info "Running bootstrap..."
cd "$REPO_DIR"
nix --extra-experimental-features "nix-command flakes" \
  shell --inputs-from . nixpkgs#just nixpkgs#git -c just bootstrap

ok "Done! Open a new terminal to pick up the new environment."
