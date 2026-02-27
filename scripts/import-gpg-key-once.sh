#!/bin/bash

set -euo pipefail

KEY_ID="5F9DFF499091DE14"
GNUPG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gnupg"
KEY_FILE="$GNUPG_DIR/private.key"
PASSPHRASE_FILE="$GNUPG_DIR/passphrase.txt"

if [ ! -f "$PASSPHRASE_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "GPG secrets not yet available (sops-nix has not decrypted them)."
  echo "Run 'just rebuild' to activate sops-nix, then re-run this script."
  exit 0
fi

if gpg --list-secret-keys "$KEY_ID" > /dev/null 2>&1; then
  echo "Secret key already imported: $KEY_ID"
  exit 0
fi

echo "Importing GPG secret key..."
PASSPHRASE=$(cat "$PASSPHRASE_FILE")
gpg \
  --batch \
  --yes \
  --pinentry-mode loopback \
  --passphrase "$PASSPHRASE" \
  --import "$KEY_FILE" || true

if gpg --list-secret-keys "$KEY_ID" > /dev/null 2>&1; then
  echo "Secret key imported: $KEY_ID"
else
  echo "Failed to import GPG key $KEY_ID"
  exit 1
fi
