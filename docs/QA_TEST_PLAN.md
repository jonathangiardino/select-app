# Select — QA Test Plan

Complete this checklist before enabling lifetime licensing and public downloads.
Mark each item **Pass / Fail / N/A** and note build + macOS version.

**Build under test:** _______________  
**macOS version:** _______________  
**Tester:** _______________  
**Date:** _______________

---

## 1. Permissions & first launch

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 1.1 | Fresh install permissions | Install from `~/Applications/SelectApp-Dev.app`, grant Accessibility + Screen Recording once | App reads selections; screenshots work after relaunch |
| 1.2 | Rebuild persistence | `./scripts/dev-build.sh` twice without `tccutil reset` | Permissions survive; no onboarding re-run in Release |
| 1.3 | Accessibility revoked | Disable in System Settings → relaunch | App prompts or fails gracefully; Settings shows “Grant Access” |
| 1.4 | Screen Recording revoked | Disable → screenshot hotkey | Alert with link to Screen Recording settings |
| 1.5 | Onboarding (Release) | Delete `onboardingComplete` default, launch Release build | Wizard shows; Finish persists |

---

## 2. Text launcher — trigger & placement

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 2.1 | Mouse selection auto-appear | Select text with mouse in Notes, Safari, Terminal, Xcode | Launcher appears after release; not on caret-only clicks |
| 2.2 | Min selection length | Select 1 character with min length = 2 | No launcher |
| 2.3 | Hotkey text trigger | Keyboard-select text → ⌥C (default) | Launcher with selection |
| 2.4 | Near-selection placement | Placement = near selection | Panel below/above selection, on-screen |
| 2.5 | Centered placement | Placement = centered; drag panel | Stays movable; position saved |
| 2.6 | Excluded app | Add frontmost app to exclusions | No launcher for that app |
| 2.7 | Secure field | Select in password field | No capture |
| 2.8 | Cooldown | Re-select same text quickly | No duplicate pop within ~1s |

---

## 3. Text launcher — UI & keyboard

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 3.1 | Search filter | Type in search; clear search | Filters actions; empty state “No actions found” |
| 3.2 | Filter resize anchor | Filter to 1 item; filter back to many | Top edge fixed; no vertical drift |
| 3.3 | Arrow keys | ↑↓ through list | Selection moves; scroll when >5 items |
| 3.4 | Enter | Press Return on selected action | Action runs |
| 3.5 | Escape | Esc on root / submenu | Back or dismiss |
| 3.6 | Shortcuts ⌘C/S/P/N | Press with action selected | Runs matching action |
| 3.7 | Corner radii — first/middle | Select first and middle rows | Uniform 8pt rounding |
| 3.8 | Corner radii — last | Select last row | Bottom matches panel curve |
| 3.9 | Padding alignment | Compare search icon, row icons, shortcuts | Horizontally aligned |
| 3.10 | Click outside | Click outside panel | Dismisses |
| 3.11 | Space change | Switch Spaces while open | Dismisses |

---

## 4. Image launcher

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 4.1 | Browser copy image | Copy Image in Safari/Arc | Auto-appears at configured corner |
| 4.2 | Screenshot hotkey | Region screenshot hotkey | Image launcher with preview |
| 4.3 | Image hotkey | Copy image → image hotkey | Opens launcher |
| 4.4 | Preview alignment | Compare to text launcher | Full content width; same list padding/corners |
| 4.5 | OCR | Run Extract Text (OCR) | Switches to text actions or “No text found” |
| 4.6 | Copy hidden when redundant | Image already on clipboard (browser copy) | No “Copy to Clipboard” action |
| 4.7 | Copy shown for screenshot | Screenshot capture | Copy action present |
| 4.8 | Corner placement | Each screen corner setting | Panel pinned correctly |

---

## 5. Actions

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 5.1 | Delete selection | Delete Selection on text | Text removed in source app |
| 5.2 | Copy | Copy to Clipboard | Paste elsewhere works |
| 5.3 | Add to queue | Add multiple clips | Menu bar badge updates |
| 5.4 | Paste all clips | ⌘V after Paste All / queue paste monitor | All clips pasted; queue clears |
| 5.5 | Clear queue | Menu → Clear Queue | Badge gone |
| 5.6 | Paste into app | Pick app from list | Switches app + pastes |
| 5.7 | Save to Notes — folder | Pick folder → new note | Note created |
| 5.8 | Save to Notes — append | Pick existing note | Text appended |
| 5.9 | Markdown vault | Save to vault path | File written |
| 5.10 | Translate — detect | Detect language | Result screen; preamble stripped |
| 5.11 | Translate — target | Pick German/French/etc. | Correct target language |
| 5.12 | Translate — refusal | Prompt that triggers refusal | Error message, not garbage output |
| 5.13 | AI summarize / fix grammar | Run on sample text | Result screen with body + actions |
| 5.14 | Replace in source | Replace on result screen | Source text replaced |
| 5.15 | Result copy / queue | From result screen | Works |

---

## 6. Submenus & result screens

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 6.1 | Paste into submenu | Open; search apps; scroll | Header not squished; list aligned |
| 6.2 | Translate language picker | Scroll to last language | Bottom corners match when selected |
| 6.3 | Notes folder picker | Single folder | No layout compression |
| 6.4 | Notes list | Many notes; scroll | No overflow past panel bottom |
| 6.5 | Result screen padding | Translate result | Text + search + actions evenly padded |
| 6.6 | Back navigation | Back from each submenu | Returns to parent; search clears |

---

## 7. Settings

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 7.1 | Sidebar selection | Click each section | Correct pane shows |
| 7.2 | Deep search | Search “Accessibility”, “OCR”, etc. | Finds settings; ↑↓ navigates |
| 7.3 | Trigger mode changes | Auto / hotkey / both | Monitors enable/disable live |
| 7.4 | Shortcut recording | Change text/image/screenshot shortcuts | New shortcuts work |
| 7.5 | Reset centered position | Reset button | Centered launcher resets |
| 7.6 | License UI | Enter invalid / valid key (scaffold) | Appropriate message |

---

## 8. Menu bar & feedback

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 8.1 | Queue badge | Add to queue | Count in menu bar |
| 8.2 | Send Feedback | Menu → Send Feedback | Glass form opens |
| 8.3 | Feedback send | Fill message → Send in Mail | Mail opens with subject, body, version info |
| 8.4 | Check for Updates | Menu item | Sparkle stub alert (until integrated) |
| 8.5 | Quit | Quit Select | Clean exit; monitors removed |

---

## 9. Edge cases & stress

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 9.1 | Very long selection | 10k+ characters | Launcher usable; scroll result if needed |
| 9.2 | Empty selection / OCR on blank image | — | Graceful message |
| 9.3 | Multi-monitor | Selection on non-primary display | Correct screen placement |
| 9.4 | Rapid open/close | Trigger repeatedly | No crash; no ghost windows |
| 9.5 | Peek vs launcher mode | First presentation = peek | Expands on interaction |
| 9.6 | Low memory / sleep wake | Sleep Mac, wake, use Select | Still works |
| 9.7 | Non-English UI | macOS language ≠ English | Layout intact |

---

## 10. Release build (pre-download)

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 10.1 | Release archive | `scripts/release.sh` (after configuring signing) | Signed + notarized DMG |
| 10.2 | Gatekeeper | Open DMG on clean Mac | Opens without “unidentified developer” |
| 10.3 | Permissions fresh install | Install from DMG | One-time permission grant |
| 10.4 | Auto-update check | Sparkle integrated | Finds update when appcast published |
| 10.5 | License gate | Before lifetime deal goes live | Unlicensed state handled per your policy |

---

## Automated tests (Xcode)

Run unit tests:

```bash
xcodegen generate
xcodebuild test -project SelectApp.xcodeproj -scheme SelectApp -destination 'platform=macOS'
```

Current coverage: `LauncherLayoutTests` (corner radii + content width). Expand with ViewModel filter/height tests as needed.

---

## Sign-off

| Area | Pass | Notes |
|------|------|-------|
| Permissions | | |
| Text launcher | | |
| Image launcher | | |
| Actions & AI | | |
| Settings | | |
| Release build | | |

**Ready for licensing + public download:** ☐ Yes ☐ No
