import AppKit
import SwiftUI

// MARK: - Shared header

private struct SubScreenHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        LauncherScreenHeader(title: title, onBack: onBack)
        Divider()
            .padding(.horizontal, LauncherLayout.contentInset)
    }
}

// MARK: - Working / Message

struct WorkingView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: LauncherMetrics.workingMinHeight - LauncherMetrics.panelInset * 2)
    }
}

struct MessageView: View {
    @ObservedObject var model: LauncherViewModel
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            SubScreenHeader(title: "Select") { model.goToActions() }
            MessageBody(message: message)
            Spacer()
        }
    }
}

// MARK: - Shared row styling

struct LauncherRowView: View {
    let title: String
    var subtitle: String?
    var systemImage: String
    var iconImage: NSImage?
    var shortcut: String?
    var isSelected: Bool
    var showsShortcut: Bool = true
    var cornerRadii: RectangleCornerRadii = RectangleCornerRadii(
        topLeading: LauncherMetrics.rowCornerRadius,
        bottomLeading: LauncherMetrics.rowCornerRadius,
        bottomTrailing: LauncherMetrics.rowCornerRadius,
        topTrailing: LauncherMetrics.rowCornerRadius
    )

    var body: some View {
        ZStack {
            if isSelected {
                UnevenRoundedRectangle(cornerRadii: cornerRadii, style: .continuous)
                    .fill(Color.accentColor)
            }

            HStack(spacing: LauncherLayout.iconSpacing) {
                if let iconImage {
                    Image(nsImage: iconImage)
                        .resizable()
                        .frame(width: LauncherLayout.iconWidth, height: LauncherLayout.iconWidth)
                } else {
                    Image(systemName: systemImage)
                        .frame(width: LauncherLayout.iconWidth)
                        .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
                    }
                }
                Spacer(minLength: 0)
                if showsShortcut, let shortcut {
                    LauncherShortcutBadge(text: shortcut, isSelected: isSelected)
                }
            }
            .padding(.horizontal, LauncherLayout.contentInset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: LauncherMetrics.rowHeight)
    }
}

struct LauncherShortcutBadge: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.18) : Color.primary.opacity(0.06))
            )
    }
}

// MARK: - Small reusable pieces

private struct MessageBody: View {
    let message: String
    var body: some View {
        Text(message)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(16)
    }
}
