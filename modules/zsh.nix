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

    # Go
    GOPATH = "${config.xdg.dataHome}/go";
    CGO_CC = "/usr/bin/clang";
    CGO_CXX = "/usr/bin/clang++";

    # Rust
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";

    # OCaml
    OPAMROOT = "${config.xdg.dataHome}/opam";
    DUNE_CACHE_ROOT = "${config.xdg.dataHome}/dune";

    LESSHISTFILE = "${config.xdg.cacheHome}/less/history";

    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";

    SSH_HOME = "${config.xdg.configHome}/ssh/ssh_config";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
      ];
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

      cdi = "cd ~/dev/platform-ingestor";
      iup = "cdi; ./tools/devenv.sh up";
      istop = "cdi; ./tools/devenv.sh up";
      irdbt = "cdi; ./tools/reset-db.sh test";
      irdtd = "cdi; ./tools/reset-db.sh dev";
      itest = "cdi; ./tools/run-tests.sh";

      cdm = "cd ~/dev/mention";
      mup = "cdm; ./tools/devenv.sh stop";
      mstop = "cdm; ./tools/devenv.sh stop";
      mrdbt = "cdm; ./tools/reset-db.sh test";
      mrdtd = "cdm; ./tools/reset-db.sh dev";
      mtest = "cdm; ./tools/run-tests.sh";
      mphp = "docker exec -it php_cli";
      mysql56 = "mphp mysql -u mention -p -h mysql_5_6";
      mysql57 = "mphp mysql -u mention -p -h mysql_5_7";

      brdiff = "def_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'); git diff origin/$def_branch...";
      brfiles = "def_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'); git diff --name-only origin/$def_branch...";
      gpf = "git push --force-with-lease";
    };

    initContent = ''
      export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

      export PATH="$HOME/.local/bin:$PATH"

      export PATH="$HOME/.opencode/bin:$PATH"

      export PATH="$HOME/dev/cli/bin:$PATH"

      export CGO_CC="/usr/bin/clang"
      export CGO_CXX="/usr/bin/clang++"
      export CC="/usr/bin/clang"
      export CXX="/usr/bin/clang++"

      # Opam configuration
      [[ ! -r "$HOME/.local/share/opam/opam-init/init.zsh" ]] || source "$HOME/.local/share/opam/opam-init/init.zsh" > /dev/null 2> /dev/null

      # Nvm configuration
      export NVM_DIR="$HOME/.config/nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      gpgconf --launch gpg-agent

      # Tmux autostart
      if command -v tmux &> /dev/null \
        && [ -n "$PS1" ] \
        && [[ ! "$TERM" =~ screen ]] \
        && [[ ! "$TERM" =~ tmux ]] \
        && [ -z "$TMUX" ] \
        && [[ "$TERMINAL_EMULATOR" != JetBrains* ]]; then
        exec tmux
      fi

      eval "$(scw autocomplete script shell=zsh)"

      eval "$(starship init zsh)"

      eval "$(mise activate zsh)"

      fastfetch
    '';
  };
}
