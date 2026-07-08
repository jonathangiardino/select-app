import SwiftUI

/// Root of the panel content: shows the compact peek bar or the full launcher.
struct LauncherRootView: View {
    @ObservedObject var model: LauncherViewModel
    @State private var appeared = false

    var body: some View {
        Group {
            if model.expanded {
                LauncherView(model: model)
            } else {
                PeekBarView(model: model)
            }
        }
        .frame(width: model.expanded ? LauncherMetrics.width : 300)
        .frame(height: model.expanded ? model.panelContentHeight : nil)
        .fixedSize(horizontal: true, vertical: !model.expanded)
        .glassPanel()
        .clipShape(RoundedRectangle(cornerRadius: LauncherMetrics.panelCornerRadius, style: .continuous))
        .scaleEffect(appeared ? 1 : 0.96, anchor: .top)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            appeared = false
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}
