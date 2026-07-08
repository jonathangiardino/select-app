import Foundation

enum AIActionKind: String, CaseIterable {
    case translate
    case summarize
    case rewrite
    case grammar

    var title: String {
        switch self {
        case .translate: return "Translate"
        case .summarize: return "Summarize"
        case .rewrite: return "Rewrite"
        case .grammar: return "Fix Grammar & Spelling"
        }
    }

    var systemImage: String {
        switch self {
        case .translate: return "globe"
        case .summarize: return "text.append"
        case .rewrite: return "arrow.triangle.2.circlepath"
        case .grammar: return "checkmark.circle"
        }
    }

    var shortcutKey: String {
        switch self {
        case .translate: return "t"
        case .summarize: return "u"
        case .rewrite: return "r"
        case .grammar: return "g"
        }
    }

    var resultTitle: String { title }
}

/// Runs an AI transformation on the captured text and shows the result screen.
struct AIAction: LauncherAction {
    let kind: AIActionKind

    var id: String { "ai.\(kind.rawValue)" }
    var title: String { kind.title }
    var systemImage: String { kind.systemImage }
    var shortcutKey: String? { kind.shortcutKey }

    func perform(on model: LauncherViewModel) {
        guard model.capture.content.text != nil else { return }
        if kind == .translate {
            model.showTranslationLanguagePicker()
            return
        }
        runDirect(model)
    }

    private func runDirect(_ model: LauncherViewModel) {
        guard let text = model.capture.content.text else { return }
        model.screen = .working("\(kind.title)…")
        model.recomputePanelHeight()
        Task { @MainActor in
            do {
                let raw = try await model.aiService.run(kind: kind, input: text)
                let output: String
                if kind == .translate {
                    output = try AIOutputCleaner.validateTranslation(raw, input: text)
                } else {
                    output = AIOutputCleaner.clean(raw, for: kind)
                }
                model.showResult(title: kind.resultTitle, text: output)
            } catch {
                model.screen = .message(aiErrorMessage(error))
                model.recomputePanelHeight()
            }
        }
    }

    private func aiErrorMessage(_ error: Error) -> String {
        if let aiError = error as? AIError {
            return aiError.userMessage
        }
        return "AI request failed: \(error.localizedDescription)"
    }
}
