import SwiftUI

/// The compact peek bar shown on auto-appear: a couple of top actions plus an expand affordance.
struct PeekBarView: View {
    @ObservedObject var model: LauncherViewModel

    private var topActions: [LauncherAction] {
        Array(model.actions.prefix(3))
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(topActions, id: \.id) { action in
                Button {
                    model.run(action)
                } label: {
                    Image(systemName: action.systemImage)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .help(action.title)
            }

            Divider().frame(height: 20)

            Button {
                model.expand()
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .help("More actions")
        }
        .padding(.horizontal, 10)
        .font(.system(size: 15, weight: .medium))
    }
}
