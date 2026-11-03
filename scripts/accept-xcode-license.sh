#!/bin/bash
set -euo pipefail

xcode=/Applications/Xcode.app/Contents/Developer
xcodebuild="$xcode/usr/bin/xcodebuild"

[ -x "$xcodebuild" ] || exit 0

if DEVELOPER_DIR="$xcode" "$xcodebuild" -checkFirstLaunchStatus > /dev/null 2>&1; then
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "accept-xcode-license.sh: must run as root" >&2
  exit 1
fi

DEVELOPER_DIR="$xcode" "$xcodebuild" -license accept
DEVELOPER_DIR="$xcode" "$xcodebuild" -runFirstLaunch
