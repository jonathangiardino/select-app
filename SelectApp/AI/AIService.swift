import Foundation

/// Runs AI actions by building prompts and dispatching to the routed provider.
final class AIService {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func run(
        kind: AIActionKind,
        input: String,
        targetLanguage: String? = nil,
        detectSourceLanguage: Bool = false
    ) async throws -> String {
        let router = ProviderRouter(settings: settings)
        let provider = try router.provider()
        let language = targetLanguage ?? settings.translationTargetLanguage
        let system = Prompts.system(
            for: kind,
            targetLanguage: language,
            detectSourceLanguage: kind == .translate && detectSourceLanguage
        )
        let user = Prompts.user(for: kind, input: input)
        return try await provider.complete(system: system, user: user)
    }
}
