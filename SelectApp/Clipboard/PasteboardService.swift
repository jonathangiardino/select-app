import AppKit
import Carbon.HIToolbox

/// Thin wrapper over `NSPasteboard` plus a synthesized paste (Cmd-V) helper.
final class PasteboardService {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func copy(text: String) {
        copyPlainText(text)
    }

    /// Writes only plain UTF-8 text — avoids RTF/HTML duplicates when pasting into rich-text apps.
    func copyPlainText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }

    func copy(image: NSImage) {
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    func currentString() -> String? {
        pasteboard.string(forType: .string)
    }

    func currentImage() -> NSImage? {
        let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage]
        return images?.first
    }

    /// Synthesizes a Cmd-V keystroke to paste into the frontmost app.
    func paste() {
        postCommandV()
    }

    /// Copies plain text to the pasteboard, activates the source app, and pastes once.
    func paste(into bundleID: String?) {
        let performPaste = { [self] in
            postCommandV()
        }

        guard let bundleID,
              let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
        else {
            performPaste()
            return
        }

        app.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: performPaste)
    }

    private func postCommandV() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    /// Synthesizes a Delete (backspace) keystroke to remove the current selection in the
    /// frontmost app. Best-effort: only affects editable text fields.
    func deleteSelection(returningTo bundleID: String? = nil) {
        let performDelete = { [self] in
            postDeleteKey()
        }

        guard let bundleID,
              let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
        else {
            performDelete()
            return
        }

        app.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: performDelete)
    }

    private func postDeleteKey() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
