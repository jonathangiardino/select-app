import SwiftUI

/// First-run wizard: welcome, permissions (Accessibility + Screen Recording), trigger mode.
struct OnboardingWizard: View {
    @EnvironmentObject var settings: AppSettings
    let onFinish: () -> Void

    // If onboarding was already completed, we're only here to re-fix permissions — jump
    // straight to the Accessibility step instead of replaying the welcome flow.
    @State private var step = AppSettings.shared.onboardingComplete ? 1 : 0
    @State private var accessibilityTrusted = AccessibilityPermission.isTrusted
    @State private var screenRecordingAuthorized = ScreenRecordingPermission.isAuthorized
    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)

            Divider()

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                }
                Spacer()
                if settings.onboardingComplete, isPermissionStep, !currentStepGranted {
                    Button("Skip") { onFinish() }
                }
                Button(step == lastStep ? "Finish" : "Continue") {
                    if step == lastStep { onFinish() } else { step += 1 }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .onReceive(pollTimer) { _ in
            accessibilityTrusted = AccessibilityPermission.isTrusted
            screenRecordingAuthorized = ScreenRecordingPermission.isAuthorized
        }
    }

    private var lastStep: Int { 3 }

    private var isPermissionStep: Bool { step == 1 || step == 2 }

    private var currentStepGranted: Bool {
        switch step {
        case 1: accessibilityTrusted
        case 2: screenRecordingAuthorized
        default: true
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcomeStep
        case 1: accessibilityStep
        case 2: screenRecordingStep
        default: triggerStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)
            Text("Welcome to Select")
                .font(.largeTitle.bold())
            Text("Select text anywhere — or copy an image — and Select pops up with quick actions: copy, queue, paste into another app, save to Notes, OCR, and AI.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Image(systemName: accessibilityTrusted ? "checkmark.shield.fill" : "lock.shield")
                .font(.system(size: 52))
                .foregroundStyle(accessibilityTrusted ? Color.green : Color.accentColor)
            Text("Enable Accessibility")
                .font(.title.bold())
            Text("Select needs Accessibility to read your selected text and paste into other apps. Your text never leaves your Mac unless you run a cloud AI action.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if accessibilityTrusted {
                Label("Access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                HStack {
                    Button("Grant Access") { AccessibilityPermission.promptIfNeeded() }
                    Button("Open System Settings") { AccessibilityPermission.openSystemSettings() }
                }
            }
        }
    }

    private var screenRecordingStep: some View {
        VStack(spacing: 16) {
            Image(systemName: screenRecordingAuthorized ? "checkmark.rectangle.fill" : "rectangle.dashed.badge.record")
                .font(.system(size: 52))
                .foregroundStyle(screenRecordingAuthorized ? Color.green : Color.accentColor)
            Text("Enable Screen Recording")
                .font(.title.bold())
            Text("Required for the screenshot hotkey (⌘⇧0). This is separate from Accessibility — enable Select under Screen Recording in System Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if screenRecordingAuthorized {
                Label("Access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                HStack {
                    Button("Add Select to List…") { ScreenRecordingPermission.requestAuthorization() }
                    Button("Open System Settings") { ScreenRecordingPermission.openSystemSettings() }
                }
                Text("After enabling, quit and reopen Select for the grant to take effect.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var triggerStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How should Select appear?")
                .font(.title.bold())
            Picker("", selection: Binding(
                get: { settings.triggerMode },
                set: { settings.triggerMode = $0 }
            )) {
                ForEach(TriggerMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Text("Automatic: appears when you finish a mouse selection or copy an image in a browser. Hotkey: press ⌥C (also works for keyboard selections). You can change this anytime in Settings.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
