#!/bin/bash

set -euo pipefail

# Get absolute path to the nix-config directory
NIXCONFIG_PATH="/Users/mael.lepetit/dev/nix-config"
cd "$NIXCONFIG_PATH"

if [[ "$MACHTYPE" == arm64* ]]; then
  echo "Detected architecture: ARM (aarch64-darwin)"
  # Use sudo to run the command as root, but preserve the path
  sudo nix run nix-darwin -- switch --flake "$NIXCONFIG_PATH"#maelito-arm --show-trace
elif [[ "$MACHTYPE" == x86_64* ]]; then
  echo "Detected architecture: x86_64 (x86_64-darwin)"
  sudo nix run nix-darwin -- switch --flake "$NIXCONFIG_PATH"#maelito-x86 --show-trace
else
  echo "Unsupported architecture: $MACHTYPE" >&2
  exit 1
fi
