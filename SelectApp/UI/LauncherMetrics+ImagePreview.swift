import AppKit
import CoreGraphics

extension LauncherMetrics {
    /// Interior content width inside the panel inset (matches list row width).
    static var contentWidth: CGFloat { width - panelInset * 2 }

    /// Computes the preview image frame used in the image launcher.
    static func imagePreviewSize(for image: NSImage) -> CGSize {
        let maxWidth = contentWidth
        let maxHeight: CGFloat = 140
        let minHeight: CGFloat = 44
        let size = image.size
        guard size.width > 0, size.height > 0 else {
            return CGSize(width: min(maxWidth, 160), height: minHeight)
        }

        let aspect = size.width / size.height

        if aspect >= 1.4 {
            let fittedWidth = maxWidth
            let height = max(minHeight, min(maxHeight, fittedWidth / aspect))
            return CGSize(width: fittedWidth, height: height)
        }
        if aspect <= 0.75 {
            let height = maxHeight
            let fittedWidth = min(maxWidth, height * aspect)
            return CGSize(width: fittedWidth, height: height)
        }
        let side = min(maxWidth, maxHeight)
        return CGSize(width: side, height: side)
    }

    static func imagePreviewHeight(for image: NSImage) -> CGFloat {
        imagePreviewSize(for: image).height
    }
}
