import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Summons the launcher for the current text selection (default: ⌥C).
    static let textTrigger = Self("textTrigger", default: .init(.c, modifiers: [.option]))

    /// Summons the launcher for the current clipboard image.
    static let imageTrigger = Self("imageTrigger")

    /// Captures a region via the system screenshot UI and opens the image launcher.
    static let screenshot = Self("screenshot", default: .init(.zero, modifiers: [.command, .shift]))
}
