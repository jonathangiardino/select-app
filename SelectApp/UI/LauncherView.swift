import SwiftUI
import AppKit

/// The full launcher: an optional back header, a persistent focused search field, a keyboard-
/// navigable list (shared across the actions and every sub-screen), plus the working/result
/// /message screens.
struct LauncherView: View {
    @ObservedObject var model: LauncherViewModel
    @FocusState private var searchFocused: Bool
    @State private var windowStartIndex = 0

    private var maxVisibleRows: Int { LauncherMetrics.maxListRows }

    private var visibleRowCount: Int {
        model.isShowingEmptyResults ? 1 : model.visibleRows.count
    }

    var body: some View {
        VStack(spacing: 0) {
            if model.isListScreen {
                listScreen
            } else {
                switch model.screen {
                case let .working(message):
                    WorkingView(message: message)
                case let .message(message):
                    MessageView(model: model, message: message)
                default:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(LauncherMetrics.panelInset)
    }

    // MARK: - List screen (actions + sub-screens)

    private var listScreen: some View {
        VStack(spacing: 0) {
            if let title = model.screenTitle {
                LauncherScreenHeader(title: title) { model.goBack() }
            } else if case let .image(image) = model.capture.content {
                LauncherImagePreview(image: image)
            }

            if let resultText = model.resultBodyText {
                LauncherResultPreview(text: resultText)
            }

            LauncherSearchField(
                placeholder: model.searchPlaceholder,
                text: $model.query,
                focus: $searchFocused
            )
            .onChange(of: model.query) { _, _ in
                model.selectedIndex = 0
                windowStartIndex = 0
                model.refreshVisibleRows()
            }

            listViewport
                .layoutPriority(1)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                searchFocused = true
            }
        }
    }

    private var listViewport: some View {
        Group {
            if model.listNeedsScroll {
                scrollingList
            } else {
                fixedList
            }
        }
        .frame(height: model.listAreaHeight, alignment: .top)
        .frame(minHeight: model.listAreaHeight)
        .launcherListViewportClip()
    }

    private func rowCornerRadii(for index: Int) -> RectangleCornerRadii {
        LauncherLayout.selectionCorners(
            index: index,
            count: visibleRowCount,
            selectedIndex: model.selectedIndex
        )
    }

    private var rowStack: some View {
        VStack(spacing: LauncherMetrics.rowSpacing) {
            if model.isShowingEmptyResults {
                EmptyResultsView()
                    .id("empty-results")
            } else {
                ForEach(Array(model.visibleRows.enumerated()), id: \.element.id) { index, row in
                    LauncherRowView(
                        title: row.title,
                        subtitle: row.subtitle,
                        systemImage: row.systemImage,
                        iconImage: row.iconImage,
                        shortcut: row.shortcut,
                        isSelected: index == model.selectedIndex,
                        showsShortcut: model.screen == .actions,
                        cornerRadii: rowCornerRadii(for: index)
                    )
                    .id(row.id)
                    .contentShape(Rectangle())
                    .onTapGesture { row.perform() }
                    .onHover { hovering in
                        if hovering {
                            model.clearKeyboardNavigation()
                            windowStartIndex = 0
                            model.selectedIndex = index
                        }
                    }
                }
            }
            if let error = model.loadError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LauncherLayout.contentInset)
                    .padding(.vertical, 8)
            }
        }
    }

    private var fixedList: some View {
        rowStack
    }

    private var scrollingList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                rowStack
                    .background(ScrollInsetFixer())
            }
            .scrollIndicators(.hidden)
            .id(model.listRefreshID)
            .onAppear {
                scrollToSelectedItem(proxy: proxy, animated: false)
            }
            .onChange(of: model.selectedIndex) { oldValue, newValue in
                scrollToSelection(
                    oldValue: oldValue,
                    newValue: newValue,
                    proxy: proxy,
                    animated: model.isKeyboardNavigating
                )
            }
            .onChange(of: model.listRefreshID) { _, _ in
                windowStartIndex = 0
                scrollToSelectedItem(proxy: proxy, animated: false)
            }
        }
    }

    private func scrollToSelectedItem(proxy: ScrollViewProxy, animated: Bool) {
        let rows = model.visibleRows
        guard rows.indices.contains(model.selectedIndex) else { return }
        let id = rows[model.selectedIndex].id
        let anchor: UnitPoint = model.selectedIndex == rows.count - 1 ? .bottom : .top
        if animated {
            withAnimation(.easeOut(duration: 0.12)) {
                proxy.scrollTo(id, anchor: anchor)
            }
        } else {
            proxy.scrollTo(id, anchor: anchor)
        }
    }

    /// Scrolls only when keyboard navigation moves the selection past the visible window.
    private func scrollToSelection(oldValue: Int, newValue: Int, proxy: ScrollViewProxy, animated: Bool) {
        guard animated else { return }
        let rows = model.visibleRows
        guard rows.indices.contains(newValue) else { return }

        let id = rows[newValue].id
        let delta = model.lastSelectionDelta
        guard delta != 0 else { return }

        let scroll: () -> Void = {
            if delta > 0, newValue == 0, oldValue == rows.count - 1 {
                windowStartIndex = 0
                proxy.scrollTo(id, anchor: .top)
                return
            }
            if delta < 0, newValue == rows.count - 1, oldValue == 0 {
                windowStartIndex = max(0, rows.count - maxVisibleRows)
                proxy.scrollTo(id, anchor: .bottom)
                return
            }

            if delta > 0 {
                if newValue >= windowStartIndex + maxVisibleRows {
                    windowStartIndex = min(
                        max(0, newValue - maxVisibleRows + 1),
                        max(0, rows.count - maxVisibleRows)
                    )
                    proxy.scrollTo(id, anchor: .bottom)
                } else if newValue == rows.count - 1 {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            } else {
                if newValue < windowStartIndex {
                    windowStartIndex = newValue
                    proxy.scrollTo(id, anchor: .top)
                } else if newValue == 0 {
                    windowStartIndex = 0
                    proxy.scrollTo(id, anchor: .top)
                }
            }
        }

        withAnimation(.easeOut(duration: 0.12), scroll)
    }
}

// MARK: - Empty state

private struct EmptyResultsView: View {
    var body: some View {
        HStack(spacing: LauncherLayout.iconSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .frame(width: LauncherLayout.iconWidth)
            Text("No actions found")
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LauncherLayout.contentInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: LauncherMetrics.rowHeight)
    }
}
