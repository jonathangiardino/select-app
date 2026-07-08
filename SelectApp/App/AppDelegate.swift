import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var coordinator: AppCoordinator?
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var feedbackWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let coordinator = AppCoordinator()
        self.coordinator = coordinator
        coordinator.start()

        setUpStatusItem()

        // Reflect clip-queue count in the menu bar badge.
        coordinator.onQueueChange = { [weak self] count in
            self?.updateStatusItemBadge(count: count)
        }

        // DEBUG: skip onboarding; guide dev permission setup without spamming the system sheet.
        #if DEBUG
        AccessibilityPermission.handleDevLaunch { [weak coordinator] in
            coordinator?.reloadTriggers()
        }
        #else
        if !AppSettings.shared.onboardingComplete || !AccessibilityPermission.isTrusted {
            showOnboarding()
        }
        #endif
    }

    // MARK: - Status item

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "Select")
            button.image?.isTemplate = true
        }
        item.menu = buildMenu()
        statusItem = item
    }

    private func updateStatusItemBadge(count: Int) {
        guard let button = statusItem?.button else { return }
        if count > 0 {
            button.title = " \(count)"
        } else {
            button.title = ""
        }
        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let queueCount = coordinator?.clipQueue.count ?? 0
        let clipsItem = NSMenuItem(title: "Clips in queue: \(queueCount)", action: nil, keyEquivalent: "")
        clipsItem.isEnabled = false
        menu.addItem(clipsItem)

        if queueCount > 0 {
            menu.addItem(NSMenuItem(title: "Paste All Clips", action: #selector(pasteAllClips), keyEquivalent: "v"))
            menu.addItem(NSMenuItem(title: "Clear Queue", action: #selector(clearQueue), keyEquivalent: ""))
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))

        let feedbackItem = NSMenuItem(title: "Send Feedback…", action: #selector(openFeedback), keyEquivalent: "")
        feedbackItem.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: nil)
        feedbackItem.image?.isTemplate = true
        menu.addItem(feedbackItem)

        menu.addItem(NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Select", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        for item in menu.items where item.action != nil {
            item.target = self
        }
        // Keep the terminate action targeting NSApp.
        if let quit = menu.items.last { quit.target = nil }
        return menu
    }

    // MARK: - Actions

    @objc private func pasteAllClips() {
        coordinator?.clipQueue.pasteAll()
        HUDPresenter.shared.show("Pasted all clips", systemImage: "square.stack.3d.up")
    }

    @objc private func clearQueue() {
        coordinator?.clipQueue.clear()
        HUDPresenter.shared.show("Queue cleared", systemImage: "trash")
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        // We host our own settings window rather than SwiftUI's `Settings` scene: opening that
        // scene programmatically from an accessory/menu-bar app triggers a "use SettingsLink"
        // runtime error and doesn't reliably show.
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(
            rootView: SettingsView()
                .environmentObject(AppSettings.shared)
                .environment(\.reloadTriggers) { [weak self] in
                    self?.coordinator?.reloadTriggers()
                }
        )
        let window = NSWindow(contentViewController: hosting)
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor.windowBackgroundColor
        window.isOpaque = true
        window.styleMask = [.titled, .closable, .resizable]
        if #available(macOS 11.0, *) {
            window.toolbarStyle = .unified
        }
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.setContentSize(NSSize(width: 720, height: 520))
        window.center()
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
    }

    @objc private func checkForUpdates() {
        coordinator?.updater.checkForUpdates()
    }

    @objc private func openFeedback() {
        NSApp.activate(ignoringOtherApps: true)

        if let feedbackWindow {
            feedbackWindow.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(
            rootView: FeedbackView {
                self.feedbackWindow?.close()
                self.feedbackWindow = nil
            }
        )
        let window = FeedbackWindow(contentViewController: hosting)
        let size = hosting.sizeThatFits(in: NSSize(
            width: LauncherMetrics.width,
            height: CGFloat.greatestFiniteMagnitude
        ))
        window.setContentSize(size)
        window.center()
        window.makeKeyAndOrderFront(nil)
        feedbackWindow = window
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        let hosting = NSHostingController(
            rootView: OnboardingWizard(
                onFinish: { [weak self] in
                    AppSettings.shared.onboardingComplete = true
                    self?.onboardingWindow?.close()
                    self?.onboardingWindow = nil
                    self?.coordinator?.reloadTriggers()
                }
            )
            .environmentObject(AppSettings.shared)
        )
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to Select"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 500))
        window.center()
        window.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
    }
}
