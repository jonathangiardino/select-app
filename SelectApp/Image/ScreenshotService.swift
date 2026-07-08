import AppKit

/// Captures a screen region via the system `screencapture` tool and returns an image.
/// Uses a temp file (not the clipboard) so the image launcher does not self-trigger.
enum ScreenshotService {
    enum ScreenshotError: LocalizedError {
        case cancelled
        case notAuthorized
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .cancelled: return "Screenshot cancelled."
            case .notAuthorized: return "Screen Recording permission is required for screenshots."
            case let .failed(message): return message
            }
        }
    }

    /// Runs interactive region capture. Returns nil when the user cancels.
    ///
    /// Does not call `CGRequestScreenCaptureAccess()` — that spams a system sheet on every
    /// hotkey press. Permission is handled via Settings / the coordinator alert instead.
    static func captureInteractiveRegion() async throws -> NSImage? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("select-screenshot-\(UUID().uuidString).png")

        defer { try? FileManager.default.removeItem(at: tempURL) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", tempURL.path]

        try process.run()
        process.waitUntilExit()

        switch process.terminationStatus {
        case 0:
            guard let image = NSImage(contentsOf: tempURL), image.isValid else {
                if !ScreenRecordingPermission.isAuthorized {
                    throw ScreenshotError.notAuthorized
                }
                throw ScreenshotError.failed("Could not read the captured image.")
            }
            return image
        case 1:
            return nil
        default:
            if !ScreenRecordingPermission.isAuthorized {
                throw ScreenshotError.notAuthorized
            }
            throw ScreenshotError.failed("Screenshot failed (exit code \(process.terminationStatus)).")
        }
    }
}

private extension NSImage {
    var isValid: Bool {
        !representations.isEmpty && size.width > 0 && size.height > 0
    }
}
