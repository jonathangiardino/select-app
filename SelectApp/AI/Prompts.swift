import Foundation

enum Prompts {
    static func system(for kind: AIActionKind, targetLanguage: String, detectSourceLanguage: Bool = false) -> String {
        switch kind {
        case .translate:
            let target = languageName(targetLanguage)
            if detectSourceLanguage {
                return translateInstructions(
                    target: target,
                    extra: "Auto-detect the source language of the input."
                )
            }
            return translateInstructions(target: target, extra: nil)
        case .summarize:
            return "You are a concise summarizer. Summarize the user's text into a few clear bullet points capturing the key ideas. Output only the summary."
        case .rewrite:
            return "You are an editor. Rewrite the user's text to be clearer and more natural while preserving meaning and tone. Output only the rewritten text."
        case .grammar:
            return "You are a proofreader. Correct spelling, grammar, and punctuation in the user's text. Preserve meaning, tone, and formatting. Output only the corrected text."
        }
    }

    static func user(for kind: AIActionKind, input: String) -> String {
        switch kind {
        case .translate:
            return input
        default:
            return input
        }
    }

    static func languageName(_ code: String) -> String {
        TranslationLanguage.named(code)
    }

    private static func translateInstructions(target: String, extra: String?) -> String {
        var lines = [
            "You are a translation engine, not a chat assistant.",
            "Translate the user's text into \(target).",
            "Output ONLY the translated text.",
            "Never apologize, explain, ask questions, or mention errors.",
            "Never refuse — always produce the best translation you can.",
            "Preserve line breaks and formatting.",
            "If the text is already in \(target), return it unchanged.",
        ]
        if let extra {
            lines.insert(extra, at: 1)
        }
        return lines.joined(separator: " ")
    }
}
