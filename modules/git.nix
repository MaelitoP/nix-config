{ pkgs, ... }:
let
  name = "MaelitoP";
  email = "makibeardy@gmail.com";
in
{
  programs.git = {
    enable = true;
    ignores = [ ".DS_Store" ];

    signing = {
      key = "5F9DFF499091DE14";
      signByDefault = true;
      format = "openpgp";
    };

    settings = {
      user.name = name;
      user.email = email;
      pull.rebase = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true;
      credential.helper = if pkgs.stdenv.isDarwin then "osxkeychain" else "cache";
      help.autocorrect = 10;
      url."git@github.com:".insteadOf = "https://github.com/";

      alias = {
        cl = "clone --depth=1 --filter=blob:none";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
        tidy = "!git fetch --prune && git branch -vv | awk '/: gone]/ {print $1}' | xargs -I{} git branch -D {}";
      };
    };
  };
}
