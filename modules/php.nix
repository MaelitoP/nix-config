{ pkgs, ... }:
let
  withExtensions =
    php:
    php.withExtensions (
      { enabled, all }:
      enabled
      ++ (with all; [
        redis
        pcntl
        intl
      ])
    );
  php = withExtensions pkgs.php84;
  php85 = withExtensions pkgs.php85;
in
[
  php
  php.packages.composer
  # Both versions ship bin/php; 8.4 keeps that name and 8.5 is exposed as php85.
  (pkgs.runCommand "php85" { } ''
    mkdir -p $out/bin
    ln -s ${php85}/bin/php $out/bin/php85
  '')
]
