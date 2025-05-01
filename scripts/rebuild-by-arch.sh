#!/bin/bash

set -euo pipefail

if [[ "$MACHTYPE" == arm64* ]]; then
  echo "Detected architecture: ARM (aarch64-darwin)"
  nix run nix-darwin -- switch --flake .#maelito-arm --show-trace
elif [[ "$MACHTYPE" == x86_64* ]]; then
  echo "Detected architecture: x86_64 (x86_64-darwin)"
  nix run nix-darwin -- switch --flake .#maelito-x86 --show-trace
else
  echo "Unsupported architecture: $MACHTYPE" >&2
  exit 1
fi
