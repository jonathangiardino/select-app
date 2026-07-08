import Foundation

/// Shared JSON POST helper.
private enum HTTP {
    static func postJSON(
        url: URL,
        headers: [String: String],
        body: [String: Any]
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIError.badResponse("No HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "status \(http.statusCode)"
            throw AIError.badResponse("Request failed (\(http.statusCode)): \(message)")
        }
        return data
    }

    static func value(_ data: Data, path: [Any]) -> String? {
        guard var current: Any = try? JSONSerialization.jsonObject(with: data) else { return nil }
        for component in path {
            if let key = component as? String, let dict = current as? [String: Any] {
                guard let next = dict[key] else { return nil }
                current = next
            } else if let index = component as? Int, let array = current as? [Any] {
                guard array.indices.contains(index) else { return nil }
                current = array[index]
            } else {
                return nil
            }
        }
        return current as? String
    }
}

/// OpenAI Chat Completions (also the base for any OpenAI-compatible endpoint).
struct OpenAICompatibleProvider: AIProvider {
    let baseURL: String
    let apiKey: String?
    let model: String

    func complete(system: String, user: String) async throws -> String {
        guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespaces))?
            .appendingPathComponent("chat/completions") else {
            throw AIError.badResponse("Invalid base URL.")
        }
        var headers: [String: String] = [:]
        if let apiKey, !apiKey.isEmpty {
            headers["Authorization"] = "Bearer \(apiKey)"
        }
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.3,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user],
            ],
        ]
        let data = try await HTTP.postJSON(url: url, headers: headers, body: body)
        guard let content = HTTP.value(data, path: ["choices", 0, "message", "content"]) else {
            throw AIError.emptyResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct OpenAIProvider: AIProvider {
    let apiKey: String
    let model: String

    func complete(system: String, user: String) async throws -> String {
        try await OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: apiKey,
            model: model
        ).complete(system: system, user: user)
    }
}

struct AnthropicProvider: AIProvider {
    let apiKey: String
    let model: String

    func complete(system: String, user: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw AIError.badResponse("Invalid URL.")
        }
        let headers = [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
        ]
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            "messages": [["role": "user", "content": user]],
        ]
        let data = try await HTTP.postJSON(url: url, headers: headers, body: body)
        guard let content = HTTP.value(data, path: ["content", 0, "text"]) else {
            throw AIError.emptyResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct GeminiProvider: AIProvider {
    let apiKey: String
    let model: String

    func complete(system: String, user: String) async throws -> String {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw AIError.badResponse("Invalid URL.")
        }
        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": system]]],
            "contents": [["role": "user", "parts": [["text": user]]]],
        ]
        let data = try await HTTP.postJSON(url: url, headers: [:], body: body)
        guard let content = HTTP.value(data, path: ["candidates", 0, "content", "parts", 0, "text"]) else {
            throw AIError.emptyResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
