{ config, lib, ... }:

let
  picture = "${config.home.homeDirectory}/Pictures/background.jpg";
in
{
  home.file."Pictures/background.jpg".source = ../resources/background.jpg;

  home.activation.wallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "${picture}"'
  '';
}
