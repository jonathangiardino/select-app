#!/usr/bin/env bash
#
# Release scaffold for Select — builds, signs, notarizes, and packages a .dmg,
# then (once Sparkle is integrated) regenerates the appcast.
#
# Prerequisites (only needed at release time):
#   - Full Xcode installed
#   - Apple Developer Program membership + a "Developer ID Application" certificate
#   - A notarytool keychain profile: `xcrun notarytool store-credentials`
#
# This is a starting point — fill in TEAM_ID / signing identity / notary profile.
set -euo pipefail

APP_NAME="SelectApp"
SCHEME="SelectApp"
CONFIG="Release"
BUILD_DIR="./.build/release"
EXPORT_DIR="${BUILD_DIR}/export"
DEVELOPER_ID="Developer ID Application: YOUR NAME (TEAMID)"   # TODO
NOTARY_PROFILE="SelectAppNotary"                              # TODO: xcrun notarytool store-credentials

rm -rf "${BUILD_DIR}"
mkdir -p "${EXPORT_DIR}"

echo "==> Archiving"
xcodebuild -project "${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIG}" \
  -derivedDataPath "${BUILD_DIR}/DerivedData" \
  -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
  archive

echo "==> Exporting app"
# The exported app lives in the archive; copy it out for signing/packaging.
cp -R "${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app" "${EXPORT_DIR}/"

echo "==> Code signing (Developer ID, hardened runtime)"
codesign --force --deep --options runtime \
  --sign "${DEVELOPER_ID}" \
  "${EXPORT_DIR}/${APP_NAME}.app"

echo "==> Building DMG (hdiutil — no extra tooling required)"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"
hdiutil create -volname "Select" \
  -srcfolder "${EXPORT_DIR}/${APP_NAME}.app" \
  -ov -format UDZO "${DMG_PATH}"

echo "==> Notarizing"
xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
xcrun stapler staple "${DMG_PATH}"

echo "==> Done: ${DMG_PATH}"

# TODO (after adding Sparkle):
#   generate_appcast ./path/to/updates_directory
#   (upload the .dmg and appcast.xml to your website / GitHub Releases)
