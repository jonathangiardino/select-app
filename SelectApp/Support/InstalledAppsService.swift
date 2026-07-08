import AppKit

/// Discovers `.app` bundles under standard application folders for settings pickers.
enum InstalledAppsService {
    struct InstalledApp: Identifiable, Hashable {
        var id: String { bundleID }
        let bundleID: String
        let name: String
        let icon: NSImage
        let path: URL
    }

    private static let applicationDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
    ]

    private static var cachedApps: [InstalledApp]?
    private static let cacheLock = NSLock()

    /// Returns installed apps sorted by name, reusing an in-memory cache unless `forceRefresh` is set.
    static func installedApps(forceRefresh: Bool = false) -> [InstalledApp] {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if !forceRefresh, let cachedApps {
            return cachedApps
        }

        var byBundleID: [String: InstalledApp] = [:]
        for directory in applicationDirectories where FileManager.default.fileExists(atPath: directory.path) {
            for appURL in discoverApps(in: directory) {
                guard let bundle = Bundle(url: appURL),
                      let bundleID = bundle.bundleIdentifier,
                      !bundleID.isEmpty
                else { continue }

                // Prefer the copy in /Applications when the same bundle exists in both folders.
                if byBundleID[bundleID] != nil,
                   appURL.path.hasPrefix("/Applications") == false {
                    continue
                }

                let name = displayName(for: bundle, appURL: appURL)
                byBundleID[bundleID] = InstalledApp(
                    bundleID: bundleID,
                    name: name,
                    icon: NSWorkspace.shared.icon(forFile: appURL.path),
                    path: appURL
                )
            }
        }

        let apps = byBundleID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        cachedApps = apps
        return apps
    }

    static func searchInstalledApps(matching query: String, limit: Int = 15) -> [InstalledApp] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let needle = trimmed.lowercased()
        return installedApps()
            .filter {
                $0.name.lowercased().contains(needle) || $0.bundleID.lowercased().contains(needle)
            }
            .prefix(limit)
            .map { $0 }
    }

    static func installedApp(forBundleID bundleID: String) -> InstalledApp? {
        installedApps().first { $0.bundleID == bundleID }
    }

    /// Resolves a display name for a bundle ID, using the installed-apps cache or Launch Services.
    static func displayName(forBundleID bundleID: String) -> String {
        if let app = installedApp(forBundleID: bundleID) {
            return app.name
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url) {
            return displayName(for: bundle, appURL: url)
        }
        return bundleID
    }

    static func icon(forBundleID bundleID: String) -> NSImage {
        if let app = installedApp(forBundleID: bundleID) {
            return app.icon
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }

    // MARK: - Discovery

    private static func discoverApps(in directory: URL) -> [URL] {
        guard let topLevel = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var apps: [URL] = []
        for url in topLevel {
            if url.pathExtension == "app" {
                apps.append(url)
                continue
            }
            guard isDirectory(url) else { continue }
            // One level deep covers folders like Setapp without scanning the whole disk.
            if let nested = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                apps.append(contentsOf: nested.filter { $0.pathExtension == "app" })
            }
        }
        return apps
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private static func displayName(for bundle: Bundle, appURL: URL) -> String {
        if let display = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !display.isEmpty {
            return display
        }
        if let name = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String,
           !name.isEmpty {
            return name
        }
        return appURL.deletingPathExtension().lastPathComponent
    }
}
