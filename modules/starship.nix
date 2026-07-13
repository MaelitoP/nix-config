{ lib, pkgs, ... }:

let
  macos_prompt = {
    error_symbol = "[ ](red)";
    vimcmd_symbol = "[ ](green)";
    success_symbol = "[ ](rosewater)";
  };

  linux_prompt = {
    error_symbol = "[ ](red)";
    vimcmd_symbol = "[ ](green)";
    success_symbol = "[ ](rosewater)";
  };

in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      scan_timeout = 10;

      format = "$directory$git_branch$character";
      right_format = "$nix_shell";

      character = if pkgs.stdenv.isDarwin then macos_prompt else linux_prompt;

      os = {
        disabled = false;
        style = "rosewater";
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
      };

      directory = {
        style = "bold pink";
        truncation_length = 1;
        read_only = " 󰌾";
      };

      git_branch = {
        symbol = " ";
        format = "on [$symbol$branch]($style) ";
        truncation_length = 10;
        truncation_symbol = "…/";
        style = "bold green";
      };

      git_status = {
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        conflicted = "󱃞";
        deleted = " ";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        format = "[\\($all_status$ahead_behind\\)]($style) ";
        modified = " ";
        renamed = "󰖷 ";
        staged = "[++\\($count\\)](green)";
        stashed = "󰏗 ";
        style = "bold green";
        untracked = " ";
        up_to_date = " ";
      };

      nix_shell = {
        format = "[$symbol$state]($style)";
        impure_msg = "impure";
        pure_msg = "pure";
        symbol = "󱄅 ";
        unknown_msg = "unknown";
      };

      # Extra symbols for languages or tools
      aws.symbol = "  ";
      buf.symbol = " ";
      c.symbol = " ";
      cmake.symbol = " ";
      conda.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fossil_branch.symbol = " ";
      git_commit.tag_symbol = "  ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nodejs.symbol = " ";
      ocaml.symbol = " ";
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      swift.symbol = " ";
      zig.symbol = " ";
      gradle.symbol = " ";
    };
  };
}
