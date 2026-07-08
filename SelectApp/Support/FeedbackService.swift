import AppKit
import Foundation

/// Where feedback is sent. Set your address before shipping.
enum FeedbackConfig {
    /// Replace with your support inbox before release.
    static let destinationEmail = "hello@jonathangiardino.com"
}

enum FeedbackKind: String, CaseIterable, Identifiable, GlassSegmentTitleProviding {
    case bug
    case feedback
    case feature

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bug: return "Bug Report"
        case .feedback: return "General Feedback"
        case .feature: return "Feature Request"
        }
    }

    var segmentTitle: String {
        switch self {
        case .bug: return "Bug"
        case .feedback: return "Feedback"
        case .feature: return "Feature"
        }
    }

    var icon: String {
        switch self {
        case .bug: return "ladybug"
        case .feedback: return "text.bubble"
        case .feature: return "lightbulb"
        }
    }

    var prompt: String {
        switch self {
        case .bug: return "What happened? Steps to reproduce help a lot."
        case .feedback: return "Tell us what you think…"
        case .feature: return "What would you like Select to do?"
        }
    }
}

enum FeedbackService {
    /// Opens the default mail client with a pre-filled message.
    @MainActor
    static func send(kind: FeedbackKind, message: String, replyEmail: String) -> Bool {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let os = ProcessInfo.processInfo.operatingSystemVersionString

        var body = trimmed
        body += "\n\n---\n"
        body += "Select \(version) (\(build))\n"
        body += "macOS \(os)\n"
        if !replyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body += "Reply to: \(replyEmail.trimmingCharacters(in: .whitespacesAndNewlines))\n"
        }

        let subject = "[Select \(kind.title)]"
        guard let url = mailtoURL(
            to: FeedbackConfig.destinationEmail,
            subject: subject,
            body: body
        ) else { return false }

        return NSWorkspace.shared.open(url)
    }

    private static func mailtoURL(to email: String, subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}
