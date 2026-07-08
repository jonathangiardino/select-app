import AppKit
import SwiftUI

/// Clears default NSScrollView content insets as early as possible to avoid a first-frame layout jump.
final class ScrollInsetFixerView: NSView {
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        fixInsets()
    }

    override func layout() {
        super.layout()
        fixInsets()
    }

    private func fixInsets() {
        guard let scrollView = enclosingScrollView else { return }
        scrollView.scrollerStyle = .overlay
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.verticalScrollElasticity = .none
        scrollView.horizontalScrollElasticity = .none
    }
}

struct ScrollInsetFixer: NSViewRepresentable {
    func makeNSView(context: Context) -> ScrollInsetFixerView { ScrollInsetFixerView() }
    func updateNSView(_ nsView: ScrollInsetFixerView, context: Context) {
        nsView.needsLayout = true
    }
}
