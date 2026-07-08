import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device AI using Apple's Foundation Models (macOS 26+). Falls back to a clear error when
/// unavailable so the router can prompt the user to add a BYOK key.
struct AppleFoundationProvider: AIProvider {
    func complete(system: String, user: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard case .available = model.availability else {
                throw AIError.providerUnavailable(
                    "Apple Intelligence isn't ready on this Mac. Add a provider API key in Settings, or enable Apple Intelligence."
                )
            }
            let session = LanguageModelSession(instructions: system)
            let response = try await session.respond(to: user)
            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if content.isEmpty { throw AIError.emptyResponse }
            return content
        } else {
            throw AIError.providerUnavailable(
                "On-device AI requires macOS 26 or later. Add a provider API key in Settings."
            )
        }
        #else
        throw AIError.providerUnavailable(
            "On-device AI isn't available in this build. Add a provider API key in Settings."
        )
        #endif
    }
}
