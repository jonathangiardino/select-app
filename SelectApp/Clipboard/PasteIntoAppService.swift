import AppKit

/// Enumerates running apps and pastes content into a chosen one by activating it and
/// synthesizing Cmd-V.
final class PasteIntoAppService {
    struct RunningApp: Identifiable {
        let id: pid_t
        let name: String
        let bundleID: String?
        let icon: NSImage?
        let app: NSRunningApplication
    }

    private let pasteboard = PasteboardService()
    private var pendingPaste: DispatchWorkItem?

    /// Regular (dock-visible) running apps, excluding ourselves, sorted by name.
    func runningApps() -> [RunningApp] {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != ownPID }
            .map {
                RunningApp(
                    id: $0.processIdentifier,
                    name: $0.localizedName ?? "App",
                    bundleID: $0.bundleIdentifier,
                    icon: $0.icon,
                    app: $0
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Puts plain text on the pasteboard, activates the target app, and pastes once after it is frontmost.
    func paste(text: String, into app: NSRunningApplication) {
        pendingPaste?.cancel()
        pasteboard.copyPlainText(text)
        schedulePaste(into: app)
    }

    func paste(image: NSImage, into app: NSRunningApplication) {
        pendingPaste?.cancel()
        pasteboard.copy(image: image)
        schedulePaste(into: app)
    }

    private func schedulePaste(into app: NSRunningApplication) {
        let targetPID = app.processIdentifier
        app.activate(options: [.activateIgnoringOtherApps])

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == targetPID else { return }
            self.pasteboard.paste()
            self.pendingPaste = nil
        }
        pendingPaste = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
}
