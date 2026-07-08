# Distribution, Updates & Lifetime Licensing

Guide for shipping Select as a downloadable Mac app with lifetime licenses.

---

## Overview

| Stage | What you need |
|-------|----------------|
| **Dev builds** | `./scripts/dev-build.sh` → `~/Applications/SelectApp-Dev.app` |
| **Public download** | Signed + notarized `.dmg` |
| **Updates** | Sparkle + hosted `appcast.xml` |
| **Lifetime license** | Gumroad / Lemon Squeezy / Paddle + `LicenseManager` |

---

## 1. Making the app downloadable

### Prerequisites

1. **Apple Developer Program** ($99/year)
2. **Developer ID Application** certificate (not “Apple Development”)
3. **Notarization credentials**:
   ```bash
   xcrun notarytool store-credentials "SelectAppNotary" \
     --apple-id "you@email.com" \
     --team-id "YOUR_TEAM_ID" \
     --password "app-specific-password"
   ```

### Configure release signing

Edit `scripts/release.sh`:

- `DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"`
- `NOTARY_PROFILE="SelectAppNotary"`

Set `DEVELOPMENT_TEAM` in a Release xcconfig or export before building.

### Build the DMG

```bash
./scripts/release.sh
# Output: .build/release/SelectApp.dmg
```

### Host the download

Options:

| Host | Pros |
|------|------|
| **Your website** | Full control, custom landing page |
| **GitHub Releases** | Free, easy versioning |
| **Gumroad / Lemon Squeezy** | Payment + download in one |

Upload the **stapled** DMG (notarization staple is applied by the script).

### User install flow

1. Download `.dmg`
2. Open → drag **Select** to Applications
3. First launch: right-click → Open (if Gatekeeper warns before notarization is trusted)
4. Grant Accessibility + Screen Recording once

---

## 2. Auto-updates (Sparkle)

The app includes `UpdaterController` as a stub. To enable real updates:

### Add Sparkle

1. Xcode → File → Add Package → `https://github.com/sparkle-project/Sparkle`
2. Replace `UpdaterController.swift` with `SPUStandardUpdaterController`
3. Add to `Info.plist`:
   - `SUFeedURL` → `https://yourdomain.com/appcast.xml`
   - `SUPublicEDKey` → Ed25519 public key from Sparkle

### Release an update

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`
2. Run `scripts/release.sh`
3. Generate appcast:
   ```bash
   ./Sparkle/bin/generate_appcast /path/to/updates/folder
   ```
4. Upload new `.dmg` + `appcast.xml` to your server
5. Existing users: **Check for Updates** or background Sparkle check

### Update policy for lifetime deal

- **Lifetime = all 1.x updates included** (recommended wording)
- Major 2.0 can be a paid upgrade or grandfathered — decide before launch
- Document in Terms on your store page

---

## 3. Lifetime licensing

Current code: `LicenseManager` scaffold in `SelectApp/Licensing/LicenseManager.swift`.

### Recommended store: Lemon Squeezy or Gumroad

Both support:

- One-time payment
- License keys
- Webhooks for activation

### Implementation steps

1. **Choose validation model**
   - **Online:** API call on activate (simple, needs network)
   - **Offline:** Ed25519-signed keys (works offline, more work)

2. **Wire `LicenseManager.activate(key:)`** to your store API

3. **Gate features** (if any free tier) or **gate launch**:
   ```swift
   guard LicenseManager.shared.isLicensed else { showActivation() }
   ```

4. **Settings → License** pane already exists — connect to real validation

5. **Lifetime deal copy** (store page):
   > Pay once. All updates within v1.x included. One license per Mac (or per user — your choice).

### Before going live

- [ ] Complete `docs/QA_TEST_PLAN.md`
- [ ] Test activate / deactivate / invalid key
- [ ] Test offline behavior (grace period or hard block — decide)
- [ ] Privacy policy if you collect email at purchase

---

## 4. Feedback → email → Linear (later)

### Now: email (implemented)

- Menu bar → **Send Feedback…**
- Opens Mail with pre-filled subject, message, app version, macOS version
- Set your address in `SelectApp/Support/FeedbackConfig.swift`:
  ```swift
  static let destinationEmail = "you@yourdomain.com"
  ```

### Later: Linear integration

Options:

1. **Linear email intake** — Linear team settings → create intake email → forward `FeedbackConfig.destinationEmail` there
2. **Linear API** — POST to `https://api.linear.app/graphql` with API key (requires network call from app or a small server)
3. **Zapier / Make** — Gumroad purchase → Linear issue; email → Linear

Recommended path: start with email → set up Linear email intake → optionally add API in v1.1.

---

## 5. Checklist before public launch

- [ ] QA test plan signed off
- [ ] `FeedbackConfig.destinationEmail` set
- [ ] Developer ID signed + notarized DMG tested on clean Mac
- [ ] Sparkle appcast live
- [ ] Store page + lifetime license keys working
- [ ] Privacy policy + support email published
- [ ] App icon + name “Select” in Applications folder
- [ ] Version 1.0.0 tagged in git

---

## Quick reference

```bash
# Dev
./scripts/dev-build.sh

# Regenerate Xcode project
./.tools/xcodegen/bin/xcodegen generate

# Unit tests
xcodebuild test -project SelectApp.xcodeproj -scheme SelectApp -destination 'platform=macOS'

# Release (after configuring release.sh)
./scripts/release.sh
```
