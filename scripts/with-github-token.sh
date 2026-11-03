#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
owner="${SUDO_USER:-$(id -un)}"
owner_home="$(dscl . -read "/Users/$owner" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
owner_home="${owner_home:-$HOME}"
config_home="$owner_home/.config"

export PATH="/nix/var/nix/profiles/default/bin:/etc/profiles/per-user/$owner/bin:$PATH"

run_sops() {
  if command -v sops > /dev/null 2>&1; then
    sops "$@"
  else
    nix --extra-experimental-features "nix-command flakes" \
      shell --inputs-from "$repo_dir" nixpkgs#sops -c sops "$@"
  fi
}

token=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  token="$GITHUB_TOKEN"
elif [ -r "$config_home/secrets/github_token" ]; then
  token="$(< "$config_home/secrets/github_token")"
elif [ -r "$config_home/sops/age/keys.txt" ]; then
  token="$(SOPS_AGE_KEY_FILE="$config_home/sops/age/keys.txt" \
    run_sops -d --extract '["github_token"]' "$repo_dir/secrets/common.yaml")" || token=""
fi

if [ -z "$token" ]; then
  echo "warning: no GitHub token found; private flake inputs will fail to fetch" >&2
else
  export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG
}access-tokens = github.com=$token"
fi

exec "$@"
