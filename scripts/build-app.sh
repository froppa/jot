#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
app="$root/.build/Jot.app"

cd "$root"
swift build -c release
mkdir -p "$app/Contents/MacOS"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp .build/release/Jot "$app/Contents/MacOS/Jot"

print "Built $app"
