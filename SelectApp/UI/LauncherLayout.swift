import SwiftUI

/// Shared padding, alignment, and selection-corner rules for the launcher list.
enum LauncherLayout {
    /// Horizontal inset for search + rows (inside the panel inset).
    static let contentInset: CGFloat = 10
    /// Leading icon column width — shared by search, rows, and sub-screen headers.
    static let iconWidth: CGFloat = 20
    /// Space between the icon column and primary label text.
    static let iconSpacing: CGFloat = 10

    /// Corner radii for a selected row. Container-fitting bottom corners apply only when
    /// this row is the selected last item in the list.
    static func selectionCorners(
        index: Int,
        count: Int,
        selectedIndex: Int
    ) -> RectangleCornerRadii {
        let row = LauncherMetrics.rowCornerRadius
        let isLast = count > 0 && index == count - 1
        let isSelectedLast = isLast && index == selectedIndex

        if isSelectedLast {
            let inner = LauncherMetrics.innerCornerRadius
            return RectangleCornerRadii(
                topLeading: row,
                bottomLeading: inner,
                bottomTrailing: inner,
                topTrailing: row
            )
        }

        return RectangleCornerRadii(
            topLeading: row,
            bottomLeading: row,
            bottomTrailing: row,
            topTrailing: row
        )
    }

    /// Clips the list viewport so scrolled rows don't bleed past the panel's inner bottom curve.
    static var listViewportBottomClip: UnevenRoundedRectangle {
        let inner = LauncherMetrics.innerCornerRadius
        return UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: inner,
                bottomTrailing: inner,
                topTrailing: 0
            ),
            style: .continuous
        )
    }

    /// Top corners follow the panel inner curve; bottom corners match row highlights.
    static var imagePreviewCornerRadii: RectangleCornerRadii {
        RectangleCornerRadii(
            topLeading: LauncherMetrics.innerCornerRadius,
            bottomLeading: LauncherMetrics.rowCornerRadius,
            bottomTrailing: LauncherMetrics.rowCornerRadius,
            topTrailing: LauncherMetrics.innerCornerRadius
        )
    }
}

// MARK: - Sub-screen header

/// Back-navigation header for sub-menus and result screens — aligned with search + rows.
struct LauncherScreenHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: LauncherLayout.iconSpacing) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: LauncherLayout.iconWidth, height: LauncherLayout.iconWidth)
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.headline)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, LauncherLayout.contentInset)
        .frame(height: LauncherMetrics.subheaderHeight, alignment: .center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Image preview

/// Image preview shown above the search field on the image launcher — full content width,
/// aligned with list rows below.
struct LauncherImagePreview: View {
    let image: NSImage

    private var previewShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: LauncherLayout.imagePreviewCornerRadii,
            style: .continuous
        )
    }

    var body: some View {
        let size = LauncherMetrics.imagePreviewSize(for: image)
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipped()
            .clipShape(previewShape)
            .overlay(previewShape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: size.height)
    }
}

// MARK: - Result preview

struct LauncherResultPreview: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.horizontal, LauncherLayout.contentInset)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .frame(height: LauncherMetrics.resultTextHeight(text))
    }
}

// MARK: - Search field row

struct LauncherSearchField: View {
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: LauncherLayout.iconSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .frame(width: LauncherLayout.iconWidth)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .focused(focus)
        }
        .padding(.horizontal, LauncherLayout.contentInset)
        .frame(height: LauncherMetrics.searchHeight)
    }
}

extension View {
    /// Clips a list viewport to the panel's inner bottom curve without flattening row tops.
    func launcherListViewportClip() -> some View {
        clipShape(LauncherLayout.listViewportBottomClip)
    }
}
