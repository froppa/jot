#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
app="$root/.build/ShelfNote.app"

cd "$root"
swift build -c release
mkdir -p "$app/Contents/MacOS"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp .build/release/ShelfNote "$app/Contents/MacOS/ShelfNote"

print "Built $app"
