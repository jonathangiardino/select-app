import AppKit

/// An item held in the ephemeral multi-clip queue (in memory only).
enum ClipItem {
    case text(String)
    case image(NSImage)
}

/// Ordered, in-memory queue of clips (text paragraphs and images). Cleared on paste-all or quit.
final class ClipQueue {
    private(set) var items: [ClipItem] = [] {
        didSet { onChange?(items.count) }
    }

    /// Called whenever the queue count changes (used for the menu-bar badge).
    var onChange: ((Int) -> Void)?

    private let pasteboard: PasteboardService

    init(pasteboard: PasteboardService = PasteboardService()) {
        self.pasteboard = pasteboard
    }

    var count: Int { items.count }
    var isEmpty: Bool { items.isEmpty }

    func addText(_ text: String) {
        items.append(.text(text))
        syncClipboard()
    }

    func addImage(_ image: NSImage) {
        items.append(.image(image))
        syncClipboard()
    }

    func clear() {
        items.removeAll()
    }

    /// Keeps the system clipboard mirroring the combined queue text, so a plain ⌘V in any app
    /// pastes everything collected so far (matching users' expectations after "Add to Queue").
    /// Only text is mirrored — re-writing an image would bump the pasteboard change count and
    /// re-trigger the image auto-popup.
    private func syncClipboard() {
        if let combined = combinedText() {
            pasteboard.copy(text: combined)
        }
    }

    /// The combined queued text currently mirrored onto the clipboard, if any.
    func combinedText() -> String? {
        let texts = items.compactMap { item -> String? in
            if case let .text(value) = item { return value }
            return nil
        }
        guard !texts.isEmpty else { return nil }
        return texts.joined(separator: "\n\n")
    }

    /// If the system clipboard still holds the queued text (i.e. the user just pasted the queue
    /// elsewhere with ⌘V), clear the queue so the badge/count reset. Returns true if cleared.
    @discardableResult
    func clearIfClipboardMatchesQueue() -> Bool {
        guard let combined = combinedText() else { return false }
        guard pasteboard.currentString() == combined else { return false }
        clear()
        return true
    }

    /// Concatenates queued text (separated by blank lines) onto the pasteboard and pastes it,
    /// then clears the queue. Images are ignored for the combined text paste.
    func pasteAll() {
        guard let combined = combinedText() else { return }
        pasteboard.copy(text: combined)
        clear()
        pasteboard.paste()
    }
}
