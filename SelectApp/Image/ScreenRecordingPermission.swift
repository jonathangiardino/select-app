import AppKit
import CoreGraphics

/// Screen Recording permission (separate from Accessibility). Required for the screenshot hotkey.
enum ScreenRecordingPermission {
    static var isAuthorized: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Adds Select to the Screen Recording list and shows the system consent sheet.
    /// The grant may not take effect until the app is relaunched.
    @discardableResult
    static func requestAuthorization() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
