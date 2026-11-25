{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  username = config.host.username;
  home = config.host.home;
  extraCasks = config.host.extraCasks;
  extraBrews = config.host.extraBrews;
  extraHosts = pkgs.writeText "extra-hosts" config.host.extraHosts;
  # nix-darwin 26.05 (x86 host) exposes brewBundleCmd as a string; unstable made it a function.
  brewBundleCmd = config.homebrew.onActivation.brewBundleCmd;
  brewBundle =
    if isFunction brewBundleCmd then brewBundleCmd { onlyCheck = false; } else brewBundleCmd;
  acceptXcodeLicense = "/bin/bash ${../scripts/accept-xcode-license.sh} || true";
in
{
  imports = [ ./common.nix ];

  options.host = {
    extraCasks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra casks";
    };
    extraBrews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra brews";
    };
  };

  config = {
    system.stateVersion = 5;
    system.primaryUser = username;

    security.pam.services.sudo_local.touchIdAuth = true;
    security.pam.services.sudo_local.reattach = true;
    security.sudo.extraConfig = ''
      ${config.host.realname} ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0
    '';

    networking.computerName = "maelito";

    homebrew = {
      enable = true;
      onActivation.autoUpdate = true;
      onActivation.upgrade = true;
      taps = [
        {
          name = "d12frosted/emacs-plus";
          trusted = true;
        }
      ];
      brews = [
        "libomp"
        "jpeg"
        "zlib"
        {
          name = "emacs-plus@30";
          args = [
            "with-imagemagick"
            "with-xwidgets"
          ];
        }
      ]
      ++ extraBrews;
      casks = [
        "ghostty"
        "goland"
        "phpstorm"
        "pycharm"
        "rustrover"
        "intellij-idea"
        "webstorm"
        "android-studio"
        "slack"
        "google-chrome"
        "spotify"
        "1password"
        "docker-desktop"
        "claude"
      ]
      ++ extraCasks;
      masApps = {
        Xcode = 497799835;
      };
    };

    environment.etc."Brewfile".text = config.homebrew.brewfile;

    # Upstream aborts the whole activation (home-manager included) when brew bundle fails.
    # mas installs Xcode inside brew bundle, so its license can only be accepted after the first attempt.
    system.activationScripts.homebrew.text = mkForce ''
      echo >&2 "Homebrew bundle..."
      if [ -f "${config.homebrew.prefix}/bin/brew" ]; then
        ${acceptXcodeLicense}
        if ! ${brewBundle}; then
          ${acceptXcodeLicense}
          ${brewBundle} || printf >&2 '\e[1;33mwarning: brew bundle failed; continuing activation. Run `just brew` to retry.\e[0m\n'
        fi
      else
        echo -e "\e[1;31merror: Homebrew is not installed, skipping...\e[0m" >&2
      fi
    '';

    system = {
      activationScripts.postActivation.text = mkAfter ''
        emacs_opt="/opt/homebrew/opt/emacs-plus@30"
        if [ -d "$emacs_opt" ]; then
          /bin/ln -sfn "$emacs_opt/Emacs.app" "/Applications/Emacs.app"
          # the Dock can't launch a symlinked bundle (shows "?"), so copy this one
          /bin/rm -rf "/Applications/Emacs Client.app"
          /bin/cp -R "$emacs_opt/Emacs Client.app" "/Applications/Emacs Client.app"
        fi

        # screencapture silently falls back to the Desktop when its location is missing.
        /usr/bin/sudo -u ${username} /bin/mkdir -p "${home}/Documents/screenshots"

        # /etc/hosts stays a plain file: Docker Desktop and other tools write to it too.
        hosts_tmp=$(/usr/bin/mktemp)
        /usr/bin/awk '/^# nix-config start$/ { skip = 1 } !skip { print } /^# nix-config end$/ { skip = 0 }' /etc/hosts > "$hosts_tmp"
        if [ -s ${extraHosts} ]; then
          { echo "# nix-config start"; /bin/cat ${extraHosts}; echo "# nix-config end"; } >> "$hosts_tmp"
        fi
        /bin/cat "$hosts_tmp" > /etc/hosts
        /bin/rm -f "$hosts_tmp"
      '';

      defaults = {
        dock = {
          autohide = true;
          show-recents = false;
          tilesize = 40;
          orientation = "right";
          persistent-apps = [
            "/Applications/Ghostty.app"
            "/Applications/Emacs Client.app"
            "/Applications/PhpStorm.app"
            "/Applications/GoLand.app"
            "/Applications/IntelliJ IDEA.app"
            "/Applications/RustRover.app"
            "/Applications/PyCharm.app"
            "/Applications/WebStorm.app"
            "/Applications/Android Studio.app"
            "/Applications/Slack.app"
            "/Applications/Google Chrome.app"
            "/Applications/Spotify.app"
          ];
        };

        CustomUserPreferences = {
          "com.apple.screencapture" = {
            location = "~/Documents/screenshots";
            type = "png";
          };
        };

        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
        };

        SoftwareUpdate = {
          AutomaticallyInstallMacOSUpdates = false;
        };

        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
        };
      };
    };
  };
}
