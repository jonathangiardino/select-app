import ApplicationServices
import AppKit

enum AccessibilityPermission {
    /// Whether the process is currently trusted for the Accessibility API.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Silent check — does not show the system prompt.
    static func checkTrusted(showPrompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: showPrompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Prompts the user to grant Accessibility access if not already trusted.
    @discardableResult
    static func promptIfNeeded() -> Bool {
        checkTrusted(showPrompt: true)
    }

    /// Opens the Accessibility pane in System Settings.
    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    #if DEBUG
    private static let devGuidanceShownKey = "devAccessibilityGuidanceShown"

    /// Dev builds: explain stale TCC entries instead of spamming the system sheet on every launch.
    @MainActor
    static func handleDevLaunch(onTrusted: @escaping () -> Void) {
        if isTrusted {
            UserDefaults.standard.removeObject(forKey: devGuidanceShownKey)
            onTrusted()
            return
        }

        let bundlePath = Bundle.main.bundlePath
        let installPath = ("~/Applications/SelectApp-Dev.app" as NSString).expandingTildeInPath

        if bundlePath != installPath {
            showDevAlert(
                title: "Run the Dev Install",
                message: """
                This build is running from DerivedData, not the fixed dev install path.

                Quit Select, then run:
                  ./scripts/dev-build.sh

                That installs to ~/Applications/SelectApp-Dev.app and launches from there.
                Grant Accessibility for that app only.
                """,
                openSettings: false
            )
            return
        }

        if !UserDefaults.standard.bool(forKey: devGuidanceShownKey) {
            showDevAlert(
                title: "Accessibility Required",
                message: """
                Select needs Accessibility to read your text selection.

                If the toggle is already on but selection still doesn't work, you likely have a stale entry from an old build:

                1. Open System Settings → Privacy & Security → Accessibility
                2. Remove every "Select" / "SelectApp" entry
                3. Click + and add:
                   ~/Applications/SelectApp-Dev.app
                4. Enable the toggle
                5. Quit Select (menu bar → Quit) and run ./scripts/dev-build.sh again

                Running from: \(bundlePath)
                """,
                openSettings: true
            )
            UserDefaults.standard.set(true, forKey: devGuidanceShownKey)
        }

        startDevTrustPolling(onTrusted: onTrusted)
    }

    @MainActor
    private static func showDevAlert(title: String, message: String, openSettings: Bool) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        if openSettings {
            alert.addButton(withTitle: "Open Accessibility Settings")
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                openSystemSettings()
            }
        } else {
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    @MainActor
    private static func startDevTrustPolling(onTrusted: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                guard isTrusted else { return }
                timer.invalidate()
                UserDefaults.standard.removeObject(forKey: devGuidanceShownKey)
                onTrusted()
            }
        }
    }
    #endif
}
