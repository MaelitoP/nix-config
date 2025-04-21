#!/bin/bash

set -euo pipefail

KEY_ID="5F9DFF499091DE14"
KEY_FILE="$XDG_DATA_HOME/gnupg/private.key"
PASSPHRASE=$(cat "$XDG_DATA_HOME/gnupg/passphrase.txt")

if gpg --list-secret-keys "$KEY_ID" > /dev/null 2>&1; then
  echo "Secret key already imported: $KEY_ID"
else
  echo "Importing GPG secret key interactively..."
  gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$PASSPHRASE" \
    --import "$KEY_FILE"
fi