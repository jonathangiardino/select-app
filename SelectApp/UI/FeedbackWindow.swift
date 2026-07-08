import AppKit
import SwiftUI

/// Borderless window that accepts keyboard focus (required for text fields).
final class FeedbackWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(contentViewController: NSViewController) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: LauncherMetrics.width, height: 360),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.contentViewController = contentViewController
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        roundContentCorners()
    }

    private func roundContentCorners() {
        guard let contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = LauncherMetrics.panelCornerRadius
        contentView.layer?.cornerCurve = .continuous
        contentView.layer?.masksToBounds = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

/// Drag the window by its header without blocking clicks on text fields elsewhere.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragHandleView {
        WindowDragHandleView()
    }

    func updateNSView(_ nsView: WindowDragHandleView, context: Context) {}
}

final class WindowDragHandleView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
