import ApplicationServices
import AppKit

/// Reads the currently selected text and its on-screen bounds from the focused UI element
/// using the Accessibility API.
enum AXSelection {
    struct Result {
        let text: String
        /// Screen rect in AppKit (bottom-left origin) coordinates, if resolvable.
        let bounds: CGRect?
    }

    static func currentSelection() -> Result? {
        guard AXIsProcessTrusted() else { return nil }

        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let focusedErr = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard focusedErr == .success, let element = focusedElement else { return nil }
        // Safe: element is an AXUIElement returned by the API.
        let axElement = element as! AXUIElement

        // Skip secure text fields (password inputs).
        if isSecure(axElement) { return nil }

        var selectedValue: CFTypeRef?
        let selErr = AXUIElementCopyAttributeValue(
            axElement,
            kAXSelectedTextAttribute as CFString,
            &selectedValue
        )
        guard selErr == .success,
              let text = selectedValue as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        let bounds = selectionBounds(for: axElement)
        return Result(text: text, bounds: bounds)
    }

    private static func isSecure(_ element: AXUIElement) -> Bool {
        var roleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        if let role = roleValue as? String, role == "AXSecureTextField" {
            return true
        }
        var subroleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleValue)
        if let subrole = subroleValue as? String, subrole == "AXSecureTextField" {
            return true
        }
        return false
    }

    /// Attempts to resolve the screen rect of the current selection range.
    private static func selectionBounds(for element: AXUIElement) -> CGRect? {
        var rangeValue: CFTypeRef?
        let rangeErr = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeValue
        )
        guard rangeErr == .success, let rangeValue else { return nil }

        var boundsValue: CFTypeRef?
        let boundsErr = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &boundsValue
        )
        guard boundsErr == .success, let boundsValue else { return nil }

        var rect = CGRect.zero
        // Safe: boundsValue is an AXValue of type CGRect.
        if AXValueGetValue(boundsValue as! AXValue, .cgRect, &rect) {
            return convertToAppKitScreenRect(rect)
        }
        return nil
    }

    /// The Accessibility API returns rects in top-left origin (flipped) global coordinates.
    /// Convert to AppKit bottom-left origin screen coordinates.
    private static func convertToAppKitScreenRect(_ axRect: CGRect) -> CGRect? {
        guard let primary = NSScreen.screens.first else { return nil }
        let maxY = primary.frame.maxY
        return CGRect(
            x: axRect.origin.x,
            y: maxY - axRect.origin.y - axRect.height,
            width: axRect.width,
            height: axRect.height
        )
    }
}
