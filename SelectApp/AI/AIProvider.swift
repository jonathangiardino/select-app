import Foundation

enum AIError: LocalizedError {
    case missingAPIKey(String)
    case providerUnavailable(String)
    case badResponse(String)
    case emptyResponse
    case translationFailed

    var errorDescription: String? { userMessage }

    var userMessage: String {
        switch self {
        case let .missingAPIKey(provider):
            return "No API key set for \(provider). Add one in Settings, or switch to on-device AI."
        case let .providerUnavailable(message):
            return message
        case let .badResponse(message):
            return message
        case .emptyResponse:
            return "The AI returned an empty response."
        case .translationFailed:
            return "Translation failed. Try again or switch to a different AI provider in Settings."
        }
    }
}

/// A text-in/text-out chat provider.
protocol AIProvider {
    func complete(system: String, user: String) async throws -> String
}
