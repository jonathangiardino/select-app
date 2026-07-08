#!/usr/bin/env bash
# Opens Accessibility settings and prints steps to fix stale dev permission entries.
set -euo pipefail

echo ""
echo "Fix dev Accessibility permissions"
echo "================================="
echo ""
echo "1. System Settings will open → Privacy & Security → Accessibility"
echo "2. Remove ALL 'Select' / 'SelectApp' entries (stale builds from DerivedData)"
echo "3. Click + and add:  ~/Applications/SelectApp-Dev.app"
echo "4. Enable the toggle"
echo "5. Run:  ./scripts/dev-build.sh"
echo ""
echo "Important: always launch via ./scripts/dev-build.sh — not Run from Xcode."
echo "           Xcode builds to a different DerivedData path."
echo ""

open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
