import AppKit
import Combine
import Foundation

enum TriggerMode: String, CaseIterable, Codable, Identifiable {
    case auto        // mouse-selection + image-copy auto-appear
    case hotkey      // only via global hotkey
    case both        // auto + hotkey

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Automatic"
        case .hotkey: return "Hotkey only"
        case .both: return "Automatic + Hotkey"
        }
    }

    var autoAppearEnabled: Bool { self == .auto || self == .both }
    var hotkeyEnabled: Bool { self == .hotkey || self == .both }
}

enum FirstPresentation: String, CaseIterable, Codable, Identifiable {
    case peek        // small peek bar that expands
    case launcher    // full mini-launcher immediately

    var id: String { rawValue }

    var title: String {
        switch self {
        case .peek: return "Peek bar (expands on hover/key)"
        case .launcher: return "Full launcher"
        }
    }
}

enum LauncherPlacement: String, CaseIterable, Codable, Identifiable {
    case nearSelection
    case centered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nearSelection: return "Near selection"
        case .centered: return "Centered"
        }
    }
}

enum AIProviderKind: String, CaseIterable, Codable, Identifiable {
    case appleFoundation
    case openAI
    case anthropic
    case gemini
    case openAICompatible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleFoundation: return "Apple Intelligence (on-device)"
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic (Claude)"
        case .gemini: return "Google Gemini"
        case .openAICompatible: return "OpenAI-compatible"
        }
    }

    /// Whether this provider stores an API key in the Keychain.
    var usesAPIKey: Bool { self != .appleFoundation }
}

enum ScreenCorner: String, CaseIterable, Codable, Identifiable {
    case bottomRight
    case bottomLeft
    case topRight
    case topLeft

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bottomRight: return "Bottom-right"
        case .bottomLeft: return "Bottom-left"
        case .topRight: return "Top-right"
        case .topLeft: return "Top-left"
        }
    }
}

enum SaveTargetKind: String, CaseIterable, Codable, Identifiable {
    case appleNotes
    case markdownVault

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleNotes: return "Apple Notes"
        case .markdownVault: return "Markdown file / vault"
        }
    }
}

/// Central, observable, persisted user settings.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// Browser bundle IDs used as the default image auto-appear allowlist.
    static let defaultImageAutoAppearBundleIDs: [String] = [
        "com.apple.Safari",
        "com.google.Chrome",
        "company.thebrowser.Browser", // Arc
        "com.microsoft.edgemac",
        "org.mozilla.firefox",
        "com.brave.Browser",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",
    ]

    private let defaults: UserDefaults
    private enum Key {
        static let triggerMode = "triggerMode"
        static let firstPresentation = "firstPresentation"
        static let minSelectionLength = "minSelectionLength"
        static let mouseSelectionOnly = "mouseSelectionOnly"
        static let imageLauncherCorner = "imageLauncherCorner"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let onboardingComplete = "onboardingComplete"
        static let selectedProvider = "selectedProvider"
        static let openAIModel = "openAIModel"
        static let anthropicModel = "anthropicModel"
        static let geminiModel = "geminiModel"
        static let compatibleBaseURL = "compatibleBaseURL"
        static let compatibleModel = "compatibleModel"
        static let defaultSaveTarget = "defaultSaveTarget"
        static let markdownVaultBookmark = "markdownVaultBookmark"
        static let translationTargetLanguage = "translationTargetLanguage"
        static let enabledTranslationLanguages = "enabledTranslationLanguages"
        static let autoAppearDelay = "autoAppearDelay"
        static let launcherPlacement = "launcherPlacement"
        static let centeredOriginX = "centeredOriginX"
        static let centeredOriginY = "centeredOriginY"
        static let imageAutoAppearEnabled = "imageAutoAppearEnabled"
        static let imageAutoAppearBundleIDs = "imageAutoAppearBundleIDs"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Key.triggerMode: TriggerMode.both.rawValue,
            Key.firstPresentation: FirstPresentation.launcher.rawValue,
            Key.minSelectionLength: 2,
            Key.mouseSelectionOnly: true,
            Key.imageLauncherCorner: ScreenCorner.bottomRight.rawValue,
            Key.onboardingComplete: false,
            Key.selectedProvider: AIProviderKind.appleFoundation.rawValue,
            Key.openAIModel: "gpt-4o-mini",
            Key.anthropicModel: "claude-3-5-haiku-latest",
            Key.geminiModel: "gemini-1.5-flash",
            Key.compatibleBaseURL: "http://localhost:11434/v1",
            Key.compatibleModel: "llama3.1",
            Key.defaultSaveTarget: SaveTargetKind.appleNotes.rawValue,
            Key.translationTargetLanguage: "en",
            Key.enabledTranslationLanguages: ["en", "de", "fr", "es", "it"],
            Key.autoAppearDelay: 80,
            Key.launcherPlacement: LauncherPlacement.nearSelection.rawValue,
            Key.imageAutoAppearEnabled: true,
            Key.imageAutoAppearBundleIDs: Self.defaultImageAutoAppearBundleIDs,
        ])
    }

    // MARK: - Trigger

    var triggerMode: TriggerMode {
        get { TriggerMode(rawValue: defaults.string(forKey: Key.triggerMode) ?? "") ?? .both }
        set { defaults.set(newValue.rawValue, forKey: Key.triggerMode); objectWillChange.send() }
    }

    var firstPresentation: FirstPresentation {
        get { FirstPresentation(rawValue: defaults.string(forKey: Key.firstPresentation) ?? "") ?? .peek }
        set { defaults.set(newValue.rawValue, forKey: Key.firstPresentation); objectWillChange.send() }
    }

    var minSelectionLength: Int {
        get { defaults.integer(forKey: Key.minSelectionLength) }
        set { defaults.set(newValue, forKey: Key.minSelectionLength); objectWillChange.send() }
    }

    var mouseSelectionOnly: Bool {
        get { defaults.bool(forKey: Key.mouseSelectionOnly) }
        set { defaults.set(newValue, forKey: Key.mouseSelectionOnly); objectWillChange.send() }
    }

    var autoAppearDelay: Int {
        get { defaults.integer(forKey: Key.autoAppearDelay) }
        set { defaults.set(newValue, forKey: Key.autoAppearDelay); objectWillChange.send() }
    }

    var launcherPlacement: LauncherPlacement {
        get { LauncherPlacement(rawValue: defaults.string(forKey: Key.launcherPlacement) ?? "") ?? .nearSelection }
        set { defaults.set(newValue.rawValue, forKey: Key.launcherPlacement); objectWillChange.send() }
    }

    /// Persisted screen-space center for centered placement (nil until the user moves the panel).
    var centeredOrigin: NSPoint? {
        get {
            guard defaults.object(forKey: Key.centeredOriginX) != nil else { return nil }
            return NSPoint(
                x: defaults.double(forKey: Key.centeredOriginX),
                y: defaults.double(forKey: Key.centeredOriginY)
            )
        }
        set {
            if let newValue {
                defaults.set(newValue.x, forKey: Key.centeredOriginX)
                defaults.set(newValue.y, forKey: Key.centeredOriginY)
            } else {
                defaults.removeObject(forKey: Key.centeredOriginX)
                defaults.removeObject(forKey: Key.centeredOriginY)
            }
            objectWillChange.send()
        }
    }

    var imageAutoAppearEnabled: Bool {
        get { defaults.bool(forKey: Key.imageAutoAppearEnabled) }
        set { defaults.set(newValue, forKey: Key.imageAutoAppearEnabled); objectWillChange.send() }
    }

    var imageAutoAppearBundleIDs: [String] {
        get { defaults.stringArray(forKey: Key.imageAutoAppearBundleIDs) ?? Self.defaultImageAutoAppearBundleIDs }
        set { defaults.set(newValue, forKey: Key.imageAutoAppearBundleIDs); objectWillChange.send() }
    }

    var imageLauncherCorner: ScreenCorner {
        get { ScreenCorner(rawValue: defaults.string(forKey: Key.imageLauncherCorner) ?? "") ?? .bottomRight }
        set { defaults.set(newValue.rawValue, forKey: Key.imageLauncherCorner); objectWillChange.send() }
    }

    var excludedBundleIDs: [String] {
        get { defaults.stringArray(forKey: Key.excludedBundleIDs) ?? [] }
        set { defaults.set(newValue, forKey: Key.excludedBundleIDs); objectWillChange.send() }
    }

    var onboardingComplete: Bool {
        get { defaults.bool(forKey: Key.onboardingComplete) }
        set { defaults.set(newValue, forKey: Key.onboardingComplete); objectWillChange.send() }
    }

    // MARK: - AI

    var selectedProvider: AIProviderKind {
        get { AIProviderKind(rawValue: defaults.string(forKey: Key.selectedProvider) ?? "") ?? .appleFoundation }
        set { defaults.set(newValue.rawValue, forKey: Key.selectedProvider); objectWillChange.send() }
    }

    var openAIModel: String {
        get { defaults.string(forKey: Key.openAIModel) ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: Key.openAIModel); objectWillChange.send() }
    }

    var anthropicModel: String {
        get { defaults.string(forKey: Key.anthropicModel) ?? "claude-3-5-haiku-latest" }
        set { defaults.set(newValue, forKey: Key.anthropicModel); objectWillChange.send() }
    }

    var geminiModel: String {
        get { defaults.string(forKey: Key.geminiModel) ?? "gemini-1.5-flash" }
        set { defaults.set(newValue, forKey: Key.geminiModel); objectWillChange.send() }
    }

    var compatibleBaseURL: String {
        get { defaults.string(forKey: Key.compatibleBaseURL) ?? "" }
        set { defaults.set(newValue, forKey: Key.compatibleBaseURL); objectWillChange.send() }
    }

    var compatibleModel: String {
        get { defaults.string(forKey: Key.compatibleModel) ?? "" }
        set { defaults.set(newValue, forKey: Key.compatibleModel); objectWillChange.send() }
    }

    var translationTargetLanguage: String {
        get { enabledTranslationLanguages.first ?? defaults.string(forKey: Key.translationTargetLanguage) ?? "en" }
        set {
            defaults.set(newValue, forKey: Key.translationTargetLanguage)
            if !enabledTranslationLanguages.contains(newValue) {
                enabledTranslationLanguages.insert(newValue, at: 0)
            }
            objectWillChange.send()
        }
    }

    /// Language codes enabled for the Translate picker in the launcher.
    var enabledTranslationLanguages: [String] {
        get {
            defaults.stringArray(forKey: Key.enabledTranslationLanguages)
                ?? [defaults.string(forKey: Key.translationTargetLanguage) ?? "en"]
        }
        set {
            let unique = Array(NSOrderedSet(array: newValue)) as? [String] ?? newValue
            defaults.set(unique, forKey: Key.enabledTranslationLanguages)
            objectWillChange.send()
        }
    }

    func toggleTranslationLanguage(_ code: String) {
        var codes = enabledTranslationLanguages
        if let index = codes.firstIndex(of: code) {
            guard codes.count > 1 else { return }
            codes.remove(at: index)
        } else {
            codes.append(code)
        }
        enabledTranslationLanguages = codes
    }

    func isTranslationLanguageEnabled(_ code: String) -> Bool {
        enabledTranslationLanguages.contains(code)
    }

    // MARK: - Save targets

    var defaultSaveTarget: SaveTargetKind {
        get { SaveTargetKind(rawValue: defaults.string(forKey: Key.defaultSaveTarget) ?? "") ?? .appleNotes }
        set { defaults.set(newValue.rawValue, forKey: Key.defaultSaveTarget); objectWillChange.send() }
    }

    var markdownVaultBookmark: Data? {
        get { defaults.data(forKey: Key.markdownVaultBookmark) }
        set { defaults.set(newValue, forKey: Key.markdownVaultBookmark); objectWillChange.send() }
    }

    // MARK: - Exclusions helpers

    func isExcluded(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return excludedBundleIDs.contains(bundleID)
    }

    func toggleExclusion(bundleID: String) {
        var set = excludedBundleIDs
        if let idx = set.firstIndex(of: bundleID) {
            set.remove(at: idx)
        } else {
            set.append(bundleID)
        }
        excludedBundleIDs = set
    }

    func isImageAutoAppearAllowed(bundleID: String?) -> Bool {
        guard imageAutoAppearEnabled else { return false }
        guard let bundleID else { return false }
        return imageAutoAppearBundleIDs.contains(bundleID)
    }

    func toggleImageAutoAppearBundleID(_ bundleID: String) {
        var set = imageAutoAppearBundleIDs
        if let idx = set.firstIndex(of: bundleID) {
            set.remove(at: idx)
        } else {
            set.append(bundleID)
        }
        imageAutoAppearBundleIDs = set
    }
}
