import Foundation

/// Resolves the concrete `AIProvider` to use based on the selected provider and stored keys.
struct ProviderRouter {
    let settings: AppSettings

    static func keychainAccount(for kind: AIProviderKind) -> String { kind.rawValue }

    func provider() throws -> AIProvider {
        let kind = settings.selectedProvider
        switch kind {
        case .appleFoundation:
            return AppleFoundationProvider()

        case .openAI:
            let key = try requireKey(for: .openAI)
            return OpenAIProvider(apiKey: key, model: settings.openAIModel)

        case .anthropic:
            let key = try requireKey(for: .anthropic)
            return AnthropicProvider(apiKey: key, model: settings.anthropicModel)

        case .gemini:
            let key = try requireKey(for: .gemini)
            return GeminiProvider(apiKey: key, model: settings.geminiModel)

        case .openAICompatible:
            let key = KeychainStore.key(for: Self.keychainAccount(for: .openAICompatible))
            return OpenAICompatibleProvider(
                baseURL: settings.compatibleBaseURL,
                apiKey: key,
                model: settings.compatibleModel
            )
        }
    }

    private func requireKey(for kind: AIProviderKind) throws -> String {
        guard let key = KeychainStore.key(for: Self.keychainAccount(for: kind)), !key.isEmpty else {
            throw AIError.missingAPIKey(kind.displayName)
        }
        return key
    }
}
