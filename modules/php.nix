{ pkgs, ... }:
let
  php = pkgs.php84.withExtensions (
    { enabled, all }:
    enabled
    ++ (with all; [
      redis
      pcntl
      intl
    ])
  );
in
[
  php
  php.packages.composer
]
