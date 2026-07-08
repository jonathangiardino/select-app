# Website & Product Context

Handoff document for building a marketing site, download page, and checkout — use this in a **new chat** when you're ready to build the website.

---

## Product summary

**Select** is a macOS menu-bar utility (PopClip / Raycast-adjacent) that appears when you select text or copy an image.

### Core value

- Select text with the mouse → floating action launcher
- Copy an image in a browser → image launcher with OCR, copy, queue, paste-into-app
- Keyboard shortcuts for power users
- On-device OCR (Apple Vision), AI actions (Apple Intelligence when available)
- Clip queue: collect multiple snippets, paste all later
- Save to Apple Notes, Markdown vault, paste into any app
- Liquid Glass UI on macOS 26+; material fallback on macOS 14–15

### Target user

Mac power users, writers, researchers, developers who copy/paste and transform text constantly.

### Business model (planned)

- **Lifetime deal** — one-time purchase
- All **v1.x updates** included
- License key activation (Lemon Squeezy or Gumroad)
- Optional future v2 paid upgrade (decide before launch)

### Technical facts

| Item | Value |
|------|--------|
| Platform | macOS 14.0+ |
| Bundle ID | `com.selectapp.SelectApp` |
| Menu bar app | Yes (`LSUIElement`) |
| Permissions | Accessibility (text selection), Screen Recording (screenshots) |
| Sandbox | Off |
| Repo | `select-app` (this project) |
| Dev build | `./scripts/dev-build.sh` → `~/Applications/SelectApp-Dev.app` |
| Release | `./scripts/release.sh` → notarized DMG |

---

## Naming & domains

Working name: **Select**  
Bundle prefix: `com.selectapp`

If `select.app` / `getselect.com` / similar are taken, consider:

- **Select for Mac** (descriptive)
- **SelectText**, **QuickSelect**, **ClipSelect**, **Highlight** (check trademarks)
- Keep bundle ID stable even if display name changes (`CFBundleDisplayName` in Info.plist)

**Recommendation:** pick name + domain **before** website build. Update:

- `Info.plist` → `CFBundleDisplayName`
- Menu bar strings, onboarding, website hero
- Gumroad/Lemon Squeezy product name

---

## Website — recommended scope (v1)

Single-page or small multi-page site:

1. **Hero** — name, one-line tagline, screenshot/GIF of launcher
2. **Features** — 4–6 bullets with icons (text actions, image OCR, queue, AI, Notes, shortcuts)
3. **Download** — button → direct DMG link (after notarization)
4. **Pricing** — lifetime price, “pay once” copy, link to checkout
5. **FAQ** — permissions, macOS version, privacy (on-device OCR, AI optional)
6. **Support** — email + link to feedback
7. **Legal** — Privacy Policy, Terms (required for App Store–adjacent sales even outside MAS)

Optional pages: Changelog, Press kit

---

## Repo strategy: separate project or monorepo?

### Recommended: **separate repository** for the website

| Approach | Pros | Cons |
|----------|------|------|
| **Separate repo** (`select-website`) | Clean deploy (Vercel/Netlify), no macOS code in CI, different collaborators | Two repos to manage |
| **Monorepo** (`select-app/website/`) | Everything in one place | Heavier repo; website deploy tied to app repo |

**Best practice for indie Mac apps:**

```
select-app/          ← macOS app (this repo)
select-website/      ← Next.js or Astro landing + checkout links
```

The website does **not** need the Swift codebase. It only needs:

- Download URL (DMG hosted on GitHub Releases, R2, S3, or Vercel blob)
- Checkout URL (Lemon Squeezy / Gumroad — they host checkout)
- Copy, screenshots, privacy text

### Suggested website stack

- **Astro** or **Next.js** on **Vercel** — fast, simple static/SSR
- **No backend required** for v1 — checkout is external
- DMG hosting: GitHub Releases (free) or Cloudflare R2
- Analytics: Plausible or Fathom (privacy-friendly)

---

## Download & payment flow

```
Website “Download” → notarized SelectApp.dmg
Website “Buy”      → Lemon Squeezy checkout → license key emailed
First launch       → enter key in Settings → License (or activation window)
Updates            → Sparkle appcast.xml on same domain as website
```

### What the website agent needs from you

1. Final product name + domain
2. Hero screenshot / short screen recording
3. Price (e.g. $29 lifetime launch discount → $39)
4. Support email
5. DMG URL after first release build
6. Lemon Squeezy / Gumroad product URL
7. Privacy policy text (minimal: no analytics in app, AI optional, feedback via email)

---

## App features list (for marketing copy)

### Text launcher

- Auto-appear on mouse text selection (configurable)
- Hotkey trigger (default ⌥C)
- Actions: Delete selection, Copy, Add to queue, Paste into app, Save to Notes, Translate, AI summarize/fix grammar, etc.
- Search + keyboard navigation inside launcher
- Placement: near selection or centered (draggable)

### Image launcher

- Auto-appear on browser “Copy Image”
- Screenshot region hotkey
- OCR to text (on-device)
- Same queue / paste / copy actions

### Clip queue

- Collect multiple text/image clips
- Paste all with one action
- Menu bar badge count

### Settings

- Trigger modes, shortcuts, exclusions, translation languages, AI, license

---

## Files in this repo relevant to shipping

| Path | Purpose |
|------|---------|
| `docs/SHIPPING_CHECKLIST.md` | Step-by-step ship list |
| `docs/QA_TEST_PLAN.md` | Full manual QA |
| `docs/DISTRIBUTION_AND_UPDATES.md` | DMG, notarization, Sparkle, licensing detail |
| `scripts/release.sh` | Notarized DMG build |
| `scripts/dev-build.sh` | Daily dev install |
| `SelectApp/Licensing/LicenseManager.swift` | License activation (scaffold) |
| `SelectApp/Updates/UpdaterController.swift` | Sparkle (stub) |
| `SelectApp/Support/FeedbackService.swift` | Feedback email config |

---

## Suggested prompt for next website chat

Copy-paste into a new agent session:

> Build a marketing website for my macOS app **Select** using Astro or Next.js on Vercel.  
> Read `docs/WEBSITE_AND_PRODUCT_CONTEXT.md` from my app repo for product details.  
> Pages: landing (hero, features, FAQ), download (DMG link placeholder), pricing (lifetime deal → external checkout URL placeholder).  
> Design: dark, minimal, macOS-native feel, match liquid-glass aesthetic.  
> Use separate repo `select-website`. No backend — checkout via Lemon Squeezy link.

---

## Working together step-by-step (you + agent)

1. **Finish QA** — `docs/QA_TEST_PLAN.md`
2. **Name + domain** — decide, update app display name
3. **First notarized DMG** — `scripts/release.sh`
4. **Store product** — Lemon Squeezy, lifetime SKU + license keys
5. **Wire licensing** — app repo agent
6. **Website** — new repo agent using this doc
7. **Sparkle** — appcast + update menu item
8. **Soft launch** — friends / Twitter → fix feedback → public launch

Track progress in `docs/SHIPPING_CHECKLIST.md`.
