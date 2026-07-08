import AppKit
import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @State private var selection: SettingsSection = .general
    @State private var searchQuery = ""
    @State private var highlightedSearchResultID: String?
    @State private var searchSelectedIndex = 0
    @FocusState private var searchFieldFocused: Bool

    private var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var searchResults: [SettingsSearchResult] {
        SettingsSearchIndex.search(searchQuery)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(width: 1)

            detail
        }
        .background {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
        }
        .background {
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .toolbarBackground(Color(nsColor: .windowBackgroundColor), for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .frame(minWidth: 720, minHeight: 520)
        .onChange(of: searchQuery) { _, _ in
            syncSearchSelection(resetIndex: true)
        }
        .onKeyPress(.upArrow) {
            if isSearching, !searchResults.isEmpty {
                moveSearchSelection(by: -1)
                return .handled
            }
            if !isSearching {
                moveSectionSelection(by: -1)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            if isSearching, !searchResults.isEmpty {
                moveSearchSelection(by: 1)
                return .handled
            }
            if !isSearching {
                moveSectionSelection(by: 1)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            if isSearching, let id = highlightedSearchResultID,
               let result = searchResults.first(where: { $0.id == id }) {
                applySearchResult(result)
                return .handled
            }
            return .ignored
        }
    }

    private func moveSectionSelection(by delta: Int) {
        let sections = SettingsSection.allCases
        guard let index = sections.firstIndex(of: selection) else { return }
        let next = (index + delta + sections.count) % sections.count
        selection = sections[next]
        highlightedSearchResultID = nil
    }

    private func syncSearchSelection(resetIndex: Bool) {
        guard isSearching else {
            highlightedSearchResultID = nil
            return
        }
        if resetIndex {
            searchSelectedIndex = 0
        } else if searchSelectedIndex >= searchResults.count {
            searchSelectedIndex = max(0, searchResults.count - 1)
        }
        if let result = searchResults[safe: searchSelectedIndex] {
            highlightedSearchResultID = result.id
            selection = result.section
        } else {
            highlightedSearchResultID = nil
        }
    }

    private func moveSearchSelection(by delta: Int) {
        guard !searchResults.isEmpty else { return }
        searchSelectedIndex = (searchSelectedIndex + delta + searchResults.count) % searchResults.count
        syncSearchSelection(resetIndex: false)
    }

    private func applySearchResult(_ result: SettingsSearchResult) {
        highlightedSearchResultID = result.id
        selection = result.section
        if let index = searchResults.firstIndex(of: result) {
            searchSelectedIndex = index
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search settings…", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .focused($searchFieldFocused)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 2) {
                        if isSearching {
                            if searchResults.isEmpty {
                                Text("No results")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, result in
                                    SettingsSearchResultRow(
                                        result: result,
                                        isSelected: highlightedSearchResultID == result.id
                                    ) {
                                        searchSelectedIndex = index
                                        applySearchResult(result)
                                    }
                                    .id(result.id)
                                }
                            }
                        } else {
                            ForEach(SettingsSection.allCases) { section in
                                SettingsSidebarRow(
                                    section: section,
                                    isSelected: selection == section
                                ) {
                                    selection = section
                                    highlightedSearchResultID = nil
                                }
                                .id(section.id)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                    .background(ScrollInsetFixer())
                }
                .scrollIndicators(.hidden)
                .onChange(of: highlightedSearchResultID) { _, newValue in
                    guard isSearching, let newValue else { return }
                    proxy.scrollTo(newValue, anchor: .center)
                }
                .onChange(of: selection) { _, newValue in
                    guard !isSearching else { return }
                    proxy.scrollTo(newValue.id, anchor: .center)
                }
            }
        }
        .frame(width: 196)
    }

    @ViewBuilder
    private var detail: some View {
        Group {
            switch selection {
            case .general:
                GeneralSettingsView()
            case .textTrigger:
                TextTriggerSettingsView()
            case .imageTrigger:
                ImageTriggerSettingsView()
            case .ai:
                AISettingsView()
            case .saving:
                SaveSettingsView()
            case .shortcuts:
                ShortcutsSettingsView()
            case .license:
                AboutSettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct SettingsSearchResultRow: View {
    let result: SettingsSearchResult
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: result.section.systemImage)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(result.sectionTitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(result.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.9))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSidebarRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                Text(section.title)
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared helpers

private struct SettingDescription: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SettingsForm<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                content
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollContentBackground(.hidden)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 14) {
                content
            }
        }
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var accessibilityTrusted = AccessibilityPermission.isTrusted
    @State private var runningApps: [PasteIntoAppService.RunningApp] = []
    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        SettingsForm {
            SettingsGroup(title: "Launcher") {
                Picker("Placement", selection: Binding(
                    get: { settings.launcherPlacement },
                    set: { settings.launcherPlacement = $0 }
                )) {
                    ForEach(LauncherPlacement.allCases) { Text($0.title).tag($0) }
                }
                SettingDescription(text: "Near selection follows your text. Centered appears in the middle of the screen and stays centered when the list resizes; drag to reposition.")

                if settings.launcherPlacement == .centered {
                    Button("Reset Centered Position") {
                        settings.centeredOrigin = nil
                    }
                }

                Picker("Auto-appear as", selection: Binding(
                    get: { settings.firstPresentation },
                    set: { settings.firstPresentation = $0 }
                )) {
                    ForEach(FirstPresentation.allCases) { Text($0.title).tag($0) }
                }
                SettingDescription(text: "Choose whether auto-appear shows the compact peek bar or the full launcher.")

                Stepper(
                    "Opening delay: \(settings.autoAppearDelay) ms",
                    value: Binding(get: { settings.autoAppearDelay }, set: { settings.autoAppearDelay = $0 }),
                    in: 0...500,
                    step: 10
                )
                SettingDescription(text: "How long to wait after you finish selecting text before the launcher appears.")
            }

            SettingsGroup(title: "Excluded Apps") {
                SettingDescription(text: "Select won't appear when capturing text or images from these apps.")
                if runningApps.isEmpty {
                    Text("No running apps found.").foregroundStyle(.secondary)
                } else {
                    ForEach(runningApps) { app in
                        Toggle(isOn: exclusionBinding(for: app)) {
                            HStack(spacing: 8) {
                                if let icon = app.icon {
                                    Image(nsImage: icon).resizable().frame(width: 18, height: 18)
                                }
                                Text(app.name)
                            }
                        }
                    }
                }
            }

            SettingsGroup(title: "Permissions") {
                HStack {
                    Text("Accessibility")
                    Spacer()
                    if accessibilityTrusted {
                        Label("Granted", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button("Grant Access") { AccessibilityPermission.promptIfNeeded() }
                    }
                }
                SettingDescription(text: "Required to read text selections from other apps.")
            }
        }
        .onAppear { refreshRunningApps() }
        .onReceive(pollTimer) { _ in accessibilityTrusted = AccessibilityPermission.isTrusted }
    }

    private func refreshRunningApps() {
        runningApps = PasteIntoAppService().runningApps()
    }

    private func exclusionBinding(for app: PasteIntoAppService.RunningApp) -> Binding<Bool> {
        Binding(
            get: {
                guard let bundleID = app.bundleID else { return false }
                return settings.excludedBundleIDs.contains(bundleID)
            },
            set: { excluded in
                guard let bundleID = app.bundleID else { return }
                if excluded {
                    if !settings.excludedBundleIDs.contains(bundleID) {
                        settings.toggleExclusion(bundleID: bundleID)
                    }
                } else if settings.excludedBundleIDs.contains(bundleID) {
                    settings.toggleExclusion(bundleID: bundleID)
                }
            }
        )
    }
}

// MARK: - Text trigger

private struct TextTriggerSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.reloadTriggers) private var reloadTriggers

    var body: some View {
        SettingsForm {
            SettingsGroup(title: "Text Selection") {
                Picker("Trigger mode", selection: Binding(
                    get: { settings.triggerMode },
                    set: {
                        settings.triggerMode = $0
                        reloadTriggers()
                    }
                )) {
                    ForEach(TriggerMode.allCases) { Text($0.title).tag($0) }
                }
                SettingDescription(text: "Automatic shows the launcher when you select text. Hotkey only responds to your shortcut.")

                Stepper(
                    "Minimum selection length: \(settings.minSelectionLength)",
                    value: Binding(get: { settings.minSelectionLength }, set: { settings.minSelectionLength = $0 }),
                    in: 1...50
                )
                SettingDescription(text: "Ignore very short selections to reduce accidental popups.")

                Toggle("Mouse selection only", isOn: Binding(
                    get: { settings.mouseSelectionOnly },
                    set: { settings.mouseSelectionOnly = $0 }
                ))
                SettingDescription(text: "When enabled, keyboard-only selections require the text trigger hotkey.")
            }
        }
    }
}

// MARK: - Image trigger

private struct ImageTriggerSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.reloadTriggers) private var reloadTriggers
    @State private var runningApps: [PasteIntoAppService.RunningApp] = []
    @State private var screenRecordingAuthorized = ScreenRecordingPermission.isAuthorized
    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        SettingsForm {
            SettingsGroup(title: "Screenshot Hotkey") {
                HStack {
                    Text("Screen Recording")
                    Spacer()
                    if screenRecordingAuthorized {
                        Label("Granted", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Label("Required", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    }
                }
                SettingDescription(text: "The screenshot hotkey (⌘⇧0) needs Screen Recording — not Accessibility. After enabling, quit and reopen Select.")

                if !screenRecordingAuthorized {
                    HStack {
                        Button("Open Screen Recording Settings") {
                            ScreenRecordingPermission.openSystemSettings()
                        }
                        Button("Add Select to List…") {
                            ScreenRecordingPermission.requestAuthorization()
                        }
                    }
                }
            }

            SettingsGroup(title: "Image Auto-Appear") {
                Toggle("Auto-appear on image copy", isOn: Binding(
                    get: { settings.imageAutoAppearEnabled },
                    set: {
                        settings.imageAutoAppearEnabled = $0
                        reloadTriggers()
                    }
                ))
                SettingDescription(text: "Opens the image launcher when you right-click Copy Image in a browser. Screenshots from tools like CleanShot are ignored.")

                Picker("Image launcher corner", selection: Binding(
                    get: { settings.imageLauncherCorner },
                    set: { settings.imageLauncherCorner = $0 }
                )) {
                    ForEach(ScreenCorner.allCases) { Text($0.title).tag($0) }
                }
                SettingDescription(text: "Where the image launcher appears for copied images and screenshots.")
            }

            SettingsGroup(title: "Allowed Apps") {
                SettingDescription(text: "Browsers in this list can trigger auto-appear via Copy Image (not screenshots).")
                ForEach(browserCandidates) { app in
                    if let bundleID = app.bundleID {
                        Toggle(isOn: allowlistBinding(bundleID: bundleID)) {
                            HStack(spacing: 8) {
                                if let icon = app.icon {
                                    Image(nsImage: icon).resizable().frame(width: 18, height: 18)
                                }
                                Text(app.name)
                            }
                        }
                    }
                }
                ForEach(defaultBrowsersNotRunning) { bundleID in
                    Toggle(isOn: allowlistBinding(bundleID: bundleID.id)) {
                        Text(bundleID.name)
                    }
                }
            }
        }
        .onAppear { refreshRunningApps() }
        .onReceive(pollTimer) { _ in screenRecordingAuthorized = ScreenRecordingPermission.isAuthorized }
    }

    private struct BundleEntry: Identifiable {
        let id: String
        let name: String
    }

    private var browserCandidates: [PasteIntoAppService.RunningApp] {
        runningApps.filter { app in
            guard let bundleID = app.bundleID else { return false }
            return AppSettings.defaultImageAutoAppearBundleIDs.contains(bundleID)
                || settings.imageAutoAppearBundleIDs.contains(bundleID)
        }
    }

    private var defaultBrowsersNotRunning: [BundleEntry] {
        let runningIDs = Set(runningApps.compactMap(\.bundleID))
        return AppSettings.defaultImageAutoAppearBundleIDs
            .filter { !runningIDs.contains($0) }
            .map { BundleEntry(id: $0, name: displayName(for: $0)) }
    }

    private func refreshRunningApps() {
        runningApps = PasteIntoAppService().runningApps()
    }

    private func allowlistBinding(bundleID: String) -> Binding<Bool> {
        Binding(
            get: { settings.imageAutoAppearBundleIDs.contains(bundleID) },
            set: { allowed in
                let contains = settings.imageAutoAppearBundleIDs.contains(bundleID)
                if allowed != contains {
                    settings.toggleImageAutoAppearBundleID(bundleID)
                    reloadTriggers()
                }
            }
        )
    }

    private func displayName(for bundleID: String) -> String {
        switch bundleID {
        case "com.apple.Safari": return "Safari"
        case "com.google.Chrome": return "Google Chrome"
        case "company.thebrowser.Browser": return "Arc"
        case "com.microsoft.edgemac": return "Microsoft Edge"
        case "org.mozilla.firefox": return "Firefox"
        case "com.brave.Browser": return "Brave"
        case "com.operasoftware.Opera": return "Opera"
        case "com.vivaldi.Vivaldi": return "Vivaldi"
        default: return bundleID
        }
    }
}

// MARK: - AI

private struct AISettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        SettingsForm {
            SettingsGroup(title: "Provider") {
                Picker("Provider", selection: Binding(
                    get: { settings.selectedProvider },
                    set: { settings.selectedProvider = $0 }
                )) {
                    ForEach(AIProviderKind.allCases) { Text($0.displayName).tag($0) }
                }

                switch settings.selectedProvider {
                case .appleFoundation:
                    SettingDescription(text: "Uses Apple Intelligence on-device (macOS 26+). No API key required.")
                case .openAI:
                    APIKeyField(provider: .openAI)
                    TextField("Model", text: Binding(get: { settings.openAIModel }, set: { settings.openAIModel = $0 }))
                case .anthropic:
                    APIKeyField(provider: .anthropic)
                    TextField("Model", text: Binding(get: { settings.anthropicModel }, set: { settings.anthropicModel = $0 }))
                case .gemini:
                    APIKeyField(provider: .gemini)
                    TextField("Model", text: Binding(get: { settings.geminiModel }, set: { settings.geminiModel = $0 }))
                case .openAICompatible:
                    TextField("Base URL", text: Binding(get: { settings.compatibleBaseURL }, set: { settings.compatibleBaseURL = $0 }))
                    TextField("Model", text: Binding(get: { settings.compatibleModel }, set: { settings.compatibleModel = $0 }))
                    APIKeyField(provider: .openAICompatible)
                }
            }

            SettingsGroup(title: "Translation") {
                SettingDescription(text: "Choose which languages appear in the Translate picker. All options auto-detect the source language.")
                ForEach(TranslationLanguage.catalog) { language in
                    Toggle(isOn: Binding(
                        get: { settings.isTranslationLanguageEnabled(language.code) },
                        set: { _ in settings.toggleTranslationLanguage(language.code) }
                    )) {
                        Text(language.name)
                    }
                }
            }
        }
    }
}

private struct APIKeyField: View {
    let provider: AIProviderKind
    @State private var key: String = ""

    var body: some View {
        HStack {
            SecureField("API Key", text: $key)
            Button("Save") {
                KeychainStore.setKey(key, for: ProviderRouter.keychainAccount(for: provider))
            }
        }
        .onAppear {
            key = KeychainStore.key(for: ProviderRouter.keychainAccount(for: provider)) ?? ""
        }
    }
}

// MARK: - Saving

private struct SaveSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var vaultPath: String = ""

    var body: some View {
        SettingsForm {
            SettingsGroup(title: "Default Target") {
                Picker("Default save target", selection: Binding(
                    get: { settings.defaultSaveTarget },
                    set: { settings.defaultSaveTarget = $0 }
                )) {
                    ForEach(SaveTargetKind.allCases) { Text($0.displayName).tag($0) }
                }
            }

            SettingsGroup(title: "Markdown Vault") {
                HStack {
                    Text("Markdown file / folder")
                    Spacer()
                    Text(vaultPath.isEmpty ? "Not set" : vaultPath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Choose…") { chooseVault() }
                }
                SettingDescription(text: "Text saved via Save to Markdown is appended to this file or folder.")
            }
        }
        .onAppear { refreshVaultPath() }
    }

    private func chooseVault() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowedContentTypes = [.plainText]
        panel.allowsOtherFileTypes = true
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            let service = MarkdownVaultService(settings: settings)
            try? service.setVault(url: url)
            refreshVaultPath()
        }
    }

    private func refreshVaultPath() {
        guard let bookmark = settings.markdownVaultBookmark else { vaultPath = ""; return }
        var stale = false
        if let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
            vaultPath = url.path
        }
    }
}

// MARK: - Shortcuts

private struct ShortcutsSettingsView: View {
    var body: some View {
        SettingsForm {
            SettingsGroup(title: "Global Shortcuts") {
                LabeledContent("Text trigger") {
                    KeyboardShortcuts.Recorder(for: .textTrigger)
                }
                SettingDescription(text: "Summons the launcher for the current text selection.")

                LabeledContent("Image trigger") {
                    KeyboardShortcuts.Recorder(for: .imageTrigger)
                }
                SettingDescription(text: "Summons the launcher for the current clipboard image.")

                LabeledContent("Screenshot") {
                    KeyboardShortcuts.Recorder(for: .screenshot)
                }
                SettingDescription(text: "Captures a screen region and opens the image launcher.")

                if let conflict = ShortcutConflictChecker.internalConflictMessage() {
                    Label(conflict, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }

                SettingDescription(text: "macOS cannot fully detect shortcuts already claimed by other apps. If a shortcut doesn't work, try a different combination.")
            }

            SettingsGroup(title: "In-Launcher Shortcuts") {
                SettingDescription(text: "These work while the launcher is focused:")
                ForEach(InLauncherShortcut.all, id: \.key) { shortcut in
                    HStack {
                        Text(shortcut.title)
                        Spacer()
                        Text(shortcut.display).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private enum ShortcutConflictChecker {
    static func internalConflictMessage() -> String? {
        let names: [KeyboardShortcuts.Name] = [.textTrigger, .imageTrigger, .screenshot]
        var seen: [KeyboardShortcuts.Shortcut: KeyboardShortcuts.Name] = [:]
        for name in names {
            guard let shortcut = KeyboardShortcuts.getShortcut(for: name) else { continue }
            if let existing = seen[shortcut] {
                return "“\(existing.rawValue)” and “\(name.rawValue)” use the same shortcut."
            }
            seen[shortcut] = name
        }
        return nil
    }
}

private struct InLauncherShortcut {
    let title: String
    let key: String
    let display: String

    static let all: [InLauncherShortcut] = [
        .init(title: "Copy", key: "c", display: "⌘ C"),
        .init(title: "Add to Queue", key: "s", display: "⌘ S"),
        .init(title: "Paste into App", key: "p", display: "⌘ P"),
        .init(title: "Save to Notes", key: "n", display: "⌘ N"),
        .init(title: "Save to Markdown", key: "m", display: "⌘ M"),
        .init(title: "Translate", key: "t", display: "⌘ T"),
        .init(title: "Summarize", key: "u", display: "⌘ U"),
        .init(title: "Rewrite", key: "r", display: "⌘ R"),
        .init(title: "Fix Grammar", key: "g", display: "⌘ G"),
        .init(title: "OCR", key: "o", display: "⌘ O"),
    ]
}

// MARK: - License

private struct AboutSettingsView: View {
    @StateObject private var license = LicenseManager.shared
    @State private var keyInput: String = ""
    @State private var message: String?

    var body: some View {
        SettingsForm {
            SettingsGroup(title: "License") {
                HStack {
                    Text("Status")
                    Spacer()
                    if license.isLicensed {
                        Label("Licensed", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    } else {
                        Text("Unlicensed").foregroundStyle(.secondary)
                    }
                }

                if !license.isLicensed {
                    HStack {
                        TextField("License key", text: $keyInput)
                        Button("Activate") { activate() }
                    }
                } else {
                    Button("Deactivate") { license.deactivate() }
                }

                if let message {
                    Text(message).font(.callout).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func activate() {
        Task {
            let result = await license.activate(key: keyInput)
            switch result {
            case .success: message = "Thanks! Your license is active."
            case let .failure(error): message = error.localizedDescription
            }
        }
    }
}

// MARK: - Environment

private struct ReloadTriggersKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var reloadTriggers: () -> Void {
        get { self[ReloadTriggersKey.self] }
        set { self[ReloadTriggersKey.self] = newValue }
    }
}
