#!/bin/bash

set -euo pipefail

if [[ "$MACHTYPE" == arm64* ]]; then
  echo "Detected architecture: ARM (aarch64-darwin)"
  nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.maelito-arm.system
  sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#maelito-arm --show-trace
elif [[ "$MACHTYPE" == x86_64* ]]; then
  echo "Detected architecture: x86_64 (x86_64-darwin)"
  nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.maelito-x86.system
  sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#maelito-x86 --show-trace
else
  echo "Unsupported architecture: $MACHTYPE" >&2
  exit 1
fi
