set shell := ["zsh", "-c"]

hostname := if arch() == "aarch64" { "maelito-arm" } else { "maelito-x86" }

_default:
	@just -l

# First-time setup on a fresh machine (before darwin-rebuild exists)
[macos]
bootstrap:
    @echo "Bootstrapping nix-darwin for {{hostname}}"
    @for f in /etc/bashrc /etc/zshrc; do \
      if [ -f "$$f" ] && [ ! -L "$$f" ]; then \
        echo "==> Moving $$f to $$f.before-nix-darwin for nix-darwin"; \
        sudo mv -f "$$f" "$$f.before-nix-darwin"; \
      fi; \
    done
    # First run may fail: nix-darwin's activate script runs
    # `launchctl kill HUP system/org.nixos.nix-daemon` to reload the daemon,
    # which exits 3 ("No process to signal") on a fresh machine because the
    # daemon isn't running under nix-darwin's launchd service yet.
    # The second run succeeds because the first registered the service.
    -sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#{{hostname}} --show-trace
    sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#{{hostname}} --show-trace
    ./scripts/import-gpg-key-once.sh

# Rebuild and apply the configuration
[macos]
rebuild:
    @echo "Rebuilding configuration for {{hostname}}"
    nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.{{hostname}}.system
    sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#{{hostname}} --show-trace
    ./scripts/import-gpg-key-once.sh

# Dry-run build to validate without applying
[macos]
check:
    @echo "Checking configuration for {{hostname}}"
    nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.{{hostname}}.system --dry-run
    @echo "Linting shell scripts"
    shellcheck scripts/*.sh
    @echo "Checking formatting"
    @fd -e nix -x nixfmt --check

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
    @nix flake update
