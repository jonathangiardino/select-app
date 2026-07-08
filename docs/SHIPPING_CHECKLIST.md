# Shipping Checklist

Short, ordered checklist before your first public release.  
Work top to bottom; don’t skip signing/notarization.

**Current app name:** Select (bundle ID: `com.selectapp.SelectApp`)  
**Target model:** Lifetime deal (one-time purchase, v1.x updates included)

---

## Phase 1 — Polish & QA (you are here)

- [ ] Run `./scripts/dev-build.sh` and smoke-test main flows
- [ ] Complete [`QA_TEST_PLAN.md`](QA_TEST_PLAN.md) — all sections Pass
- [ ] Set feedback email in `SelectApp/Support/FeedbackService.swift` → `FeedbackConfig.destinationEmail`
- [ ] Decide final **product name** + check domain availability (see [`WEBSITE_AND_PRODUCT_CONTEXT.md`](WEBSITE_AND_PRODUCT_CONTEXT.md))
- [ ] App icon + menu bar icon final
- [ ] Version set in `project.yml`: `MARKETING_VERSION` (e.g. `1.0.0`), bump `CURRENT_PROJECT_VERSION`

---

## Phase 2 — Licensing (lifetime deal)

- [ ] Pick store: **Lemon Squeezy** or **Gumroad** (recommended for solo indie)
- [ ] Create product: one-time price, license keys enabled
- [ ] Wire `LicenseManager.activate(key:)` to store API (replace scaffold in `SelectApp/Licensing/LicenseManager.swift`)
- [ ] Decide policy: license required at launch vs. grace period
- [ ] Test: valid key, invalid key, deactivate, offline
- [ ] Write store page copy: “Pay once — all 1.x updates included”

---

## Phase 3 — Release build

- [ ] Apple Developer Program active
- [ ] **Developer ID Application** certificate (not Apple Development)
- [ ] Edit `scripts/release.sh`:
  - [ ] `DEVELOPER_ID="Developer ID Application: …"`
  - [ ] `NOTARY_PROFILE="SelectAppNotary"` (`xcrun notarytool store-credentials`)
- [ ] Run `./scripts/release.sh` → produces `.build/release/SelectApp.dmg`
- [ ] Test DMG on a **clean Mac** (or second user account): install → grant permissions → core flows work
- [ ] No Gatekeeper “unidentified developer” warning (notarization + staple)

---

## Phase 4 — Updates

- [ ] Add **Sparkle** SPM dependency
- [ ] Replace stub in `SelectApp/Updates/UpdaterController.swift`
- [ ] Host `appcast.xml` + DMG on your domain or GitHub Releases
- [ ] Test “Check for Updates” from menu bar
- [ ] Document update policy on website

---

## Phase 5 — Website & download

- [ ] Landing page live (see [`WEBSITE_AND_PRODUCT_CONTEXT.md`](WEBSITE_AND_PRODUCT_CONTEXT.md))
- [ ] Download button → hosted notarized DMG
- [ ] Purchase button → Lemon Squeezy / Gumroad checkout
- [ ] Support email + privacy policy pages
- [ ] Optional: GitHub Releases as CDN mirror

---

## Phase 6 — Launch

- [ ] Tag git: `v1.0.0`
- [ ] Upload DMG + appcast
- [ ] Announce (Twitter, Product Hunt, etc.)
- [ ] Monitor feedback (`Send Feedback…` menu + support inbox)
- [ ] Linear/email intake for bugs (optional)

---

## Quick commands

```bash
# Dev build & run
./scripts/dev-build.sh

# Unit tests
xcodegen generate
xcodebuild test -project SelectApp.xcodeproj -scheme SelectApp -destination 'platform=macOS'

# Release (after configuring release.sh)
./scripts/release.sh
```

---

## Sign-off

| Gate | Done | Date |
|------|------|------|
| QA complete | ☐ | |
| Licensing wired | ☐ | |
| Notarized DMG tested | ☐ | |
| Sparkle live | ☐ | |
| Website + checkout live | ☐ | |
| **Ship it** | ☐ | |

---

## Suggested prompt for next shipping chat

Copy-paste into a new agent session when you're ready to ship:

> Help me ship **Select**, my macOS menu-bar app, through the full release pipeline.  
> Read these docs from my repo `select-app` first:  
> - `docs/SHIPPING_CHECKLIST.md` (master checklist — work phase by phase)  
> - `docs/QA_TEST_PLAN.md` (manual QA — run or track failures)  
> - `docs/DISTRIBUTION_AND_UPDATES.md` (notarization, Sparkle, licensing detail)  
>  
> Start at the first incomplete phase on the checklist. For each phase: tell me what you need from me, implement what you can in the repo, and give me exact commands to run.  
>  
> Context: lifetime deal (Lemon Squeezy or Gumroad), bundle ID `com.selectapp.SelectApp`, dev builds via `./scripts/dev-build.sh`, release via `./scripts/release.sh`. My Apple Development Team ID is already in `Config/Local.xcconfig`.  
>  
> Do not build the website in this chat — that's a separate repo (see `docs/WEBSITE_AND_PRODUCT_CONTEXT.md`).
