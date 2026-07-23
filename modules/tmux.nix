{ pkgs, config, ... }:

{
  programs.tmux = {
    enable = true;
    newSession = true;
    shell = "/bin/zsh";

    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.yank
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style 'rounded'
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
          set -g @catppuccin_date_time_icon "󰃰 "
        '';
      }
      tmuxPlugins.resurrect
      {
        # continuum injects its autosave hook into status-right when it loads:
        # status-right must be set before this plugin, and nothing may set it after.
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g status-right "#{E:@catppuccin_status_user}#{E:@catppuccin_status_date_time}"
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    extraConfig = ''
      set-option -g default-command "/bin/zsh -l"

      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      bind -n M-H previous-window
      bind -n M-L next-window

      set -g status on
      set -g escape-time 0
      set -g set-clipboard on
      set -g allow-rename off

      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none

      set -g base-index 1
      set -g pane-base-index 1
      set -g pane-base-index 1
      set -g renumber-windows on
      set -g mouse on

      # On kill-session, switch to another session; only detach if none remain
      set -g detach-on-destroy no-detached

      unbind r
      bind r source-file "$HOME/.config/tmux/tmux.conf"\; display-message "Reloading tmux.conf"

      unbind x
      bind x kill-pane

      bind X confirm-before -p "kill session #S? (y/n)" kill-session

      unbind b 
      bind b set-option status\; refresh-client -S # Toggle tmux bar

      # vim-like pane switching
      bind -r ^ last-window
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R

      set -g status-left ""
    '';
  };

  # The catppuccin module's autoEnable already themes tmux through its own
  # plugin load; the manual plugin entry above is the one carrying our options.
  catppuccin.tmux.enable = false;

  # Own the tmux server via launchd so it lives outside any terminal app's
  # process group; macOS terminating ghostty/wezterm cannot take it down.
  launchd.agents.tmux = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "${pkgs.tmux}/bin/tmux has-session 2>/dev/null || ${pkgs.tmux}/bin/tmux new-session -d -s main"
      ];
      # resurrect/continuum run-shell scripts inherit the server env and
      # invoke tmux and coreutils by bare name.
      EnvironmentVariables.PATH = "/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      RunAtLoad = true;
      StartInterval = 300;
    };
  };
}
