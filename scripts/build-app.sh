#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
app="$root/.build/Jot.app"

cd "$root"
swift build -c release
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/Jot.icns "$app/Contents/Resources/Jot.icns"
cp .build/release/Jot "$app/Contents/MacOS/Jot"

print "Built $app"
