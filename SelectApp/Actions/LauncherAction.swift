import Foundation

/// A single command shown in the launcher list. Performing it either completes a terminal
/// operation (and dismisses) or navigates the launcher to a sub-screen.
@MainActor
protocol LauncherAction {
    var id: String { get }
    var title: String { get }
    var subtitle: String? { get }
    var systemImage: String { get }
    /// Single character (lowercased) triggered together with ⌘ to run this action from the
    /// launcher. `nil` means no shortcut.
    var shortcutKey: String? { get }
    func perform(on model: LauncherViewModel)
}

extension LauncherAction {
    var subtitle: String? { nil }
    var shortcutKey: String? { nil }

    /// Human-readable shortcut label (e.g. "⌘ C") for display in the UI. A thin space keeps the
    /// ⌘ glyph from looking squashed against the key.
    var shortcutDisplay: String? {
        guard let key = shortcutKey else { return nil }
        return "⌘\u{2009}" + key.uppercased()
    }
}
