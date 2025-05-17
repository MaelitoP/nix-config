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
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'macchiato'
          set -g @catppuccin_window_status_style 'rounded'
          set -g @catppuccin_date_time_icon "󰃰 "
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

      unbind r
      bind r source-file "$HOME/.config/tmux/tmux.conf"\; display-message "Reloading tmux.conf"

      unbind x
      bind x kill-pane

      unbind b 
      bind b set-option status\; refresh-client -S # Toggle tmux bar

      # vim-like pane switching
      bind -r ^ last-window
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R

      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_user}#{E:@catppuccin_status_date_time}"
    '';
  };
}
