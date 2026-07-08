import Foundation

enum AIOutputCleaner {
    static func clean(_ text: String, for kind: AIActionKind) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return result }

        var lines = result.components(separatedBy: .newlines)
        while let first = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if first.isEmpty {
                lines.removeFirst()
                continue
            }
            if isPreambleLine(first) {
                lines.removeFirst()
                continue
            }
            break
        }
        result = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        if kind == .translate {
            result = stripLeadingLabelLine(result)
        }

        if kind == .translate, result.contains(" -> "), let colonRange = result.range(of: ": ", options: .backwards) {
            let tail = String(result[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !tail.isEmpty {
                result = tail
            }
        }

        return result
    }

    static func looksLikeRefusal(_ text: String) -> Bool {
        let lower = text.lowercased()
        let markers = [
            "i apologize",
            "i'm sorry",
            "please provide",
            "it seems there was an issue",
            "couldn't detect",
            "could not detect",
            "cannot detect",
            "unable to translate",
            "unable to detect",
            "issue with detecting",
            "however, i can",
        ]
        return markers.contains { lower.contains($0) }
    }

    static func validateTranslation(_ output: String, input: String) throws -> String {
        let cleaned = clean(output, for: .translate)
        guard !cleaned.isEmpty else { throw AIError.emptyResponse }
        if looksLikeRefusal(cleaned) { throw AIError.translationFailed }
        return cleaned
    }

    private static func stripLeadingLabelLine(_ text: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        while let first = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty {
            let plain = stripMarkdown(first)
            if plain.hasSuffix(":"), plain.count < 100, containsTranslationKeyword(plain) {
                lines.removeFirst()
                continue
            }
            break
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsTranslationKeyword(_ text: String) -> Bool {
        let lower = text.lowercased()
        let keywords = [
            "translation", "translate", "translated",
            "übersetzung", "übersetzungstext", "übersetzt",
            "traduction", "traduit",
            "traducción", "traducido",
            "traduzione", "tradotto",
            "here is", "here's", "hier ist", "voici", "ecco",
        ]
        return keywords.contains { lower.contains($0) }
    }

    private static func isPreambleLine(_ line: String) -> Bool {
        let plain = stripMarkdown(line)
        let lower = plain.lowercased()

        if plain.hasSuffix(":"), plain.count < 100, containsTranslationKeyword(plain) {
            return true
        }

        let preambles = [
            "sure!",
            "here is the translation",
            "here's the translation",
            "the translation is",
            "translation:",
            "hier ist der übersetzungstext",
            "hier ist die übersetzung",
            "hier ist der text",
            "voici la traduction",
            "voici le texte traduit",
            "ecco la traduzione",
            "aquí está la traducción",
        ]
        return preambles.contains { lower.hasPrefix($0) || lower == $0 }
    }
}
