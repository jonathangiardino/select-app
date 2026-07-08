import AppKit
import SwiftUI

/// Small, non-activating HUD toast for terminal action confirmations.
@MainActor
final class HUDPresenter {
    static let shared = HUDPresenter()

    private final class HUDPanel: NSPanel {
        override var canBecomeKey: Bool { false }
        override var canBecomeMain: Bool { false }
    }

    private var panel: HUDPanel?
    private var dismissWorkItem: DispatchWorkItem?

    private init() {}

    func show(_ message: String, systemImage: String = "checkmark.circle.fill") {
        dismissWorkItem?.cancel()

        let content = HUDContentView(message: message, systemImage: systemImage)
        let hosting = NSHostingController(rootView: content)
        hosting.view.layoutSubtreeIfNeeded()
        let size = hosting.view.fittingSize

        let panel: HUDPanel
        if let existing = self.panel {
            panel = existing
            panel.contentViewController = hosting
            panel.setContentSize(size)
        } else {
            panel = HUDPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.ignoresMouseEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
            panel.contentViewController = hosting
            self.panel = panel
        }

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.minY + visible.height * 0.18
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = 1
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self, let panel = self.panel else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                panel.animator().alphaValue = 0
            }, completionHandler: {
                panel.orderOut(nil)
            })
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }
}

private struct HUDContentView: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.green)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .fixedSize()
        .glassPanel(cornerRadius: 14)
    }
}
