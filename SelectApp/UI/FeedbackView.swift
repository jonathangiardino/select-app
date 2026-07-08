import SwiftUI

/// Menu-bar feedback form — borderless liquid-glass panel aligned with the launcher.
struct FeedbackView: View {
    @State private var kind: FeedbackKind = .feedback
    @State private var message = ""
    @State private var replyEmail = ""
    @State private var validationError: String?
    @FocusState private var messageFocused: Bool

    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            GlassSegmentedPicker(
                selection: $kind,
                items: FeedbackKind.allCases
            )
            .padding(.horizontal, LauncherLayout.contentInset)
            .padding(.top, 10)
            .padding(.bottom, 10)

            TextField("Your email (optional)", text: $replyEmail)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
                .padding(.horizontal, LauncherLayout.contentInset)

            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text(kind.prompt)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextField(kind.prompt, text: $message, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(5...8)
                    .focused($messageFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(minHeight: 120, maxHeight: 160, alignment: .topLeading)
            .background(fieldBackground)
            .padding(.horizontal, LauncherLayout.contentInset)
            .padding(.top, 8)

            if let validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LauncherLayout.contentInset)
                    .padding(.top, 6)
            }

            HStack {
                Button("Cancel") { close() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Send in Mail") { send() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, LauncherLayout.contentInset)
            .padding(.top, 14)
            .padding(.bottom, 6)
        }
        .padding(LauncherMetrics.panelInset)
        .frame(width: LauncherMetrics.width, alignment: .top)
        .fixedSize(horizontal: true, vertical: true)
        .glassPanel()
        .clipShape(
            RoundedRectangle(cornerRadius: LauncherMetrics.panelCornerRadius, style: .continuous)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                messageFocused = true
            }
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: LauncherMetrics.rowCornerRadius, style: .continuous)
            .fill(Color.primary.opacity(0.06))
    }

    private var header: some View {
        HStack(spacing: LauncherLayout.iconSpacing) {
            Image(systemName: "questionmark.circle")
                .frame(width: LauncherLayout.iconWidth)
                .foregroundStyle(.secondary)
            Text("Send Feedback")
                .font(.headline)
            Spacer(minLength: 0)
            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, LauncherLayout.contentInset)
        .frame(height: LauncherMetrics.subheaderHeight, alignment: .center)
        .background { WindowDragHandle() }
    }

    private func send() {
        validationError = nil
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Please write a message before sending."
            return
        }

        let opened = FeedbackService.send(kind: kind, message: trimmed, replyEmail: replyEmail)
        if opened {
            HUDPresenter.shared.show("Opening Mail…", systemImage: "envelope")
            close()
        } else {
            validationError = "Could not open Mail. Check that a mail client is configured."
        }
    }

    private func close() {
        onClose()
    }
}
