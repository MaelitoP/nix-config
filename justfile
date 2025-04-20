set shell := ["zsh", "-c"]

_default:
    @just -l

alias g := gens
alias f := format
alias c := clean
alias r := rebuild
alias u := flake-update

gens:
    @echo "Listing home-manager generations"
    @nix-env --list-generations

clean:
    @echo "Cleaning up unused Nix store items"
    @nix-collect-garbage -d

format:
    @nixfmt $(find ./ -type f -name '*.nix')
    @stylua -f $(find . -type f -name '.stylua.toml') $(find . -type f  -name '*.lua')

flake-update:
    @echo "Syncing latest git rev"
    @nix flake update

[macos]
rebuild:
    @echo " Rebuilding configuration"
    @nix run nix-darwin -- switch --flake .#agorapulse --show-trace
