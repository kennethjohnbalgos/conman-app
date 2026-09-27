#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
bundle="SSH ConMan.app"
launch_after_build=true
if [[ "${1:-}" == "--no-open" ]]; then
  launch_after_build=false
fi
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
build_dir=".build"
mkdir -p "$build_dir"
swiftc -parse-as-library -target arm64-apple-macosx14.0 SSHConfigManager.swift -o "$build_dir/SSHConfigManager-arm64"
swiftc -parse-as-library -target x86_64-apple-macosx14.0 SSHConfigManager.swift -o "$build_dir/SSHConfigManager-x86_64"
lipo -create "$build_dir/SSHConfigManager-arm64" "$build_dir/SSHConfigManager-x86_64" -output "$bundle/Contents/MacOS/SSH ConMan"
cp Info.plist "$bundle/Contents/Info.plist"
cp AppIcon-v2.icns "$bundle/Contents/Resources/AppIcon-v2.icns"
codesign --force --sign - --identifier local.ssh-config-manager "$bundle"
if $launch_after_build; then
  open "$bundle"
fi
