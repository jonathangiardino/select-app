import AppKit

/// Run on-device OCR (Apple Vision) on the captured image and switch to text actions.
struct OCRAction: LauncherAction {
    let id = "ocr"
    let title = "Extract Text (OCR)"
    var subtitle: String? { "On-device via Apple Vision" }
    let systemImage = "text.viewfinder"
    let shortcutKey: String? = "o"

    func perform(on model: LauncherViewModel) {
        guard let image = model.capture.content.image else { return }
        model.screen = .working("Extracting text…")
        model.recomputePanelHeight()
        Task { @MainActor in
            do {
                let text = try await model.imageService.recognizeText(in: image)
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    model.screen = .message("No text found in the image.")
                } else {
                    // Convert the capture to text and re-present the text actions.
                    model.replaceCapture(with: Capture(
                        content: .text(text),
                        sourceRect: model.capture.sourceRect,
                        sourceBundleID: model.capture.sourceBundleID,
                        hasTextSelection: false
                    ))
                }
            } catch {
                model.screen = .message("OCR failed: \(error.localizedDescription)")
            }
        }
    }
}
