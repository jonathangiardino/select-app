import AppKit
import SwiftUI

/// Drives the launcher UI: holds the current capture, the visible action list, the query text,
/// and which sub-screen is showing. Actions mutate this model.
@MainActor
final class LauncherViewModel: ObservableObject {
    enum Screen: Equatable {
        case actions
        case appPicker
        case notesFolderPicker
        case notesNotePicker(folder: String)
        case translationLanguagePicker
        case working(String)
        case result(title: String, text: String)
        case message(String)
    }

    /// A single selectable row rendered in any list screen (actions or sub-screens).
    struct Row: Identifiable {
        let id: String
        let title: String
        var subtitle: String? = nil
        let systemImage: String
        var iconImage: NSImage? = nil
        var shortcut: String? = nil
        let perform: () -> Void
    }

    @Published var capture: Capture
    @Published var actions: [LauncherAction] = []
    @Published var query: String = ""
    @Published var selectedIndex: Int = 0
    @Published var screen: Screen = .actions
    /// Whether the full launcher is showing (vs the compact peek bar).
    @Published var expanded: Bool = false
    /// True while arrow-key navigation is driving selection (suppresses hover scroll).
    @Published private(set) var isKeyboardNavigating = false
    /// Last arrow-key step (+1 down, −1 up) for edge-only list scrolling.
    @Published private(set) var lastSelectionDelta: Int = 0
    /// Published row list for the current screen — avoids SwiftUI stale-list bugs on navigation.
    @Published private(set) var visibleRows: [Row] = []
    /// Panel height driven by the current list content (keeps window sizing in sync with the UI).
    @Published private(set) var panelContentHeight: CGFloat = LauncherMetrics.maxHeight

    // Sub-screen data (loaded lazily when navigating into a screen).
    @Published private(set) var apps: [PasteIntoAppService.RunningApp] = []
    @Published private(set) var folders: [String] = []
    @Published private(set) var notes: [String] = []
    @Published private(set) var loadError: String?

    let registry: ActionRegistry
    var onDismiss: (() -> Void)?
    var onLayoutChange: (() -> Void)?

    // Services actions need.
    let clipQueue: ClipQueue
    let pasteboard: PasteboardService
    let pasteIntoApp: PasteIntoAppService
    let notesService: NotesService
    let markdownService: MarkdownVaultService
    let imageService: ImageService
    let aiService: AIService
    let settings: AppSettings

    init(capture: Capture, registry: ActionRegistry, services: ActionRegistry.Services) {
        self.capture = capture
        self.registry = registry
        self.clipQueue = services.clipQueue
        self.pasteboard = services.pasteboard
        self.pasteIntoApp = services.pasteIntoApp
        self.notesService = services.notesService
        self.markdownService = services.markdownService
        self.imageService = services.imageService
        self.aiService = services.aiService
        self.settings = services.settings
        self.actions = registry.actions(for: capture)
        refreshVisibleRows()
    }

    // MARK: - Rows for the current screen

    /// Whether the current screen renders a searchable, keyboard-navigable list.
    var isListScreen: Bool {
        switch screen {
        case .actions, .appPicker, .notesFolderPicker, .notesNotePicker, .translationLanguagePicker, .result:
            return true
        case .working, .message:
            return false
        }
    }

    /// The AI result body shown above the search field on result screens.
    var resultBodyText: String? {
        if case let .result(_, text) = screen { return text }
        return nil
    }

    /// Title shown in the back header for sub-screens (nil on the root actions screen).
    var screenTitle: String? {
        switch screen {
        case .appPicker: return "Paste into…"
        case .notesFolderPicker: return "Choose a folder"
        case .translationLanguagePicker: return "Translate to…"
        case let .notesNotePicker(folder): return folder
        case let .result(title, _): return title
        default: return nil
        }
    }

    /// Unfiltered rows for the current list screen.
    private var currentRows: [Row] {
        switch screen {
        case .actions:
            return actions.map { action in
                Row(
                    id: action.id,
                    title: action.title,
                    subtitle: action.subtitle,
                    systemImage: action.systemImage,
                    shortcut: action.shortcutDisplay
                ) { [weak self] in self?.run(action) }
            }
        case .appPicker:
            return apps.map { app in
                Row(id: "app-\(app.id)", title: app.name, systemImage: "app.dashed", iconImage: app.icon) {
                    [weak self] in self?.performPaste(into: app)
                }
            }
        case .notesFolderPicker:
            return folders.map { folder in
                Row(id: "folder-\(folder)", title: folder, systemImage: "folder") {
                    [weak self] in self?.showNotes(in: folder)
                }
            }
        case let .notesNotePicker(folder):
            var rows: [Row] = [
                Row(id: "new-note", title: "New note here", systemImage: "plus.circle") {
                    [weak self] in self?.saveNewNote(inFolder: folder)
                }
            ]
            rows += notes.map { note in
                Row(id: "note-\(note)", title: note, systemImage: "note.text") {
                    [weak self] in self?.appendToNote(note, inFolder: folder)
                }
            }
            return rows
        case .translationLanguagePicker:
            var rows: [Row] = [
                Row(
                    id: "translate-detect",
                    title: "Detect language",
                    subtitle: "Auto-detect source, translate to \(TranslationLanguage.named(settings.translationTargetLanguage))",
                    systemImage: "wand.and.stars"
                ) { [weak self] in
                    self?.runTranslation(detectSourceLanguage: true, targetLanguage: self?.settings.translationTargetLanguage ?? "en")
                }
            ]
            rows += settings.enabledTranslationLanguages.map { code in
                Row(
                    id: "translate-\(code)",
                    title: TranslationLanguage.named(code),
                    subtitle: "Translate into \(TranslationLanguage.named(code))",
                    systemImage: "globe"
                ) { [weak self] in
                    self?.runTranslation(detectSourceLanguage: true, targetLanguage: code)
                }
            }
            return rows
        case let .result(_, text):
            return [
                Row(id: "result-copy", title: "Copy", systemImage: "doc.on.doc") { [weak self] in
                    guard let self else { return }
                    pasteboard.copy(text: text)
                    HUDPresenter.shared.show("Copied")
                    dismiss()
                },
                Row(id: "result-replace", title: "Replace", systemImage: "arrow.triangle.2.circlepath") { [weak self] in
                    self?.replaceInSource(with: text)
                },
                Row(id: "result-queue", title: "Add to Queue", systemImage: "square.stack.3d.up.badge.plus") { [weak self] in
                    guard let self else { return }
                    clipQueue.addText(text)
                    HUDPresenter.shared.show("Added to queue")
                    dismiss()
                },
            ]
        default:
            return []
        }
    }

    /// Rows filtered by the current query.
    var filteredRows: [Row] { visibleRows }

    /// Forces list views to rebuild when the active screen or its data changes.
    var listRefreshID: String {
        switch screen {
        case .actions:
            return "actions-\(actions.map(\.id).joined())"
        case .appPicker:
            return "apps-\(apps.map { String($0.id) }.joined())"
        case .notesFolderPicker:
            return "folders-\(folders.joined())"
        case let .notesNotePicker(folder):
            return "notes-\(folder)-\(notes.joined())"
        case .translationLanguagePicker:
            return "translate-\(settings.enabledTranslationLanguages.joined())"
        case let .result(title, text):
            return "result-\(title)-\(text.hashValue)"
        default:
            return "other"
        }
    }

    var searchPlaceholder: String {
        switch screen {
        case .actions: return "Search actions…"
        case .appPicker: return "Search apps…"
        case .notesFolderPicker: return "Search folders…"
        case .notesNotePicker: return "Search notes…"
        case .translationLanguagePicker: return "Search languages…"
        case .result: return "Search actions…"
        default: return "Search…"
        }
    }

    func refreshVisibleRows() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let rows = currentRows
        visibleRows = trimmed.isEmpty
            ? rows
            : rows.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
        if visibleRows.isEmpty {
            selectedIndex = 0
        } else if selectedIndex >= visibleRows.count {
            selectedIndex = max(0, visibleRows.count - 1)
        }
        recomputePanelHeight()
    }

    /// Whether the search filter returned no matches.
    var isShowingEmptyResults: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty && visibleRows.isEmpty
    }

    var listNeedsScroll: Bool {
        let count = isShowingEmptyResults ? 1 : visibleRows.count
        return count > LauncherMetrics.maxListRows
    }

    var listAreaHeight: CGFloat {
        LauncherMetrics.listAreaHeight(
            rowCount: visibleRows.count,
            showsEmptyState: isShowingEmptyResults
        )
    }

    func recomputePanelHeight() {
        guard isListScreen else {
            switch screen {
            case .working:
                panelContentHeight = LauncherMetrics.workingMinHeight
            case .message:
                panelContentHeight = LauncherMetrics.workingMinHeight
            default:
                panelContentHeight = capture.content.isImage
                    ? LauncherMetrics.imageMaxHeight
                    : LauncherMetrics.maxHeight
            }
            onLayoutChange?()
            return
        }

        var subheader: CGFloat = 0
        if screenTitle != nil {
            subheader = LauncherMetrics.subheaderHeight
        }

        var imagePreview: CGFloat = 0
        if screen == .actions, case let .image(image) = capture.content {
            imagePreview = LauncherMetrics.imagePreviewHeight(for: image)
        }

        var resultText: CGFloat = 0
        if let body = resultBodyText {
            resultText = LauncherMetrics.resultTextHeight(body)
        }

        panelContentHeight = LauncherMetrics.panelContentHeight(
            subheaderHeight: subheader,
            imagePreviewHeight: imagePreview,
            resultTextHeight: resultText,
            listHeight: listAreaHeight
        )

        let cap: CGFloat
        if isListScreen {
            cap = LauncherMetrics.maxListScreenHeight
        } else {
            cap = capture.content.isImage ? LauncherMetrics.maxListScreenHeight : LauncherMetrics.maxHeight
        }
        panelContentHeight = min(panelContentHeight, cap)
        onLayoutChange?()
    }

    func showResult(title: String, text: String) {
        query = ""
        selectedIndex = 0
        screen = .result(title: title, text: text)
        refreshVisibleRows()
    }

    // MARK: - Navigation / execution

    func run(_ action: LauncherAction) {
        action.perform(on: self)
    }

    func runSelected() {
        let list = filteredRows
        guard list.indices.contains(selectedIndex) else { return }
        list[selectedIndex].perform()
    }

    func moveSelection(_ delta: Int) {
        let count = filteredRows.count
        guard count > 0 else { return }
        isKeyboardNavigating = true
        lastSelectionDelta = delta
        selectedIndex = (selectedIndex + delta + count) % count
    }

    func clearKeyboardNavigation() {
        isKeyboardNavigating = false
        lastSelectionDelta = 0
    }

    /// Runs the action bound to a ⌘-shortcut character on the actions screen, if any.
    @discardableResult
    func runShortcut(_ key: String) -> Bool {
        guard screen == .actions else { return false }
        guard let action = actions.first(where: { $0.shortcutKey == key.lowercased() }) else {
            return false
        }
        run(action)
        return true
    }

    /// Escape/back navigation: sub-screens step back one level; the root dismisses.
    func goBack() {
        switch screen {
        case .notesNotePicker:
            showNotesFolders()
        case .appPicker, .notesFolderPicker, .translationLanguagePicker, .working, .result, .message:
            goToActions()
        case .actions:
            dismiss()
        }
    }

    private func resetListState() {
        query = ""
        selectedIndex = 0
        refreshVisibleRows()
    }

    func goToActions() {
        loadError = nil
        query = ""
        selectedIndex = 0
        screen = .actions
        refreshVisibleRows()
        recomputePanelHeight()
    }

    func showTranslationLanguagePicker() {
        expanded = true
        query = ""
        selectedIndex = 0
        screen = .translationLanguagePicker
        refreshVisibleRows()
    }

    func runTranslation(detectSourceLanguage: Bool, targetLanguage: String) {
        guard let text = capture.content.text else { return }
        screen = .working("Translate…")
        recomputePanelHeight()
        Task { @MainActor in
            do {
                let raw = try await aiService.run(
                    kind: .translate,
                    input: text,
                    targetLanguage: targetLanguage,
                    detectSourceLanguage: detectSourceLanguage
                )
                let output = try AIOutputCleaner.validateTranslation(raw, input: text)
                showResult(title: "Translate", text: output)
            } catch {
                screen = .message(aiErrorMessage(error))
                recomputePanelHeight()
            }
        }
    }

    private func aiErrorMessage(_ error: Error) -> String {
        if let aiError = error as? AIError {
            return aiError.userMessage
        }
        return "AI request failed: \(error.localizedDescription)"
    }

    func showAppPicker() {
        expanded = true
        query = ""
        selectedIndex = 0
        apps = pasteIntoApp.runningApps()
        screen = .appPicker
        refreshVisibleRows()
    }

    func showNotesFolders() {
        expanded = true
        query = ""
        selectedIndex = 0
        loadError = nil
        folders = []
        screen = .notesFolderPicker
        refreshVisibleRows()
        Task { @MainActor in
            do {
                folders = try notesService.listFolders()
                if folders.isEmpty { loadError = "No Notes folders found." }
            } catch {
                loadError = error.localizedDescription
            }
            refreshVisibleRows()
        }
    }

    func showNotes(in folder: String) {
        expanded = true
        query = ""
        selectedIndex = 0
        loadError = nil
        notes = []
        screen = .notesNotePicker(folder: folder)
        refreshVisibleRows()
        Task { @MainActor in
            do {
                notes = try notesService.listNotes(inFolder: folder)
            } catch {
                loadError = error.localizedDescription
            }
            refreshVisibleRows()
        }
    }

    // MARK: - Sub-screen actions

    private func performPaste(into app: PasteIntoAppService.RunningApp) {
        // Dismiss first so our search field cannot intercept the synthetic Cmd-V.
        dismiss()
        switch capture.content {
        case let .text(text):
            pasteIntoApp.paste(text: text, into: app.app)
        case let .image(image):
            pasteIntoApp.paste(image: image, into: app.app)
        }
        HUDPresenter.shared.show("Pasted into \(app.name)", systemImage: "arrow.right.doc.on.clipboard")
    }

    /// Deletes the current selection in the source app after the launcher has dismissed.
    func deleteSelectionInSource() {
        pasteboard.deleteSelection(returningTo: capture.sourceBundleID)
    }

    private func saveNewNote(inFolder folder: String) {
        guard let text = capture.content.text else { return }
        let title = text.components(separatedBy: .newlines).first ?? "Note"
        do {
            try notesService.createNote(title: String(title.prefix(60)), body: text, inFolder: folder)
            HUDPresenter.shared.show("Saved to Notes")
            dismiss()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func appendToNote(_ note: String, inFolder folder: String) {
        guard let text = capture.content.text else { return }
        do {
            try notesService.appendToNote(named: note, inFolder: folder, text: text)
            HUDPresenter.shared.show("Saved to Notes")
            dismiss()
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Replaces the current capture (e.g. after OCR converts an image to text) and rebuilds actions.
    func replaceCapture(with newCapture: Capture) {
        capture = newCapture
        actions = registry.actions(for: newCapture)
        query = ""
        selectedIndex = 0
        screen = .actions
        refreshVisibleRows()
    }

    func expand() {
        expanded = true
        recomputePanelHeight()
    }

    func dismiss() {
        onDismiss?()
    }

    /// Copies text back to the source and pastes it (replace-in-place), then dismisses.
    func replaceInSource(with text: String) {
        let bundleID = capture.sourceBundleID
        dismiss()
        pasteboard.copyPlainText(text)
        pasteboard.paste(into: bundleID)
        HUDPresenter.shared.show("Replaced")
    }
}
