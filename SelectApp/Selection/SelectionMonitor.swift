import AppKit

/// Detects deliberate mouse text selections and reports them as captures.
///
/// Rather than reacting to `kAXSelectedTextChangedNotification` (which fires on caret moves and
/// typing), we listen for `leftMouseUp` / multi-click and then read the AX selection. This maps
/// cleanly onto "the user just finished selecting something with the mouse".
final class SelectionMonitor {
    var onCapture: ((Capture) -> Void)?

    private var globalMonitor: Any?
    private var isRunning = false

    private var minLength: Int = 2
    private var cooldownText: String?
    private var cooldownUntil: Date = .distantPast

    private var settleDelay: TimeInterval = 0.08

    func configure(settings: AppSettings) {
        minLength = settings.minSelectionLength
        settleDelay = TimeInterval(settings.autoAppearDelay) / 1000
    }

    func startIfNeeded() {
        guard !isRunning else { return }
        isRunning = true
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp(event)
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        isRunning = false
    }

    private func handleMouseUp(_ event: NSEvent) {
        // Let the selection settle (some apps update AX slightly after mouse-up).
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) { [weak self] in
            guard let self else { return }
            guard let capture = self.currentSelectionCapture() else { return }
            guard let text = capture.content.text else { return }

            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= self.minLength else { return }

            // Cooldown: don't re-pop for the identical selection in quick succession.
            if self.cooldownText == trimmed, Date() < self.cooldownUntil { return }
            self.cooldownText = trimmed
            self.cooldownUntil = Date().addingTimeInterval(1.0)

            self.onCapture?(capture)
        }
    }

    /// Reads the current selection on demand (used by the hotkey path, incl. keyboard selections).
    func currentSelectionCapture() -> Capture? {
        guard let result = AXSelection.currentSelection() else { return nil }
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return Capture(content: .text(result.text), sourceRect: result.bounds, sourceBundleID: bundleID)
    }
}
