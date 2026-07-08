import Foundation

/// Builds the content-aware list of actions for a given capture.
@MainActor
final class ActionRegistry {
    struct Services {
        let clipQueue: ClipQueue
        let pasteboard: PasteboardService
        let pasteIntoApp: PasteIntoAppService
        let notesService: NotesService
        let markdownService: MarkdownVaultService
        let imageService: ImageService
        let aiService: AIService
        let settings: AppSettings
    }

    let services: Services

    init(
        clipQueue: ClipQueue,
        pasteboard: PasteboardService,
        pasteIntoApp: PasteIntoAppService,
        notesService: NotesService,
        markdownService: MarkdownVaultService,
        imageService: ImageService,
        aiService: AIService,
        settings: AppSettings
    ) {
        self.services = Services(
            clipQueue: clipQueue,
            pasteboard: pasteboard,
            pasteIntoApp: pasteIntoApp,
            notesService: notesService,
            markdownService: markdownService,
            imageService: imageService,
            aiService: aiService,
            settings: settings
        )
    }

    func actions(for capture: Capture, imageAlreadyOnClipboard: Bool = false) -> [LauncherAction] {
        switch capture.content {
        case .text:
            return textActions(hasSelection: capture.hasTextSelection)
        case .image:
            return imageActions(alreadyOnClipboard: imageAlreadyOnClipboard)
        }
    }

    private func textActions(hasSelection: Bool) -> [LauncherAction] {
        var actions: [LauncherAction] = []
        if hasSelection {
            actions.append(DeleteTextAction())
        }
        actions += [
            CopyAction(),
            AddToQueueAction(),
            PasteIntoAppAction(),
            SaveToNotesAction(),
            SaveToMarkdownAction(),
            AIAction(kind: .translate),
            AIAction(kind: .summarize),
            AIAction(kind: .rewrite),
            AIAction(kind: .grammar),
        ]
        return actions
    }

    private func imageActions(alreadyOnClipboard: Bool) -> [LauncherAction] {
        var actions: [LauncherAction] = [OCRAction()]
        // A copied image is already on the clipboard, so "Copy to Clipboard" is redundant there;
        // a screenshot lives in a temp file, so it still needs the copy action.
        if !alreadyOnClipboard {
            actions.append(CopyAction())
        }
        actions.append(AddToQueueAction())
        actions.append(PasteIntoAppAction())
        return actions
    }
}
