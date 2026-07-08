import Foundation

struct TranslationLanguage: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }

    static let catalog: [TranslationLanguage] = [
        .init(code: "en", name: "English"),
        .init(code: "de", name: "German"),
        .init(code: "fr", name: "French"),
        .init(code: "es", name: "Spanish"),
        .init(code: "it", name: "Italian"),
        .init(code: "pt", name: "Portuguese"),
        .init(code: "nl", name: "Dutch"),
        .init(code: "sv", name: "Swedish"),
        .init(code: "da", name: "Danish"),
        .init(code: "no", name: "Norwegian"),
        .init(code: "fi", name: "Finnish"),
        .init(code: "pl", name: "Polish"),
        .init(code: "cs", name: "Czech"),
        .init(code: "hu", name: "Hungarian"),
        .init(code: "ro", name: "Romanian"),
        .init(code: "ru", name: "Russian"),
        .init(code: "uk", name: "Ukrainian"),
        .init(code: "tr", name: "Turkish"),
        .init(code: "ar", name: "Arabic"),
        .init(code: "he", name: "Hebrew"),
        .init(code: "hi", name: "Hindi"),
        .init(code: "ja", name: "Japanese"),
        .init(code: "ko", name: "Korean"),
        .init(code: "zh", name: "Chinese (Simplified)"),
        .init(code: "zh-Hant", name: "Chinese (Traditional)"),
    ]

    static func named(_ code: String) -> String {
        catalog.first(where: { $0.code == code })?.name
            ?? Locale.current.localizedString(forLanguageCode: code)?.capitalized
            ?? code
    }

    static func from(code: String) -> TranslationLanguage? {
        catalog.first(where: { $0.code == code })
    }
}
