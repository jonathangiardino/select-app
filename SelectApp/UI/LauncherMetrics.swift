import CoreGraphics

/// Shared measurements so the launcher panel and its SwiftUI content stay in sync when resizing.
enum LauncherMetrics {
    static let width: CGFloat = 400
    static let maxHeight: CGFloat = 300
    /// Taller cap for sub-menus and result screens that include a back header (+ search + list).
    static let maxListScreenHeight: CGFloat = 480
    static let imageMaxHeight: CGFloat = 420
    /// Uniform inset between the glass edge and all launcher content.
    static let panelInset: CGFloat = 6
    /// Corner radius of the outer glass panel.
    static let panelCornerRadius: CGFloat = 20
    /// Inner corner radius nested inside the panel inset.
    static var innerCornerRadius: CGFloat { panelCornerRadius - panelInset }
    /// Corner radius for row highlights (middle rows).
    static let rowCornerRadius: CGFloat = 8
    static let rowHeight: CGFloat = 44
    static let rowSpacing: CGFloat = 2
    static let maxListRows = 5
    static let searchHeight: CGFloat = 44
    static let subheaderHeight: CGFloat = 54
    static let workingMinHeight: CGFloat = 120

    static func listAreaHeight(rowCount: Int, showsEmptyState: Bool) -> CGFloat {
        let rows = showsEmptyState ? 1 : max(rowCount, 1)
        let capped = min(rows, maxListRows)
        return CGFloat(capped) * rowHeight + max(0, CGFloat(capped - 1)) * rowSpacing
    }

    static func resultTextHeight(_ text: String) -> CGFloat {
        let lines = max(1, text.components(separatedBy: .newlines).count)
        let wrapped = max(lines, Int(ceil(Double(text.count) / 42)))
        return min(120, max(48, CGFloat(min(wrapped, 5)) * 18)) + 14
    }

    static func panelContentHeight(
        searchHeight: CGFloat = searchHeight,
        subheaderHeight: CGFloat = 0,
        imagePreviewHeight: CGFloat = 0,
        resultTextHeight: CGFloat = 0,
        listHeight: CGFloat
    ) -> CGFloat {
        panelInset * 2
            + subheaderHeight
            + imagePreviewHeight
            + resultTextHeight
            + searchHeight
            + listHeight
    }
}
