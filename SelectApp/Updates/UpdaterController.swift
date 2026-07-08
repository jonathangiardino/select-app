import AppKit

/// In-app auto-update controller.
///
/// This is a scaffold with a stub implementation so the app builds without external dependencies.
/// To enable real updates, add the Sparkle package (https://github.com/sparkle-project/Sparkle)
/// via Swift Package Manager, then replace the body of `checkForUpdates()` with an
/// `SPUStandardUpdaterController` and host a signed `appcast.xml`. See `scripts/release.sh`.
final class UpdaterController {
    func checkForUpdates() {
        let alert = NSAlert()
        alert.messageText = "Updates not configured yet"
        alert.informativeText = "Auto-updates will be powered by Sparkle. Add the Sparkle Swift package and point it at your appcast to enable this."
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    /// Called at launch once Sparkle is integrated to schedule background update checks.
    func startAutomaticChecksIfEnabled() {
        // No-op until Sparkle is wired in.
    }
}
