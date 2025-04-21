#!/bin/bash

KEY_ID="5F9DFF499091DE14"
KEY_FILE="$XDG_DATA_HOME/gnupg/private.key"

if gpg --list-secret-keys "$KEY_ID" > /dev/null 2>&1; then
  echo "Secret key already imported: $KEY_ID"
else
  echo "Importing GPG secret key interactively..."
  gpg --import "$KEY_FILE"
fi