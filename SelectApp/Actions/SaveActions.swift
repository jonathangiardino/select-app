import AppKit

/// Save the text to Apple Notes — opens the folder/note browser (new or existing).
struct SaveToNotesAction: LauncherAction {
    let id = "saveNotes"
    let title = "Save to Apple Notes…"
    let systemImage = "note.text"
    let shortcutKey: String? = "n"

    func perform(on model: LauncherViewModel) {
        model.showNotesFolders()
    }
}

/// Append the text to the configured Markdown file/vault.
struct SaveToMarkdownAction: LauncherAction {
    let id = "saveMarkdown"
    let title = "Save to Markdown"
    var subtitle: String? { "Append to your Obsidian/Logseq/plain vault" }
    let systemImage = "doc.plaintext"
    let shortcutKey: String? = "m"

    func perform(on model: LauncherViewModel) {
        guard let text = model.capture.content.text else {
            model.screen = .message("Only text can be saved to Markdown.")
            return
        }
        guard model.markdownService.isConfigured else {
            model.screen = .message("Choose a Markdown file or folder in Settings first.")
            return
        }
        do {
            try model.markdownService.append(text: text)
            HUDPresenter.shared.show("Saved to Markdown")
            model.dismiss()
        } catch {
            model.screen = .message("Could not save: \(error.localizedDescription)")
        }
    }
}
