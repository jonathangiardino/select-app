import AppKit

/// A borderless, non-activating floating panel that can accept keyboard input (for the search
/// field) without deactivating the source app — so the selection stays intact for replace-in-place.
final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 200),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovableByWindowBackground = false
        // Deliberately not `.canJoinAllSpaces` — the panel should stay put (and the controller
        // dismisses it) rather than follow the user to another desktop/space.
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
        animationBehavior = .utilityWindow
    }
}
