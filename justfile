set shell := ["zsh", "-c"]

_default:
	@just -l

gens:
	@echo "Listing home-manager generations"
	@nix-env --list-generations

clean:
	@echo "Cleaning up unused Nix store items"
	@nix-collect-garbage -d

format:
	@nixfmt $(find ./ -type f -name '*.nix')

flake-update:
	@echo "Syncing latest git rev"
	@nix flake update

[macos]
rebuild:
  @echo "Rebuilding macOS configuration"
  ./scripts/rebuild-by-arch.sh
  ./scripts/import-gpg-key-once.sh
