#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
bundle="SSH Config Manager.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
swiftc -parse-as-library SSHConfigManager.swift -o "$bundle/Contents/MacOS/SSH Config Manager"
cp Info.plist "$bundle/Contents/Info.plist"
cp AppIcon.icns "$bundle/Contents/Resources/AppIcon.icns"
open "$bundle"
