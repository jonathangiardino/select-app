import Foundation

enum NotesError: LocalizedError {
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case let .scriptFailed(message): return message
        }
    }
}

/// Integrates with Apple Notes via AppleScript (triggers the Automation permission prompt on
/// first use). Supports listing folders/notes, creating a new note, and appending to an existing one.
@MainActor
final class NotesService {
    func listFolders() throws -> [String] {
        let script = #"tell application "Notes" to get name of folders"#
        return try runReturningList(script)
    }

    func listNotes(inFolder folder: String) throws -> [String] {
        let script = """
        tell application "Notes" to get name of notes of folder "\(escape(folder))"
        """
        return try runReturningList(script)
    }

    func createNote(title: String, body: String, inFolder folder: String) throws {
        // Notes uses HTML for the body; the first line becomes the title if none is set.
        let html = "<div><b>\(escapeHTML(title))</b></div><div>\(escapeHTML(body))</div>"
        let script = """
        tell application "Notes"
            tell folder "\(escape(folder))"
                make new note with properties {name:"\(escape(title))", body:"\(escape(html))"}
            end tell
        end tell
        """
        try run(script)
    }

    func appendToNote(named name: String, inFolder folder: String, text: String) throws {
        let addition = "<div>\(escapeHTML(text))</div>"
        let script = """
        tell application "Notes"
            tell folder "\(escape(folder))"
                set theNote to first note whose name is "\(escape(name))"
                set body of theNote to (body of theNote) & "\(escape(addition))"
            end tell
        end tell
        """
        try run(script)
    }

    // MARK: - AppleScript execution

    private func runReturningList(_ source: String) throws -> [String] {
        let output = try runReturningDescriptor(source)
        var items: [String] = []
        if output.numberOfItems > 0 {
            for index in 1...output.numberOfItems {
                if let value = output.atIndex(index)?.stringValue {
                    items.append(value)
                }
            }
        } else if let single = output.stringValue, !single.isEmpty {
            items = single.components(separatedBy: ", ")
        }
        return items
    }

    @discardableResult
    private func runReturningDescriptor(_ source: String) throws -> NSAppleEventDescriptor {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw NotesError.scriptFailed("Could not compile script.")
        }
        let result = script.executeAndReturnError(&error)
        if let error {
            let message = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error."
            throw NotesError.scriptFailed(message)
        }
        return result
    }

    private func run(_ source: String) throws {
        _ = try runReturningDescriptor(source)
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}
