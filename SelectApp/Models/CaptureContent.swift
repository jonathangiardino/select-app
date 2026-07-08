import AppKit

/// The content that the launcher operates on: either selected text or a copied image.
enum CaptureContent: Equatable {
    case text(String)
    case image(NSImage)

    var isText: Bool {
        if case .text = self { return true }
        return false
    }

    var isImage: Bool {
        if case .image = self { return true }
        return false
    }

    var text: String? {
        if case let .text(value) = self { return value }
        return nil
    }

    var image: NSImage? {
        if case let .image(value) = self { return value }
        return nil
    }

    static func == (lhs: CaptureContent, rhs: CaptureContent) -> Bool {
        switch (lhs, rhs) {
        case let (.text(a), .text(b)):
            return a == b
        case let (.image(a), .image(b)):
            return a === b
        default:
            return false
        }
    }
}

/// A capture plus the context needed to position the launcher and act on the source app.
struct Capture {
    let content: CaptureContent
    /// Screen-space rect of the selection (bottom-left origin, AppKit coords) used to place the panel.
    let sourceRect: CGRect?
    /// Bundle identifier of the frontmost app when the capture happened.
    let sourceBundleID: String?
    /// False for OCR-derived text where nothing is selected in the source app.
    let hasTextSelection: Bool

    init(
        content: CaptureContent,
        sourceRect: CGRect? = nil,
        sourceBundleID: String? = nil,
        hasTextSelection: Bool = true
    ) {
        self.content = content
        self.sourceRect = sourceRect
        self.sourceBundleID = sourceBundleID
        self.hasTextSelection = hasTextSelection
    }
}

/// How the launcher was triggered — affects the initial presentation (peek vs full launcher).
enum TriggerSource {
    case mouseSelection
    case imageCopy
    case hotkey
    case screenshot
}
