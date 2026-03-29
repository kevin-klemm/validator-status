#!/bin/bash
set -euo pipefail

# Install xcodegen if needed
if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen via Homebrew..."
    brew install xcodegen
fi

cd "$(dirname "$0")"

echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Done! Open ValidatorStatus.xcodeproj in Xcode."
echo ""
echo "Before building:"
echo "  1. Select your signing team for both targets"
echo "  2. Enable App Groups capability: group.com.validatorstatus.shared"
echo "  3. Build & Run the ValidatorStatus scheme"
echo "  4. Add the widget from your desktop (right-click → Edit Widgets)"
echo ""
echo "The host app is invisible (LSUIElement) — no dock icon, no window."
echo "Configure the validator index and API key via Edit Widget."
