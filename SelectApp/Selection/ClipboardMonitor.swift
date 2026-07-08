import AppKit

/// Watches the general pasteboard for newly copied *images* and auto-appears the launcher.
///
/// Only reacts to browser **Copy Image** (image + http/https URL on the pasteboard), not
/// screenshots from tools like CleanShot — those write image-only data while the browser
/// stays frontmost, which would otherwise false-trigger the allowlist.
final class ClipboardMonitor {
    var onImageCopied: ((Capture) -> Void)?

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let pollInterval: TimeInterval = 0.4

    private var imageAutoAppearEnabled = true
    private var allowedBundleIDs: Set<String> = Set(AppSettings.defaultImageAutoAppearBundleIDs)

    /// Frontmost apps that commonly write screenshots to the clipboard — never auto-trigger.
    private static let screenshotAppBundleIDs: Set<String> = [
        "pl.maketheweb.cleanshotx",   // CleanShot X
        "com.getcleanshot.app",         // CleanShot (legacy)
        "com.apple.screencaptureui",    // macOS screenshot UI
        "com.apple.Screenshot",         // Screenshot app (macOS 14+)
        "net.nightowl.SnapNDrag",       // SnapNDrag
        "com.techsmith.snagit",         // Snagit
        "com.cocoatech.CleanShot",      // older CleanShot variants
    ]

    func configure(settings: AppSettings) {
        imageAutoAppearEnabled = settings.imageAutoAppearEnabled
        allowedBundleIDs = Set(settings.imageAutoAppearBundleIDs)
    }

    func start() {
        guard timer == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard imageAutoAppearEnabled else { return }

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let image = imageFromPasteboard(pasteboard) else { return }

        let frontmost = NSWorkspace.shared.frontmostApplication
        let bundleID = frontmost?.bundleIdentifier

        guard let bundleID, allowedBundleIDs.contains(bundleID) else { return }
        guard !Self.screenshotAppBundleIDs.contains(bundleID) else { return }

        // Browser "Copy Image" puts an http(s) URL on the pasteboard alongside the image.
        // Screenshot tools (CleanShot, etc.) write image-only data while the browser is still
        // frontmost — require the URL signature to tell them apart.
        guard hasBrowserCopyImageSignature(pasteboard) else { return }

        onImageCopied?(Capture(content: .image(image), sourceRect: nil, sourceBundleID: bundleID))
    }

    /// True when the pasteboard looks like a browser "Copy Image" (image + http(s) URL).
    private func hasBrowserCopyImageSignature(_ pasteboard: NSPasteboard) -> Bool {
        let candidates = [
            pasteboard.string(forType: .URL),
            pasteboard.string(forType: .string),
        ].compactMap { $0 }

        for candidate in candidates {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                return true
            }
        }
        return false
    }

    private func imageFromPasteboard(_ pasteboard: NSPasteboard) -> NSImage? {
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let first = images.first {
            return first
        }
        return nil
    }
}
