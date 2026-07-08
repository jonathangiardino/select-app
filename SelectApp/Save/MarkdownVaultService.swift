import Foundation

enum MarkdownError: LocalizedError {
    case notConfigured
    case cannotResolveBookmark
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "No Markdown file or folder is configured."
        case .cannotResolveBookmark: return "Could not access the saved Markdown location."
        case let .writeFailed(message): return message
        }
    }
}

/// Appends text to a user-chosen Markdown file, or to a dated note inside a chosen folder.
/// The location is remembered via a security-scoped bookmark in `AppSettings`.
final class MarkdownVaultService {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    var isConfigured: Bool {
        settings.markdownVaultBookmark != nil
    }

    /// Stores a security-scoped bookmark for the chosen file/folder URL.
    func setVault(url: URL) throws {
        let bookmark = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        settings.markdownVaultBookmark = bookmark
    }

    func append(text: String) throws {
        guard let bookmark = settings.markdownVaultBookmark else {
            throw MarkdownError.notConfigured
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            throw MarkdownError.cannotResolveBookmark
        }

        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        let targetFile = try resolveTargetFile(base: url)
        try appendString(makeEntry(text), to: targetFile)
    }

    // MARK: - Helpers

    private func resolveTargetFile(base: URL) throws -> URL {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: base.path, isDirectory: &isDirectory)
        if isDirectory.boolValue {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let filename = "Select \(formatter.string(from: Date())).md"
            return base.appendingPathComponent(filename)
        }
        return base
    }

    private func makeEntry(_ text: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\n\n> Captured \(formatter.string(from: Date()))\n\n\(text)\n"
    }

    private func appendString(_ string: String, to file: URL) throws {
        let data = Data(string.utf8)
        if FileManager.default.fileExists(atPath: file.path) {
            let handle = try FileHandle(forWritingTo: file)
            defer { try? handle.close() }
            try handle.seekToEnd()
            handle.write(data)
        } else {
            do {
                try data.write(to: file)
            } catch {
                throw MarkdownError.writeFailed(error.localizedDescription)
            }
        }
    }
}
