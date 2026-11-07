import Foundation

public class NarrativeEngine {
    public static let shared = NarrativeEngine()
    
    private init() {}
    
    // MARK: - Mac Click Narration
    public func narrateClick(
        type: ActionType,
        element: InspectedUIElement,
        appName: String,
        windowTitle: String,
        x: Double,
        y: Double
    ) -> String {
        let app = appName.isEmpty ? "your active application" : appName
        let coords = "(\(Int(x)), \(Int(y)))"
        let effectiveTitle = !element.title.isEmpty ? element.title : element.description
        let cleanWindow = (!windowTitle.isEmpty && windowTitle != appName) ? " [\(windowTitle)]" : ""
        
        switch type {
        case .leftClick:
            if !effectiveTitle.isEmpty {
                switch element.role.lowercased() {
                case "button":
                    return "You clicked the '\(effectiveTitle)' button in \(app)\(cleanWindow) at \(coords)."
                case "hyperlink", "link":
                    return "You navigated by clicking the link '\(effectiveTitle)' in \(app) at \(coords)."
                case "text field", "multi-line text area":
                    return "You placed your cursor into the '\(effectiveTitle)' text input in \(app)\(cleanWindow) to begin writing."
                case "tab":
                    return "You switched tabs to '\(effectiveTitle)' inside \(app)."
                case "menu item":
                    return "You selected the '\(effectiveTitle)' menu action in \(app)."
                case "checkbox":
                    return "You toggled the '\(effectiveTitle)' checkbox in \(app)."
                case "dropdown selector", "combo box":
                    return "You opened the '\(effectiveTitle)' selection dropdown in \(app)."
                default:
                    return "You clicked on the '\(effectiveTitle)' \(element.role) in \(app)\(cleanWindow) at \(coords)."
                }
            } else {
                if element.role.lowercased().contains("text") {
                    return "You clicked inside an active text editing surface in \(app)\(cleanWindow) at \(coords)."
                } else if element.role.lowercased().contains("window") || element.role.lowercased().contains("container") {
                    return "You clicked the workspace canvas in \(app)\(cleanWindow) at coordinates \(coords)."
                } else {
                    return "You clicked the \(element.role) area in \(app)\(cleanWindow) at \(coords)."
                }
            }
            
        case .rightClick:
            let target = !effectiveTitle.isEmpty ? "'\(effectiveTitle)' \(element.role)" : "\(element.role) at \(coords)"
            return "You right-clicked on \(target) in \(app)\(cleanWindow) to inspect the contextual menu."
            
        case .doubleClick:
            let target = !effectiveTitle.isEmpty ? "'\(effectiveTitle)'" : "element at \(coords)"
            return "You double-clicked on \(target) in \(app)\(cleanWindow) to select text or trigger primary activation."
            
        case .drag:
            return "You dragged the pointer across \(app)\(cleanWindow), repositioning cursor to \(coords)."
            
        default:
            return "You interacted with \(app) at coordinates \(coords)."
        }
    }
    
    // MARK: - Phone Taps & Swipes Narration
    public func narratePhoneTap(
        appName: String,
        x: Double,
        y: Double,
        phoneModel: String,
        isLongPress: Bool
    ) -> String {
        let phoneTag = phoneModel.isEmpty ? "Phone" : "Phone (\(phoneModel))"
        let coords = "(\(Int(x)), \(Int(y)))"
        let app = appName.isEmpty ? "the active screen" : appName
        
        if isLongPress {
            return "On your \(phoneTag), you long-pressed at \(coords) inside \(app) to summon context options."
        } else {
            return "On your \(phoneTag), you tapped at \(coords) inside \(app)."
        }
    }
    
    public func narratePhoneSwipe(
        appName: String,
        swipe: SwipeMetadata,
        phoneModel: String
    ) -> String {
        let phoneTag = phoneModel.isEmpty ? "Phone" : "Phone (\(phoneModel))"
        let app = appName.isEmpty ? "the screen" : appName
        let dist = Int(swipe.distance)
        let vel = Int(swipe.velocity)
        
        switch swipe.direction {
        case .up:
            return "On your \(phoneTag), you performed an upward swipe (\(dist) px at ~\(vel) px/s) to scroll down your feed in \(app)."
        case .down:
            return "On your \(phoneTag), you swiped downward (\(dist) px) in \(app) to scroll up or trigger pull-to-refresh."
        case .left:
            return "On your \(phoneTag), you performed a leftward swipe (\(dist) px) in \(app) to advance forward or switch tabs."
        case .right:
            return "On your \(phoneTag), you swiped right (\(dist) px) in \(app) to navigate back to the previous screen."
        }
    }
    
    public func narratePhoneKey(
        keyName: String,
        phoneModel: String
    ) -> String {
        let phoneTag = phoneModel.isEmpty ? "Phone" : "Phone (\(phoneModel))"
        return "On your \(phoneTag), you pressed the physical [\(keyName)] button."
    }
    
    // MARK: - Keystroke Burst Narration
    public func narrateBurst(
        metadata: KeystrokeBurstMetadata,
        appName: String
    ) -> String {
        let app = appName.isEmpty ? "your active window" : appName
        let roundedWpm = Int(metadata.wpm)
        let chars = metadata.charCount
        
        if let term = metadata.terminatorKey, term == "Return" {
            if chars <= 15 {
                return "In \(app), you entered a short command (\(chars) chars) and committed it with Return."
            } else {
                return "In \(app), you composed an energetic \(chars)-character statement (~\(roundedWpm) WPM) and pressed Return to execute."
            }
        }
        
        switch metadata.flowState {
        case .sprinting:
            return "You entered a high-speed sprint of \(chars) characters at a blistering \(roundedWpm) WPM inside \(app)."
        case .deepFlow:
            return "You sustained an uninterrupted deep writing flow (\(chars) chars, ~\(roundedWpm) WPM) in \(app)."
        case .steady:
            return "You drafted a fluent \(chars)-character sequence at a steady cadence of \(roundedWpm) WPM in \(app)."
        case .thoughtful:
            return "You deliberately composed \(chars) characters with contemplative pauses (~\(roundedWpm) WPM) in \(app)."
        case .idle:
            return "You typed \(chars) characters in \(app)."
        }
    }
    
    // MARK: - Shortcut & Key Command Narration
    public func narrateShortcut(
        combo: String,
        appName: String
    ) -> String {
        let app = appName.isEmpty ? "the active window" : appName
        let upper = combo.uppercased()
        
        if upper.contains("CMD+C") {
            return "You pressed Cmd+C in \(app) to copy selected text to the macOS clipboard."
        } else if upper.contains("CMD+V") {
            return "You pressed Cmd+V in \(app) to paste content from clipboard into the document."
        } else if upper.contains("CMD+X") {
            return "You pressed Cmd+X in \(app) to cut selected content to the clipboard."
        } else if upper.contains("CMD+Z") {
            if upper.contains("SHIFT") {
                return "You performed a Redo operation (Cmd+Shift+Z) inside \(app)."
            }
            return "You performed an Undo operation (Cmd+Z) inside \(app) to revert recent changes."
        } else if upper.contains("CMD+S") {
            return "You saved modifications in \(app) using Cmd+S."
        } else if upper.contains("CMD+SPACE") || upper.contains("OPT+SPACE") {
            return "You summoned system search / application launcher using \(combo)."
        } else if upper.contains("CMD+W") {
            return "You closed the active tab or window in \(app) via Cmd+W."
        } else if upper.contains("CMD+T") {
            return "You spawned a new browser or editor tab via Cmd+T in \(app)."
        } else if upper.contains("CMD+F") {
            return "You invoked the in-app search query panel using Cmd+F in \(app)."
        } else if upper.contains("CMD+A") {
            return "You selected all contents in \(app) with Cmd+A."
        } else if upper.contains("CMD+TAB") {
            return "You navigated between active tasks using the macOS application switcher (Cmd+Tab)."
        } else {
            return "You executed keyboard shortcut [\(combo)] within \(app)."
        }
    }
    
    public func narrateDeletion(count: Int, appName: String) -> String {
        let app = appName.isEmpty ? "the active application" : appName
        if count == 1 {
            return "You tapped Backspace in \(app) to remove a character."
        } else {
            return "You executed a quick text refinement, erasing \(count) characters with Backspace in \(app)."
        }
    }
    
    public func narrateAppSwitch(from: String, to: String, windowTitle: String) -> String {
        let cleanWin = !windowTitle.isEmpty && windowTitle != to ? " focusing window '\(windowTitle)'" : ""
        if from.isEmpty || from == to {
            return "You brought \(to) into active frontmost focus\(cleanWin)."
        }
        return "You switched your attention from \(from) over to \(to)\(cleanWin)."
    }
    
    // MARK: - Cumulative Story Generation
    public func composeSessionNarrative(
        records: [ActionRecord],
        elapsedMinutes: Double,
        appCounts: [String: Int],
        avgWPM: Double
    ) -> String {
        guard !records.isEmpty else {
            return "The session has just initialized. ActionLens is monitoring both your Mac and connected Android phone in real time; interact with either device to see the live chronicle unfold."
        }
        
        let totalActions = records.count
        let macRecords = records.filter { $0.deviceTarget == .mac }
        let phoneRecords = records.filter { $0.deviceTarget == .phone }
        
        let clicks = macRecords.filter { $0.type == .leftClick || $0.type == .rightClick || $0.type == .doubleClick }.count
        let bursts = macRecords.filter { $0.type == .keystrokeBurst }.count
        let shortcuts = macRecords.filter { $0.type == .shortcut }.count
        
        let phoneTaps = phoneRecords.filter { $0.type == .phoneTap }.count
        let phoneSwipes = phoneRecords.filter { $0.type == .phoneSwipe }.count
        
        let sortedApps = appCounts.sorted { $0.value > $1.value }
        let topApp = sortedApps.first?.key ?? "the primary workspace"
        let topAppPercent = totalActions > 0 && !(sortedApps.first?.value == nil)
            ? Int((Double(sortedApps.first!.value) / Double(totalActions)) * 100.0)
            : 0
        
        let timeStr = elapsedMinutes < 1.0 ? "the opening minute" : "\(Int(elapsedMinutes)) minutes"
        
        var narrative = "Over \(timeStr) of interaction, you completed \(totalActions) total operations. "
        
        if !macRecords.isEmpty && !phoneRecords.isEmpty {
            narrative += "Your workflow seamlessly spanned both your **Mac** (\(macRecords.count) actions: \(clicks) clicks, \(bursts) typing bursts) and your **Android Phone** (\(phoneRecords.count) actions: \(phoneTaps) taps, \(phoneSwipes) touch swipes). "
        } else if !phoneRecords.isEmpty {
            narrative += "Your interactions were concentrated on your **Android Phone**, where you performed \(phoneTaps) direct taps and \(phoneSwipes) directional swipes. "
        } else {
            narrative += "Your activity was focused on your **Mac**, comprising \(clicks) mouse clicks, \(bursts) continuous typing sprints, and \(shortcuts) hotkeys. "
        }
        
        narrative += "Your primary locus of engagement was **\(topApp)**, accounting for approximately \(topAppPercent)% of total interactions. "
        
        if avgWPM > 10.0 {
            narrative += "Your Mac text composition maintained a typing velocity of **\(Int(avgWPM)) WPM**. "
        }
        
        if sortedApps.count > 1 {
            let secondaryApps = sortedApps.dropFirst().prefix(2).map { $0.key }.joined(separator: " and ")
            narrative += "Cross-device transitions occurred smoothly between \(topApp) and \(secondaryApps)."
        }
        
        return narrative
    }
}
