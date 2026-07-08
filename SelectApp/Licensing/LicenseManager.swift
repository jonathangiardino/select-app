import Foundation

/// Lifetime license state. This is a scaffold: it stores an activated key and exposes a licensed
/// flag. Wire `validate(key:)` to your store (Gumroad / Lemon Squeezy / Paddle) or to offline
/// signature verification (e.g. Ed25519) when ready.
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    private let defaults = UserDefaults.standard
    private let keyDefaultsKey = "licenseKey"

    @Published private(set) var isLicensed: Bool

    init() {
        let stored = defaults.string(forKey: keyDefaultsKey)
        isLicensed = (stored?.isEmpty == false)
    }

    var storedKey: String? {
        defaults.string(forKey: keyDefaultsKey)
    }

    /// Validate + activate a license key. Replace the placeholder check with a real one.
    func activate(key: String) async -> Result<Void, LicenseError> {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        // TODO: Replace with real online activation or offline signature verification.
        let looksValid = trimmed.count >= 8
        guard looksValid else { return .failure(.invalid) }

        await MainActor.run {
            defaults.set(trimmed, forKey: keyDefaultsKey)
            isLicensed = true
        }
        return .success(())
    }

    func deactivate() {
        defaults.removeObject(forKey: keyDefaultsKey)
        isLicensed = false
    }
}

enum LicenseError: LocalizedError {
    case empty
    case invalid

    var errorDescription: String? {
        switch self {
        case .empty: return "Enter a license key."
        case .invalid: return "That license key doesn't look valid."
        }
    }
}
