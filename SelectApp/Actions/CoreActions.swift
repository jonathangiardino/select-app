import AppKit

/// Delete the current selection in the source app (best-effort; editable fields only).
struct DeleteTextAction: LauncherAction {
    let id = "delete"
    let title = "Delete Selection"
    var subtitle: String? { "Remove the selected text" }
    let systemImage = "delete.left"
    let shortcutKey: String? = nil

    func perform(on model: LauncherViewModel) {
        model.dismiss()
        model.deleteSelectionInSource()
        HUDPresenter.shared.show("Deleted", systemImage: "trash")
    }
}

/// Copy the capture (text or image) to the clipboard.
struct CopyAction: LauncherAction {
    let id = "copy"
    let title = "Copy to Clipboard"
    let systemImage = "doc.on.doc"
    let shortcutKey: String? = "c"

    func perform(on model: LauncherViewModel) {
        switch model.capture.content {
        case let .text(text):
            model.pasteboard.copy(text: text)
        case let .image(image):
            model.pasteboard.copy(image: image)
        }
        HUDPresenter.shared.show("Copied")
        model.dismiss()
    }
}

/// Add the capture to the ephemeral multi-clip queue.
struct AddToQueueAction: LauncherAction {
    let id = "queue"
    let title = "Add to Queue"
    var subtitle: String? { "Collect multiple clips, paste them all later" }
    let systemImage = "square.stack.3d.up"
    let shortcutKey: String? = "s"

    func perform(on model: LauncherViewModel) {
        switch model.capture.content {
        case let .text(text):
            model.clipQueue.addText(text)
        case let .image(image):
            model.clipQueue.addImage(image)
        }
        HUDPresenter.shared.show("Added to queue")
        model.dismiss()
    }
}

/// Paste the capture into a chosen running app.
struct PasteIntoAppAction: LauncherAction {
    let id = "pasteInto"
    let title = "Paste into App…"
    let systemImage = "arrow.right.doc.on.clipboard"
    let shortcutKey: String? = "p"

    func perform(on model: LauncherViewModel) {
        model.showAppPicker()
    }
}
