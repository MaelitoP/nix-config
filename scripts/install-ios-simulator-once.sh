#!/usr/bin/env bash
set -euo pipefail

if [ ! -d "/Applications/Xcode.app" ]; then
  echo "Xcode.app not found in /Applications. Wait for masApps to finish, then re-run."
  exit 1
fi

sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch

xcodebuild -downloadPlatform iOS
