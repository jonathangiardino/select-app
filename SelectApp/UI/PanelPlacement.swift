import AppKit

/// Computes where to place the launcher panel, clamped to the visible screen.
enum PanelPlacement {
    /// A frozen placement anchor computed once when the panel is presented.
    enum Anchor {
        /// Panel grows downward from a fixed top edge (near-selection mode).
        case topLeft(x: CGFloat, topY: CGFloat)
        /// Panel grows upward from a fixed bottom edge (image corner modes).
        case bottomLeft(x: CGFloat, bottomY: CGFloat)
        /// Panel stays centered on a fixed screen point (centered mode).
        case center(x: CGFloat, centerY: CGFloat)
    }

    /// Returns the bottom-left origin for a panel of `size`, positioned just below the selection
    /// rect (or at the mouse location if no rect is available), clamped on-screen.
    static func origin(for size: NSSize, near sourceRect: CGRect?, on screen: NSScreen? = nil) -> NSPoint {
        let anchor: NSPoint
        let targetScreen: NSScreen

        if let rect = sourceRect, rect != .zero {
            anchor = NSPoint(x: rect.minX, y: rect.minY)
            targetScreen = screen ?? self.screen(containing: NSPoint(x: rect.midX, y: rect.midY))
        } else {
            let mouse = NSEvent.mouseLocation
            anchor = mouse
            targetScreen = screen ?? self.screen(containing: mouse)
        }

        let gap: CGFloat = 8
        var origin = NSPoint(x: anchor.x, y: anchor.y - size.height - gap)

        let visible = targetScreen.visibleFrame
        if origin.x + size.width > visible.maxX { origin.x = visible.maxX - size.width }
        if origin.x < visible.minX { origin.x = visible.minX }
        if origin.y < visible.minY {
            origin.y = anchor.y + gap
        }
        if origin.y + size.height > visible.maxY { origin.y = visible.maxY - size.height }
        if origin.y < visible.minY { origin.y = visible.minY }

        return origin
    }

    /// Returns the bottom-left origin for a panel of `size` pinned to a fixed corner, clamped on-screen.
    static func cornerOrigin(
        for size: NSSize,
        corner: ScreenCorner,
        on screen: NSScreen,
        margin: CGFloat = 24
    ) -> NSPoint {
        let visible = screen.visibleFrame

        let x: CGFloat
        switch corner {
        case .bottomLeft, .topLeft:
            x = visible.minX + margin
        case .bottomRight, .topRight:
            x = visible.maxX - size.width - margin
        }

        let y: CGFloat
        switch corner {
        case .bottomLeft, .bottomRight:
            y = visible.minY + margin
        case .topLeft, .topRight:
            y = visible.maxY - size.height - margin
        }

        return NSPoint(x: x, y: y)
    }

    /// Returns the screen-space center point for centered placement.
    static func centeredCenter(on screen: NSScreen, savedCenter: NSPoint?) -> NSPoint {
        if let savedCenter {
            return savedCenter
        }
        let visible = screen.visibleFrame
        return NSPoint(x: visible.midX, y: visible.midY)
    }

    /// Returns the bottom-left origin for centered placement, keeping the panel center fixed.
    static func centeredOrigin(for size: NSSize, on screen: NSScreen, savedCenter: NSPoint?) -> NSPoint {
        let center = centeredCenter(on: screen, savedCenter: savedCenter)
        var origin = NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        return clamp(origin, size: size, on: screen)
    }

    /// Converts a screen-space center into a center-anchored placement.
    static func centerAnchor(from center: NSPoint) -> Anchor {
        .center(x: center.x, centerY: center.y)
    }

    /// Converts a bottom-left origin into a top-anchored placement anchor.
    static func topAnchor(from origin: NSPoint, size: NSSize) -> Anchor {
        .topLeft(x: origin.x, topY: origin.y + size.height)
    }

    /// Converts a bottom-left origin into a bottom-anchored placement anchor.
    static func bottomAnchor(from origin: NSPoint) -> Anchor {
        .bottomLeft(x: origin.x, bottomY: origin.y)
    }

    /// Derives a bottom-left panel origin from a frozen anchor and the current size.
    static func origin(from anchor: Anchor, size: NSSize, on screen: NSScreen? = nil) -> NSPoint {
        switch anchor {
        case let .topLeft(x, topY):
            return NSPoint(x: x, y: topY - size.height)
        case let .bottomLeft(x, bottomY):
            return NSPoint(x: x, y: bottomY)
        case let .center(x, centerY):
            return NSPoint(x: x - size.width / 2, y: centerY - size.height / 2)
        }
    }

    /// Clamps an origin while keeping the panel center fixed as much as possible.
    static func clampPreservingCenter(_ center: NSPoint, size: NSSize, on screen: NSScreen) -> NSPoint {
        let origin = NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        return clamp(origin, size: size, on: screen)
    }

    static func screen(containing point: NSPoint) -> NSScreen {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private static func clamp(_ origin: NSPoint, size: NSSize, on screen: NSScreen) -> NSPoint {
        let visible = screen.visibleFrame
        var clamped = origin
        if clamped.x + size.width > visible.maxX { clamped.x = visible.maxX - size.width }
        if clamped.x < visible.minX { clamped.x = visible.minX }
        if clamped.y + size.height > visible.maxY { clamped.y = visible.maxY - size.height }
        if clamped.y < visible.minY { clamped.y = visible.minY }
        return clamped
    }
}
