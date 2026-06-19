This repository contains my personal macOS development environment, managed with Nix and nix-darwin.

The goal is to make workstation setup reproducible and reviewable. System packages, shell configuration, editor setup, fonts, scripts, secrets, and host-specific settings are defined in code instead of being configured manually.

This is not intended to be a generic framework. It is my own development environment, kept public as a reference for building a practical nix-darwin setup.

To bootstrap a new machine:

    curl -sL https://raw.githubusercontent.com/MaelitoP/nix-config/main/scripts/install.sh | bash

