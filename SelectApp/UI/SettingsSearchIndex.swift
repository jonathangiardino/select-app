import Foundation

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case textTrigger
    case imageTrigger
    case ai
    case saving
    case shortcuts
    case license

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .textTrigger: return "Text Trigger"
        case .imageTrigger: return "Image Trigger"
        case .ai: return "AI"
        case .saving: return "Saving"
        case .shortcuts: return "Shortcuts"
        case .license: return "License"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .textTrigger: return "text.cursor"
        case .imageTrigger: return "photo"
        case .ai: return "sparkles"
        case .saving: return "tray.and.arrow.down"
        case .shortcuts: return "command"
        case .license: return "checkmark.seal"
        }
    }
}

struct SettingsSearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let section: SettingsSection
    let keywords: String

    var sectionTitle: String { section.title }
}

enum SettingsSearchIndex {
    static let items: [SettingsSearchResult] = [
        // General
        .init(id: "general.placement", title: "Placement", section: .general, keywords: "launcher centered near selection position"),
        .init(id: "general.autoAppear", title: "Auto-appear as", section: .general, keywords: "peek bar full launcher presentation"),
        .init(id: "general.delay", title: "Opening delay", section: .general, keywords: "auto appear delay milliseconds ms"),
        .init(id: "general.excluded", title: "Excluded Apps", section: .general, keywords: "ignore disable apps bundle"),
        .init(id: "general.accessibility", title: "Accessibility", section: .general, keywords: "permission grant access tcc"),
        .init(id: "general.resetCentered", title: "Reset Centered Position", section: .general, keywords: "centered launcher position reset"),

        // Text trigger
        .init(id: "text.mode", title: "Trigger mode", section: .textTrigger, keywords: "automatic hotkey both selection"),
        .init(id: "text.minLength", title: "Minimum selection length", section: .textTrigger, keywords: "characters minimum length"),
        .init(id: "text.mouseOnly", title: "Mouse selection only", section: .textTrigger, keywords: "keyboard mouse selection"),

        // Image trigger
        .init(id: "image.screenRecording", title: "Screen Recording", section: .imageTrigger, keywords: "screenshot permission capture"),
        .init(id: "image.autoAppear", title: "Auto-appear on image copy", section: .imageTrigger, keywords: "browser copy image clipboard"),
        .init(id: "image.corner", title: "Image launcher corner", section: .imageTrigger, keywords: "position corner placement"),
        .init(id: "image.allowedApps", title: "Allowed Apps", section: .imageTrigger, keywords: "browser allowlist arc safari chrome"),

        // AI
        .init(id: "ai.provider", title: "Provider", section: .ai, keywords: "openai anthropic gemini apple intelligence api"),
        .init(id: "ai.translation", title: "Translation languages", section: .ai, keywords: "translate language english german french spanish"),
        .init(id: "ai.openaiModel", title: "OpenAI model", section: .ai, keywords: "gpt model openai"),
        .init(id: "ai.anthropicModel", title: "Anthropic model", section: .ai, keywords: "claude model anthropic"),
        .init(id: "ai.geminiModel", title: "Gemini model", section: .ai, keywords: "google gemini model"),

        // Saving
        .init(id: "saving.target", title: "Default save target", section: .saving, keywords: "apple notes markdown default"),
        .init(id: "saving.vault", title: "Markdown Vault", section: .saving, keywords: "obsidian logseq file folder vault"),

        // Shortcuts
        .init(id: "shortcuts.text", title: "Text trigger", section: .shortcuts, keywords: "hotkey shortcut global text"),
        .init(id: "shortcuts.image", title: "Image trigger", section: .shortcuts, keywords: "hotkey shortcut global image"),
        .init(id: "shortcuts.screenshot", title: "Screenshot", section: .shortcuts, keywords: "hotkey shortcut capture screen"),
        .init(id: "shortcuts.launcher", title: "In-Launcher Shortcuts", section: .shortcuts, keywords: "command keyboard copy translate"),

        // License
        .init(id: "license.status", title: "License status", section: .license, keywords: "activate deactivate key licensed"),
    ]

    static func search(_ query: String) -> [SettingsSearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return items.filter {
            $0.title.lowercased().contains(q)
                || $0.keywords.lowercased().contains(q)
                || $0.sectionTitle.lowercased().contains(q)
        }
    }
}
