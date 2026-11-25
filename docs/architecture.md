# Architecture

This repository describes whole workstations: two Macs (nix-darwin, Homebrew apps) and one NixOS desktop, sharing the same user environment (home-manager) and secrets (sops). A fresh Mac converges to the same state with `scripts/install.sh`, the desktop with [install-nixos.md](install-nixos.md), and every later change goes through `just rebuild`.

## Layout

| Path | Role |
|---|---|
| `flake.nix` | Inputs and the `mkDarwinConfig` / `mkNixosConfig` functions that assemble a host around the shared home-manager block |
| `hosts/common.nix` | `host.*` options and the system settings that are identical on every OS: user, nix settings, zsh, GitHub's SSH host key, fonts |
| `hosts/darwin.nix` | macOS system layer: nix-darwin settings, Homebrew, macOS defaults, activation scripts |
| `hosts/maelito-arm.nix`, `hosts/maelito-x86.nix` | Per-machine values: user, platform, extra brews/casks, extra `/etc/hosts` lines, work module |
| `hosts/nixos.nix` | NixOS system layer: boot loader, NetworkManager, user, sound, Docker, 1Password, GUI apps |
| `hosts/hyprland.nix` | The desktop session (Hyprland behind greetd); swapping desktops means swapping this import. It pulls in `modules/hyprland.nix` (window look, key bindings, launcher, notifications) and `modules/waybar.nix` (the top bar) |
| `hosts/maelito-desktop/` | The NixOS desktop: hardware, NVIDIA driver, Secure Boot through lanzaboote, disk layout (`disk.nix`, applied by disko at install) |
| `hosts/wireguard.nix` | The `laptop` WireGuard tunnel (arm host only) |
| `modules/` | home-manager modules, one per tool; `modules/default.nix` lists the ones every host gets, `modules/agorapulse.nix` is imported by work hosts only |
| `resources/` | Files deployed as-is: wallpaper, Claude `CLAUDE.md` and skills, the historical cluster CA |
| `secrets/` | sops-encrypted secrets, see [secrets.md](secrets.md) |
| `scripts/` | Bootstrap helpers called by `install.sh` and the `justfile` |
| `justfile` | Day-to-day entry points (`bootstrap`, `rebuild`, `check`, `brew`, `update`…) |
| `.github/workflows/check.yml` | CI: evaluates every host (the Macs on macOS, the desktop on Linux), checks formatting, lints scripts |
| `.githooks/pre-commit` | Formats staged `.nix` files with nixfmt |

## Hosts

`mkDarwinConfig` builds one nix-darwin system per host and plugs home-manager in as a nix-darwin module, so a single `darwin-rebuild switch` applies both layers.

- **`maelito-arm`** (Apple Silicon, the work laptop) follows `nixpkgs-unstable` and the matching home-manager / nix-darwin branches.
- **`maelito-x86`** (Intel) is pinned to the 26.05 branches, because nixpkgs 26.11 dropped `x86_64-darwin`. Options sometimes differ between the two generations (e.g. `homebrew.onActivation.brewBundleCmd` is a function on unstable and a string on 26.05), so shared code must evaluate on both. CI dry-builds both hosts for that reason.

- **`maelito-desktop`** (x86_64 Linux, dual-booted with Windows) is built by `mkNixosConfig` on `nixpkgs-unstable`. It gets none of the work modules, and its flake inputs are all public, so it installs without a GitHub token. It cannot be evaluated on a Mac: the catppuccin module builds its themes during evaluation, which needs a Linux builder.

Modules that differ per OS branch inline on `pkgs.stdenv.hostPlatform`; `launchd.agents` are ignored on Linux and `systemd.user` on macOS, so both can sit next to their tool.

Flake inputs that are my own projects (`nvim-config`, `emacs-config`, `scwx`, `cairn`) expose home-manager modules; their packages are pinned per host to that host's nixpkgs.

## System layer (`hosts/common.nix`, `hosts/darwin.nix`)

- **Shared** (`common.nix`): the user, nix settings, zsh, GitHub's SSH host key, fonts (`modules/fonts.nix`).
- **nix-darwin basics**: primary user, Touch ID for sudo, a passwordless `pmset` rule used by the Claude sleep guard.
- **Homebrew**: brews, casks and Mac App Store apps are declared here (plus `extraBrews`/`extraCasks` per host). Activation runs `brew bundle` with `upgrade = true`, and a failed bundle only prints a warning instead of aborting the whole activation. There is no `cleanup`: removing something from the list does not uninstall it.
- **macOS defaults**: Dock, key repeat, trackpad, dark mode, screenshot location.
- **Activation extras**: links Emacs.app and copies Emacs Client.app into `/Applications`, creates `~/Documents/screenshots`, and rewrites the `# nix-config start/end` block of `/etc/hosts` from `host.extraHosts`. `/etc/hosts` stays a plain file because Docker Desktop writes to it too.
- **WireGuard** (`hosts/wireguard.nix`): `networking.wg-quick.interfaces.laptop`, full tunnel, `autostart = false`. The private key is a system-level sops secret in `/run/secrets`, re-decrypted at boot by the `sops-install-secrets` daemon. `vpnup` / `vpndown` bring it up and down.

## Home layer (`modules/`)

| Area | Modules |
|---|---|
| Shell | `zsh` (oh-my-zsh, XDG paths, aliases, tmux autostart), `starship`, `fzf`, `direnv`, `bat`, `fastfetch` |
| Terminal & editors | `ghostty`, `tmux` (catppuccin, resurrect/continuum, launchd-owned server), `emacs` (daemon via launchd), Neovim from the `nvim-config` flake |
| Toolchains | `pkgs.nix` aggregates `rust`, `go`, `ocaml`, `php`, `python`, `haskell`, `java`, `lsp`; `mise.nix` writes the global mise config |
| Identity & access | `git` (signed commits, https→ssh rewrite), `gpg`, `ssh` (keys from sops, keychain agent), `github`, `nix` (GitHub access token), `npm`, `scw` (Scaleway CLI config) |
| Claude Code | `claude.nix`: `settings.json`, `CLAUDE.md`, skills, plugins, model settings, the session-title hooks (`resources/claude/hooks/session-title.sh`: a background `Stop` hook asks Haiku for a title every few prompts, a `UserPromptSubmit` hook applies it like `/rename`); a launchd watcher in `zsh.nix` re-enables sleep when no session is left |
| Work (Agorapulse) | `agorapulse.nix`, imported by `hosts/maelito-arm.nix` only: `cairn` (daemon) and `scwx` (Scaleway helper), work shell aliases, pulse environment files, AWS credentials, nomad and historical cluster credentials, dev client certificate, the `grafana` CLI (`resources/grafana.sh`: read-only Grafana API and Graphite queries over the client certificate) |
| Look | catppuccin mocha everywhere (`modules/default.nix`), `wallpaper` |

Long-running user services are launchd agents declared next to their tool: tmux server, Emacs daemon, cairn daemon, Claude sleep watcher, `ssh-add` into the keychain, and the sops-nix agent.

## Ownership with pulse

pulse (Agorapulse's CLI) installs and writes some of the same things as this repo. nix-config is the persistent part: it declares everything it needs even when pulse installs it too, so the setup survives without pulse. Two consequences:

- Duplicate installs are fine; pulse finds them already present.
- Files that pulse writes to are never read-only Nix symlinks. Nix rewrites them as plain files on every activation instead: `~/.config/mise/config.toml` (pulse runs `mise use -g`) and `~/.agorapulse/environment/*`.

## Secrets

Everything secret lives in `secrets/`, encrypted with sops for a single age key (`~/.config/sops/age/keys.txt`, the only thing to carry to a new machine). Files reach the machine either as read-only sops symlinks or as plain files rewritten on activation; [secrets.md](secrets.md) lists which is which and why.

Work-only secrets are isolated in `secrets/agorapulse.yaml` and `secrets/client-key_dev.p12`.

## Lifecycle

1. **Fresh machine**: `scripts/install.sh` installs the Xcode CLI tools, Nix (flakes enabled), Homebrew, clones this repo, asks for the age key, then runs `just bootstrap`: first build, move `/etc/{bashrc,zshrc}` aside, `darwin-rebuild switch` (retried once), GPG key import, `mise install`.
2. **Every change**: edit, `just check` (dry build of the current host, shellcheck, nixfmt), `just rebuild`.
3. **CI**: on pushes to `main` and on pull requests, dry builds of every host, nixfmt, shellcheck.
4. **Upkeep**: `just update` (flake inputs), `just brew` (bundle only), `just clean` (garbage collection).

## Leaving Agorapulse

The work-specific parts are meant to be removable in one pass: `modules/agorapulse.nix` and its import in `hosts/maelito-arm.nix`, `secrets/agorapulse.yaml`, `secrets/client-key_dev.p12`, `resources/historical-ca.pem`, `resources/grafana.sh`, and `host.extraHosts` in `hosts/maelito-arm.nix`.
