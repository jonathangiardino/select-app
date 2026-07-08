import AppKit
import Vision

enum ImageServiceError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "The image could not be read."
        case let .recognitionFailed(message): return message
        }
    }
}

/// On-device text recognition (OCR) using Apple's Vision framework.
final class ImageService {
    func recognizeText(in image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageServiceError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: ImageServiceError.recognitionFailed(error.localizedDescription))
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ImageServiceError.recognitionFailed(error.localizedDescription))
                }
            }
        }
    }
}
