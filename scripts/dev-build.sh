#!/usr/bin/env bash
# Dev build helper — builds, installs to a fixed path, and launches.
set -euo pipefail
cd "$(dirname "$0")/.."

LOCAL_XCCONFIG="Config/Local.xcconfig"
INSTALL_PATH="$HOME/Applications/SelectApp-Dev.app"
BUILD_APP=".build/DerivedData/Build/Products/Debug/SelectApp.app"

XCODEBUILD_ARGS=(
  -project SelectApp.xcodeproj
  -scheme SelectApp
  -configuration Debug
  -derivedDataPath ./.build/DerivedData
)

signing_configured=false

if [[ -f "$LOCAL_XCCONFIG" ]]; then
  if grep -qE '^\s*DEVELOPMENT_TEAM\s*=\s*[A-Z0-9]{10}\s*$' "$LOCAL_XCCONFIG"; then
    team_id="$(grep -E '^\s*DEVELOPMENT_TEAM\s*=' "$LOCAL_XCCONFIG" | sed 's/.*=\s*//' | tr -d '[:space:]')"
    cert_count="$(security find-identity -v -p codesigning 2>/dev/null | grep -c 'Apple Development' || true)"

    if [[ "$cert_count" -gt 0 ]]; then
      echo "Signing with Team ID: $team_id"
      signing_configured=true
    else
      echo ""
      echo "⚠  Local.xcconfig has Team ID $team_id but no Apple Development certificate found."
      echo "   Xcode → Settings → Accounts → Manage Certificates → + → Apple Development"
      echo "   Falling back to ad-hoc signing for this build."
      echo ""
      XCODEBUILD_ARGS+=(DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY=-)
    fi
  else
    echo ""
    echo "⚠  Config/Local.xcconfig exists but DEVELOPMENT_TEAM is not set."
    echo "   See Config/Local.xcconfig.example for setup."
    echo "   Building with ad-hoc signing — permissions reset on every rebuild."
    echo ""
    XCODEBUILD_ARGS+=(DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY=-)
  fi
else
  echo ""
  echo "Tip: copy Config/Local.xcconfig.example → Config/Local.xcconfig"
  echo "     and set your Apple Development Team ID for persistent permissions."
  echo "     Building with ad-hoc signing for now."
  echo ""
  XCODEBUILD_ARGS+=(DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY=-)
fi

./.tools/xcodegen/bin/xcodegen generate
xcodebuild "${XCODEBUILD_ARGS[@]}" build

mkdir -p "$HOME/Applications"
echo "Installing to $INSTALL_PATH"
pkill -x SelectApp 2>/dev/null || true
sleep 0.3
ditto "$BUILD_APP" "$INSTALL_PATH"
xattr -cr "$INSTALL_PATH" 2>/dev/null || true

echo ""
echo "Installed: $INSTALL_PATH"
if [[ "$signing_configured" == true ]]; then
  echo "Grant Accessibility once for SelectApp-Dev in System Settings."
  echo "Use ONLY this install — not Xcode's DerivedData build."
else
  echo "Ad-hoc signing — grant Accessibility + Screen Recording once per rebuild."
fi

open "$INSTALL_PATH"
