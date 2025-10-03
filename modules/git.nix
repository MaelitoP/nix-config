{ pkgs, ... }:
let
  name = "MaelitoP";
  email = "makibeardy@gmail.com";
in
{
  programs.git = {
    enable = true;
    userName = name;
    userEmail = email;
    ignores = [ ".DS_Store" ];

    extraConfig = {
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential.helper = if pkgs.stdenv.isDarwin then "osxkeychain" else "cache";
      help.autocorrect = 10;
      url."git@github.com:".insteadOf = "https://github.com/";
    };

    signing = {
      key = "5F9DFF499091DE14";
      signByDefault = true;
    };

    aliases = {
      cl = "clone --depth=1 --filter=blob:none";
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
    };
  };
}
