import Cocoa
import ApplicationServices

public struct InspectedUIElement {
    public let role: String
    public let title: String
    public let description: String
    public let value: String
    public let windowTitle: String
    public let isSecure: Bool
    
    public init(
        role: String = "Canvas",
        title: String = "",
        description: String = "",
        value: String = "",
        windowTitle: String = "",
        isSecure: Bool = false
    ) {
        self.role = role
        self.title = title
        self.description = description
        self.value = value
        self.windowTitle = windowTitle
        self.isSecure = isSecure
    }
}

public class AccessibilityInspector {
    public static let shared = AccessibilityInspector()
    
    private let systemWideElement: AXUIElement
    
    private init() {
        self.systemWideElement = AXUIElementCreateSystemWide()
    }
    
    public func inspect(at screenPoint: CGPoint) -> InspectedUIElement {
        var rawElement: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWideElement, Float(screenPoint.x), Float(screenPoint.y), &rawElement)
        
        guard result == .success, let element = rawElement else {
            return fallbackInspect()
        }
        
        let role = copyStringAttribute(element, attribute: kAXRoleAttribute as CFString) ?? "AXUnknown"
        let roleDesc = copyStringAttribute(element, attribute: kAXRoleDescriptionAttribute as CFString)
        let title = copyStringAttribute(element, attribute: kAXTitleAttribute as CFString) ?? ""
        let description = copyStringAttribute(element, attribute: kAXDescriptionAttribute as CFString) ?? ""
        let rawVal = copyStringAttribute(element, attribute: kAXValueAttribute as CFString) ?? ""
        
        // Window Title resolution
        var winTitle = ""
        var current: AXUIElement? = element
        for _ in 0..<6 {
            guard let cur = current else { break }
            var parentRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(cur, kAXRoleAttribute as CFString, &parentRef) == .success,
               let pRole = parentRef as? String, pRole == (kAXWindowAttribute as String) || pRole == "AXWindow" {
                winTitle = copyStringAttribute(cur, attribute: kAXTitleAttribute as CFString) ?? ""
                break
            }
            var windowRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(cur, kAXWindowAttribute as CFString, &windowRef) == .success,
               let win = windowRef {
                let winElem = win as! AXUIElement
                winTitle = copyStringAttribute(winElem, attribute: kAXTitleAttribute as CFString) ?? ""
                break
            }
            var upRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(cur, kAXParentAttribute as CFString, &upRef) == .success,
               let parent = upRef {
                current = (parent as! AXUIElement)
            } else {
                break
            }
        }
        
        let friendlyRole = humanReadableRole(rawRole: role, roleDescription: roleDesc)
        let isSecure = role == "AXSecureTextField" || role.lowercased().contains("password")
        
        return InspectedUIElement(
            role: friendlyRole,
            title: title,
            description: description,
            value: isSecure ? "[Secure Input]" : rawVal,
            windowTitle: winTitle,
            isSecure: isSecure
        )
    }
    
    private func fallbackInspect() -> InspectedUIElement {
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName ?? "Desktop"
        return InspectedUIElement(
            role: "Workspace Area",
            title: appName,
            description: "",
            value: "",
            windowTitle: appName,
            isSecure: false
        )
    }
    
    private func copyStringAttribute(_ element: AXUIElement, attribute: CFString) -> String? {
        var valueRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute, &valueRef)
        guard err == .success, let val = valueRef else { return nil }
        if let str = val as? String {
            return str
        } else if let num = val as? NSNumber {
            return num.stringValue
        }
        return nil
    }
    
    private func humanReadableRole(rawRole: String, roleDescription: String?) -> String {
        if let desc = roleDescription, !desc.isEmpty {
            return desc.capitalized
        }
        switch rawRole {
        case "AXButton": return "Button"
        case "AXTextField": return "Text Field"
        case "AXSecureTextField": return "Secure Password Field"
        case "AXTextArea": return "Multi-line Text Area"
        case "AXLink": return "Hyperlink"
        case "AXPopUpButton": return "Dropdown Selector"
        case "AXComboBox": return "Combo Box"
        case "AXCheckBox": return "Checkbox"
        case "AXRadioButton": return "Radio Option"
        case "AXTabGroup", "AXTab": return "Tab"
        case "AXMenuItem": return "Menu Item"
        case "AXMenuBar": return "Menu Bar"
        case "AXScrollArea": return "Scroll Area"
        case "AXScrollBar": return "Scrollbar"
        case "AXImage": return "Image"
        case "AXGroup": return "Interface Container"
        case "AXWindow": return "Window Canvas"
        case "AXRow", "AXCell": return "Table Row"
        default:
            return rawRole.replacingOccurrences(of: "AX", with: "")
        }
    }
}
