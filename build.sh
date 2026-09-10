#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
bundle="SSH ConMan.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
build_dir=".build"
mkdir -p "$build_dir"
swiftc -parse-as-library -target arm64-apple-macosx14.0 SSHConfigManager.swift -o "$build_dir/SSHConfigManager-arm64"
swiftc -parse-as-library -target x86_64-apple-macosx14.0 SSHConfigManager.swift -o "$build_dir/SSHConfigManager-x86_64"
lipo -create "$build_dir/SSHConfigManager-arm64" "$build_dir/SSHConfigManager-x86_64" -output "$bundle/Contents/MacOS/SSH ConMan"
cp Info.plist "$bundle/Contents/Info.plist"
cp AppIcon.icns "$bundle/Contents/Resources/AppIcon.icns"
codesign --force --sign - --identifier local.ssh-config-manager "$bundle"
open "$bundle"
