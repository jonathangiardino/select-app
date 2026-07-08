import AppKit
import SwiftUI
import Combine

/// Presents and positions the launcher panel, manages peek/launcher sizing, and dismisses on
/// Escape or click-outside.
@MainActor
final class PanelController {
    private let settings: AppSettings
    private let panel = LauncherPanel()
    private var hostingController: NSHostingController<LauncherRootView>?
    private var model: LauncherViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var moveObserver: NSObjectProtocol?
    private var isApplyingFrame = false
    private var hasAppliedFrame = false

    private var currentSourceRect: CGRect?
    private var currentTrigger: TriggerSource = .hotkey
    private var frozenAnchor: PanelPlacement.Anchor?
    private var placementScreen: NSScreen?

    private let peekSize = NSSize(width: 300, height: 56)

    init(settings: AppSettings) {
        self.settings = settings
    }

    /// The coordinator sets this so the controller can build view models (incl. OCR re-presentation).
    var registry: ActionRegistry?

    func present(capture: Capture, actions: [LauncherAction], trigger: TriggerSource) {
        guard let registry else { return }

        if model != nil { dismiss() }

        let model = LauncherViewModel(capture: capture, registry: registry, services: registry.services)
        model.actions = actions
        model.onDismiss = { [weak self] in self?.dismiss() }

        switch trigger {
        case .hotkey, .screenshot:
            model.expanded = true
        case .mouseSelection, .imageCopy:
            model.expanded = settings.firstPresentation == .launcher
        }

        self.model = model
        self.currentSourceRect = capture.sourceRect
        self.currentTrigger = trigger

        model.onLayoutChange = { [weak self, weak model] in
            guard let self, let model else { return }
            self.applyFrame(for: model)
        }

        freezePlacement(for: model, trigger: trigger)
        bind(model)

        let root = LauncherRootView(model: model)
        let hosting = NSHostingController(rootView: root)
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = [.intrinsicContentSize]
        }
        hostingController = hosting
        panel.contentViewController = hosting
        roundContentCorners()

        applyFrame(for: model)

        panel.makeKeyAndOrderFront(nil)
        installDismissMonitors()
        installMoveObserverIfNeeded()
    }

    private func freezePlacement(for model: LauncherViewModel, trigger: TriggerSource) {
        let fullSize = contentSize(for: model)

        switch trigger {
        case .imageCopy, .screenshot:
            let screen = PanelPlacement.screen(containing: NSEvent.mouseLocation)
            placementScreen = screen
            let origin = PanelPlacement.cornerOrigin(
                for: fullSize,
                corner: settings.imageLauncherCorner,
                on: screen
            )
            frozenAnchor = PanelPlacement.bottomAnchor(from: origin)
            panel.isMovableByWindowBackground = false

        case .mouseSelection, .hotkey:
            let screen: NSScreen
            let origin: NSPoint

            switch settings.launcherPlacement {
            case .nearSelection:
                screen = placementScreenForNearSelection(capture: model.capture)
                origin = PanelPlacement.origin(for: fullSize, near: currentSourceRect, on: screen)
                panel.isMovableByWindowBackground = false

            case .centered:
                screen = placementScreenForCentered(capture: model.capture)
                origin = PanelPlacement.centeredOrigin(
                    for: fullSize,
                    on: screen,
                    savedCenter: settings.centeredOrigin
                )
                panel.isMovableByWindowBackground = true
            }

            placementScreen = screen
            // Always top-anchored so height changes grow/shrink downward without drifting.
            frozenAnchor = PanelPlacement.topAnchor(from: origin, size: fullSize)
        }
    }

    private func placementScreenForNearSelection(capture: Capture) -> NSScreen {
        if let rect = capture.sourceRect, rect != .zero {
            return PanelPlacement.screen(containing: NSPoint(x: rect.midX, y: rect.midY))
        }
        return PanelPlacement.screen(containing: NSEvent.mouseLocation)
    }

    private func placementScreenForCentered(capture: Capture) -> NSScreen {
        if let rect = capture.sourceRect, rect != .zero {
            return PanelPlacement.screen(containing: NSPoint(x: rect.midX, y: rect.midY))
        }
        return PanelPlacement.screen(containing: NSEvent.mouseLocation)
    }

    private func roundContentCorners() {
        guard let contentView = panel.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = LauncherMetrics.panelCornerRadius
        contentView.layer?.cornerCurve = .continuous
        contentView.layer?.masksToBounds = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
    }

    // MARK: - Binding / sizing

    private func bind(_ model: LauncherViewModel) {
        cancellables.removeAll()
        model.$expanded
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self, weak model] _ in
                guard let self, let model else { return }
                model.recomputePanelHeight()
                self.refreezeAnchor(for: model)
            }
            .store(in: &cancellables)
    }

    private func contentSize(for model: LauncherViewModel) -> NSSize {
        let width = LauncherMetrics.width
        guard model.expanded || model.screen != .actions else { return peekSize }

        if !model.isListScreen {
            return NSSize(width: width, height: model.panelContentHeight)
        }

        return NSSize(width: width, height: model.panelContentHeight)
    }

    private func applyFrame(for model: LauncherViewModel) {
        guard frozenAnchor != nil else { return }

        let size = contentSize(for: model)

        // Keep the top edge fixed on every resize.
        if hasAppliedFrame, panel.frame.width > 0, panel.frame.height > 0 {
            frozenAnchor = .topLeft(x: panel.frame.minX, topY: panel.frame.maxY)
        }

        guard let anchor = frozenAnchor else { return }
        let origin = PanelPlacement.origin(from: anchor, size: size)

        isApplyingFrame = true
        panel.setFrame(NSRect(origin: origin, size: size), display: true, animate: false)
        hasAppliedFrame = true
        DispatchQueue.main.async { [weak self] in
            self?.isApplyingFrame = false
        }
    }

    /// Recomputes the frozen anchor after peek → full expansion using the current panel frame.
    private func refreezeAnchor(for model: LauncherViewModel) {
        guard panel.frame.width > 0, panel.frame.height > 0 else { return }
        frozenAnchor = .topLeft(x: panel.frame.minX, topY: panel.frame.maxY)
        applyFrame(for: model)
    }

    private func installMoveObserverIfNeeded() {
        removeMoveObserver()
        guard settings.launcherPlacement == .centered,
              currentTrigger == .mouseSelection || currentTrigger == .hotkey else { return }

        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handlePanelMoved()
            }
        }
    }

    private func handlePanelMoved() {
        guard !isApplyingFrame else { return }
        guard settings.launcherPlacement == .centered else { return }
        let frame = panel.frame
        settings.centeredOrigin = NSPoint(x: frame.midX, y: frame.midY)
        frozenAnchor = .topLeft(x: frame.minX, topY: frame.maxY)
    }

    private func removeMoveObserver() {
        if let moveObserver {
            NotificationCenter.default.removeObserver(moveObserver)
        }
        moveObserver = nil
    }

    // MARK: - Dismissal

    private func installDismissMonitors() {
        removeDismissMonitors()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, let model = self.model else { return event }

            if event.modifierFlags.contains(.command),
               let chars = event.charactersIgnoringModifiers,
               model.runShortcut(chars) {
                return nil
            }

            switch event.keyCode {
            case 53:
                model.goBack()
                return nil
            case 126:
                if model.isListScreen { model.moveSelection(-1); return nil }
                return event
            case 125:
                if model.isListScreen { model.moveSelection(1); return nil }
                return event
            case 36:
                if model.isListScreen { model.runSelected(); return nil }
                return event
            default:
                return event
            }
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismiss()
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didActivateApplicationNotification] {
            let observer = workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.dismiss() }
            }
            workspaceObservers.append(observer)
        }
    }

    private func removeDismissMonitors() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        localMonitor = nil
        globalMonitor = nil
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers { workspaceCenter.removeObserver(observer) }
        workspaceObservers.removeAll()
    }

    func dismiss() {
        removeDismissMonitors()
        removeMoveObserver()
        cancellables.removeAll()
        panel.orderOut(nil)
        panel.contentViewController = nil
        hostingController = nil
        model = nil
        frozenAnchor = nil
        placementScreen = nil
        hasAppliedFrame = false
        panel.isMovableByWindowBackground = false
    }
}
