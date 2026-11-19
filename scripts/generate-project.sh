#!/bin/bash
set -euo pipefail
qr_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$qr_root"
xcodegen generate --spec project.yml
qr_pins="QRReader.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
mkdir -p "$qr_pins"
cp Config/Xcode-Package.resolved "$qr_pins/Package.resolved"
