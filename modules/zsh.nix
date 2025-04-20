{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    KEYTIMEOUT = 15;

    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";

    ZDOTDIR = "${config.xdg.configHome}/zsh";

    GOPATH = "${config.xdg.dataHome}/go";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    LESSHISTFILE = "${config.xdg.cacheHome}/less/history";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    SSH_HOME = "${config.xdg.configHome}/ssh/ssh_config";

    PYENV_ROOT = "${config.home.homeDirectory}/.pyenv";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = ".config/zsh";

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "zsh-autosuggestions" "zsh-syntax-highlighting" "fzf" ];
    };

    history = {
      path = "${config.xdg.dataHome}/zsh/zsh_history";
      expireDuplicatesFirst = true;
      ignoreSpace = false;
      save = 15000;
      share = true;
      append = true;
      ignoreAllDups = true;
    };

    shellAliases = {
      ll = "ls -alF";

      v = "nvim";
      vim = "nvim";
      lkjh = "nvim";
      hjkl = "nvim";

      cdm = "cd ~/dev/mention";
      devup = "cdm; ./tools/devenv.sh up";
      devstop = "cdm; ./tools/devenv.sh stop";
      resetdbt = "cdm; ./tools/reset-db.sh test";
      resetdbd = "cdm; ./tools/reset-db.sh dev";
      runtest = "cdm; ./tools/run-tests.sh";
      ephp = "docker exec -it php_cli";
      mysql56 = "ephp mysql -u mention -p -h mysql_5_6";
      mysql57 = "ephp mysql -u mention -p -h mysql_5_7";
      brdiff = "def_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'); git diff origin/$def_branch...";
      brfiles = "def_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'); git diff --name-only origin/$def_branch...";
      composer = "/usr/local/bin/composer";
      phpd = "docker compose -f ~/mention/dev-env/docker-compose.yml exec php_cli php -dzend_extension=xdebug.so -dxdebug.mode=debug -dxdebug.start_with_request=yes -dxdebug.client_host=172.17.0.1 -dxdebug.client_port=9003";
      gdiffc = "git diff master | xclip -selection clipboard";
    };

    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"

      # Brew
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

      # CUDA
      if [ -d "/usr/local/cuda-12.4/bin" ]; then
        export PATH="/usr/local/cuda-12.4/bin:$PATH"
      fi
      if [ -d "/usr/local/cuda-12.4/lib64" ]; then
        export LD_LIBRARY_PATH="/usr/local/cuda-12.4/lib64:$LD_LIBRARY_PATH"
      fi

      # Opam
      [[ -r "$HOME/.opam/opam-init/init.zsh" ]] && source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null

      # Pyenv
      [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
      eval "$(pyenv init -)"

      # fnm
      FNM_PATH="$HOME/.local/share/fnm"
      if [ -d "$FNM_PATH" ]; then
        export PATH="$FNM_PATH:$PATH"
        eval "$(fnm env)"
      fi

      # Mention dev-env config
      if [ -f "$HOME/dev/mention/dev-env/config/rc_files/zshrc" ]; then
        source "$HOME/dev/mention/dev-env/config/rc_files/zshrc"
      fi

      # Tmux autostart
      if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
        exec tmux
      fi

      eval "$(starship init zsh)"
      nerdfetch
    '';
  };
}

