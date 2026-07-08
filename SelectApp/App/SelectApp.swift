import SwiftUI

@main
struct SelectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Settings scene provides the standard Preferences window (Cmd-,).
        Settings {
            SettingsView()
                .environmentObject(AppSettings.shared)
        }
    }
}
