set shell := ["zsh", "-c"]

hostname := if arch() == "aarch64" { "maelito-arm" } else { "maelito-x86" }
brew_prefix := if arch() == "aarch64" { "/opt/homebrew" } else { "/usr/local" }
nix := "nix --extra-experimental-features 'nix-command flakes'"

export PATH := "/etc/profiles/per-user/" + env("USER") + "/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:" + brew_prefix + "/bin:" + env("PATH")

build := nix + " build .#darwinConfigurations." + hostname + ".system"
switch := "sudo -H ./scripts/with-github-token.sh ./result/sw/bin/darwin-rebuild switch --flake .#" + hostname + " --show-trace"

_default:
	@just -l

# First-time setup on a fresh machine (before darwin-rebuild exists)
[macos]
bootstrap: _preflight
    @echo "Bootstrapping nix-darwin for {{hostname}}"
    ./scripts/with-github-token.sh {{build}}
    just _etc-shell-files
    # nix-darwin HUPs the nix-daemon, which exits 3 on a fresh machine where the daemon isn't under its launchd service yet.
    {{switch}} || { echo "==> First switch failed; retrying once"; {{switch}}; }
    ./scripts/import-gpg-key-once.sh
    mise install
    @echo "==> Done. Open a new terminal to pick up the new environment."

# Rebuild and apply the configuration
[macos]
rebuild:
    @echo "Rebuilding configuration for {{hostname}}"
    ./scripts/with-github-token.sh {{build}}
    {{switch}}
    ./scripts/import-gpg-key-once.sh

# Re-run the Homebrew bundle without a full switch
[macos]
brew:
    sudo ./scripts/accept-xcode-license.sh
    brew bundle --file=/etc/Brewfile --no-upgrade

# Dry-run build to validate without applying
[macos]
check:
    @echo "Checking configuration for {{hostname}}"
    ./scripts/with-github-token.sh {{build}} --dry-run
    @echo "Linting shell scripts"
    shellcheck scripts/*.sh
    @echo "Checking formatting"
    @fd -e nix -x nixfmt --check

# One-shot: accept Xcode license + download iOS simulator runtime
[macos]
ios-setup:
    ./scripts/install-ios-simulator-once.sh

# List home-manager generations
generations:
    @nix-env --list-generations

# Garbage-collect unused Nix store items
clean:
    @nix-collect-garbage -d

# Format all .nix files
format:
    @fd -e nix -x nixfmt

# Update flake inputs
update:
    @echo "Updating flake inputs"
    ./scripts/with-github-token.sh {{nix}} flake update

[macos]
_preflight:
    @command -v nix >/dev/null || { echo "error: nix not found; run: . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" >&2; exit 1; }
    @[ -x {{brew_prefix}}/bin/brew ] || { echo "error: Homebrew not found at {{brew_prefix}}/bin/brew" >&2; exit 1; }
    @[ -f "$HOME/.config/sops/age/keys.txt" ] || { echo "error: age key missing at ~/.config/sops/age/keys.txt (see docs/secrets.md)" >&2; exit 1; }

[macos]
_etc-shell-files:
    @for f in /etc/bashrc /etc/zshrc; do \
      if [ -f "$f" ] && [ ! -L "$f" ]; then \
        [ ! -e "$f.before-nix-darwin" ] || { echo "error: $f.before-nix-darwin already exists; reconcile it with $f by hand" >&2; exit 1; }; \
        echo "==> Moving $f to $f.before-nix-darwin for nix-darwin"; \
        sudo mv "$f" "$f.before-nix-darwin"; \
      fi; \
    done
