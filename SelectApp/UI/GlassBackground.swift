import SwiftUI

extension View {
    /// Applies Apple's Liquid Glass on macOS 26+, falling back to an `NSVisualEffectView`
    /// material on macOS 14–15. Use this for the launcher's panel surface.
    @ViewBuilder
    func glassPanel(cornerRadius: CGFloat = LauncherMetrics.panelCornerRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26.0, *) {
            self
                .clipShape(shape)
                .glassEffect(.regular, in: shape)
                .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
        } else {
            self
                .background(
                    VisualEffectBlur(material: .menu, blendingMode: .behindWindow)
                )
                .clipShape(shape)
                .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
        }
    }

    /// Capsule glass track for segmented controls (feedback type picker, etc.).
    @ViewBuilder
    func glassCapsuleTrack() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: Capsule())
        } else {
            self.background(Capsule().fill(.ultraThinMaterial))
        }
    }
}

/// macOS-style liquid-glass segmented control (no visible label).
struct GlassSegmentedPicker<Item: Hashable & Identifiable>: View where Item: GlassSegmentTitleProviding {
    @Binding var selection: Item
    let items: [Item]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items) { item in
                Button {
                    selection = item
                } label: {
                    Text(item.segmentTitle)
                        .font(.subheadline.weight(selection == item ? .semibold : .regular))
                        .foregroundStyle(selection == item ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .background {
                    if selection == item {
                        Capsule()
                            .fill(Color.primary.opacity(0.10))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                            )
                    }
                }
            }
        }
        .padding(3)
        .background {
            Capsule()
                .fill(Color.primary.opacity(0.05))
        }
        .glassCapsuleTrack()
        .clipShape(Capsule())
    }
}

protocol GlassSegmentTitleProviding {
    var segmentTitle: String { get }
}

/// Bridges `NSVisualEffectView` for the macOS 14–15 material fallback.
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
