import AppKit
import KeyboardShortcuts

/// Owns the always-running pieces and routes captures from the monitors to the launcher panel.
@MainActor
final class AppCoordinator {
    let settings = AppSettings.shared
    let clipQueue = ClipQueue()
    let updater = UpdaterController()
    let license = LicenseManager.shared

    private lazy var pasteboard = PasteboardService()
    private lazy var pasteIntoApp = PasteIntoAppService()
    private lazy var notesService = NotesService()
    private lazy var markdownService = MarkdownVaultService(settings: settings)
    private lazy var imageService = ImageService()
    private lazy var aiService = AIService(settings: settings)

    private lazy var actionRegistry = ActionRegistry(
        clipQueue: clipQueue,
        pasteboard: pasteboard,
        pasteIntoApp: pasteIntoApp,
        notesService: notesService,
        markdownService: markdownService,
        imageService: imageService,
        aiService: aiService,
        settings: settings
    )

    private lazy var panelController = PanelController(settings: settings)

    private let selectionMonitor = SelectionMonitor()
    private let clipboardMonitor = ClipboardMonitor()
    private var shortcutsRegistered = false

    /// Global ⌘V watcher, installed only while the queue is non-empty, so a plain paste
    /// elsewhere consumes and clears the queue.
    private var queuePasteMonitor: Any?

    /// Set by the app delegate to keep the menu-bar badge in sync.
    var onQueueChange: ((Int) -> Void)?

    func start() {
        panelController.registry = actionRegistry

        clipQueue.onChange = { [weak self] count in
            self?.handleQueueCountChanged(count)
        }

        selectionMonitor.onCapture = { [weak self] capture in
            self?.present(capture, trigger: .mouseSelection)
        }
        clipboardMonitor.onImageCopied = { [weak self] capture in
            self?.present(capture, trigger: .imageCopy)
        }

        registerShortcutsIfNeeded()
        reloadTriggers()
    }

    // MARK: - Queue paste watching

    private func handleQueueCountChanged(_ count: Int) {
        if count > 0 {
            installQueuePasteMonitor()
        } else {
            removeQueuePasteMonitor()
        }
        onQueueChange?(count)
    }

    private func installQueuePasteMonitor() {
        guard queuePasteMonitor == nil else { return }
        queuePasteMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return }
            guard event.modifierFlags.contains(.command), event.keyCode == 9 else { return }
            DispatchQueue.main.async { self.clipQueue.clearIfClipboardMatchesQueue() }
        }
    }

    private func removeQueuePasteMonitor() {
        if let queuePasteMonitor { NSEvent.removeMonitor(queuePasteMonitor) }
        queuePasteMonitor = nil
    }

    private func registerShortcutsIfNeeded() {
        guard !shortcutsRegistered else { return }
        shortcutsRegistered = true

        KeyboardShortcuts.onKeyUp(for: .textTrigger) { [weak self] in
            self?.handleTextHotkey()
        }
        KeyboardShortcuts.onKeyUp(for: .imageTrigger) { [weak self] in
            self?.handleImageHotkey()
        }
        KeyboardShortcuts.onKeyUp(for: .screenshot) { [weak self] in
            self?.handleScreenshotHotkey()
        }
    }

    /// (Re)configure monitors to match the current trigger mode.
    func reloadTriggers() {
        let mode = settings.triggerMode
        selectionMonitor.configure(settings: settings)
        clipboardMonitor.configure(settings: settings)

        if mode.autoAppearEnabled {
            selectionMonitor.startIfNeeded()
            if settings.imageAutoAppearEnabled {
                clipboardMonitor.start()
            } else {
                clipboardMonitor.stop()
            }
        } else {
            selectionMonitor.stop()
            clipboardMonitor.stop()
        }

        if mode.hotkeyEnabled {
            KeyboardShortcuts.enable(.textTrigger)
            KeyboardShortcuts.enable(.imageTrigger)
        } else {
            KeyboardShortcuts.disable(.textTrigger)
            KeyboardShortcuts.disable(.imageTrigger)
        }

        KeyboardShortcuts.enable(.screenshot)
    }

    func requestAccessibilityIfNeeded() {
        AccessibilityPermission.promptIfNeeded()
    }

    // MARK: - Presentation

    private func handleTextHotkey() {
        if let capture = selectionMonitor.currentSelectionCapture() {
            present(capture, trigger: .hotkey)
        }
    }

    private func handleImageHotkey() {
        if let image = pasteboard.currentImage() {
            present(Capture(content: .image(image)), trigger: .hotkey)
        }
    }

    private func handleScreenshotHotkey() {
        Task { @MainActor in
            do {
                guard let image = try await ScreenshotService.captureInteractiveRegion() else { return }
                present(Capture(content: .image(image)), trigger: .screenshot)
            } catch ScreenshotService.ScreenshotError.notAuthorized {
                showScreenRecordingAlert()
            } catch {
                NSLog("SelectApp: screenshot failed — \(error.localizedDescription)")
            }
        }
    }

    private func showScreenRecordingAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Required"
        alert.informativeText = """
        Screenshots need Screen Recording permission — this is separate from Accessibility.

        1. Open System Settings → Privacy & Security → Screen Recording
        2. Enable Select
        3. Quit Select completely (⌘Q from the menu bar) and reopen it

        If the toggle is already on but screenshots still fail (common with unsigned dev builds), run in Terminal:
        tccutil reset ScreenCapture com.selectapp.SelectApp
        Then enable Select again and relaunch.
        """
        alert.addButton(withTitle: "Open Screen Recording Settings")
        alert.addButton(withTitle: "Add to List…")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            ScreenRecordingPermission.openSystemSettings()
        case .alertSecondButtonReturn:
            ScreenRecordingPermission.requestAuthorization()
        default:
            break
        }
    }

    private func present(_ capture: Capture, trigger: TriggerSource) {
        if settings.isExcluded(bundleID: capture.sourceBundleID) { return }

        // An image already on the clipboard (copy or image-hotkey) doesn't need a Copy action;
        // a screenshot is captured to a temp file, so it does.
        let imageAlreadyOnClipboard: Bool
        switch trigger {
        case .imageCopy:
            imageAlreadyOnClipboard = true
        case .hotkey:
            imageAlreadyOnClipboard = capture.content.isImage
        case .screenshot, .mouseSelection:
            imageAlreadyOnClipboard = false
        }

        let actions = actionRegistry.actions(for: capture, imageAlreadyOnClipboard: imageAlreadyOnClipboard)
        panelController.present(capture: capture, actions: actions, trigger: trigger)
    }
}
