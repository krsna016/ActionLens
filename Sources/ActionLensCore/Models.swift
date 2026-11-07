import Foundation
import CoreGraphics

public enum DeviceTarget: String, Codable, CaseIterable {
    case mac = "Mac"
    case phone = "Phone"
    
    public var icon: String {
        switch self {
        case .mac: return "laptopcomputer"
        case .phone: return "iphone"
        }
    }
}

public enum SwipeDirection: String, Codable {
    case up = "Swipe Up"
    case down = "Swipe Down"
    case left = "Swipe Left"
    case right = "Swipe Right"
    
    public var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
}

public struct SwipeMetadata: Codable {
    public let startX: Double
    public let startY: Double
    public let endX: Double
    public let endY: Double
    public let direction: SwipeDirection
    public let distance: Double
    public let velocity: Double
    public let duration: Double
    public let normalizedStartX: Double
    public let normalizedStartY: Double
    public let normalizedEndX: Double
    public let normalizedEndY: Double
    
    public init(
        startX: Double,
        startY: Double,
        endX: Double,
        endY: Double,
        direction: SwipeDirection,
        distance: Double,
        velocity: Double,
        duration: Double,
        screenWidth: Double,
        screenHeight: Double
    ) {
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
        self.direction = direction
        self.distance = distance
        self.velocity = velocity
        self.duration = duration
        self.normalizedStartX = min(max(startX / max(screenWidth, 1.0), 0.0), 1.0)
        self.normalizedStartY = min(max(startY / max(screenHeight, 1.0), 0.0), 1.0)
        self.normalizedEndX = min(max(endX / max(screenWidth, 1.0), 0.0), 1.0)
        self.normalizedEndY = min(max(endY / max(screenHeight, 1.0), 0.0), 1.0)
    }
}

public enum ActionType: String, Codable, CaseIterable {
    case leftClick = "Left Click"
    case rightClick = "Right Click"
    case doubleClick = "Double Click"
    case drag = "Mouse Drag"
    case keystrokeBurst = "Typing Burst"
    case shortcut = "Keyboard Shortcut"
    case keyAction = "Key Command"
    case appSwitch = "App Switch"
    case phoneTap = "Phone Tap"
    case phoneSwipe = "Phone Swipe"
    case phoneKey = "Phone Button"
    
    public var icon: String {
        switch self {
        case .leftClick: return "cursorarrow.click.2"
        case .rightClick: return "contextualmenu.and.cursorarrow"
        case .doubleClick: return "hand.tap.2"
        case .drag: return "hand.draw"
        case .keystrokeBurst: return "keyboard"
        case .shortcut: return "command"
        case .keyAction: return "return"
        case .appSwitch: return "macwindow.on.rectangle"
        case .phoneTap: return "hand.tap.fill"
        case .phoneSwipe: return "hand.draw.fill"
        case .phoneKey: return "button.programmable"
        }
    }
}

public enum FlowState: String, Codable {
    case idle = "Idle"
    case thoughtful = "Reflective Cadence"
    case steady = "Steady Composition"
    case deepFlow = "Deep Flow State"
    case sprinting = "Rapid Sprint"
    
    public var badgeColorHex: String {
        switch self {
        case .idle: return "#8E8E93"
        case .thoughtful: return "#64D2FF"
        case .steady: return "#30D158"
        case .deepFlow: return "#FFD60A"
        case .sprinting: return "#FF453A"
        }
    }
}

public struct ActionClickMetadata: Codable {
    public let x: Double
    public let y: Double
    public let screenWidth: Double
    public let screenHeight: Double
    public let normalizedX: Double
    public let normalizedY: Double
    public let appName: String
    public let bundleId: String
    public let windowTitle: String
    public let uiRole: String
    public let uiTitle: String
    public let uiDescription: String
    
    public init(
        x: Double,
        y: Double,
        screenWidth: Double,
        screenHeight: Double,
        appName: String,
        bundleId: String,
        windowTitle: String,
        uiRole: String,
        uiTitle: String,
        uiDescription: String
    ) {
        self.x = x
        self.y = y
        self.screenWidth = max(screenWidth, 1.0)
        self.screenHeight = max(screenHeight, 1.0)
        self.normalizedX = min(max(x / self.screenWidth, 0.0), 1.0)
        self.normalizedY = min(max(y / self.screenHeight, 0.0), 1.0)
        self.appName = appName
        self.bundleId = bundleId
        self.windowTitle = windowTitle
        self.uiRole = uiRole
        self.uiTitle = uiTitle
        self.uiDescription = uiDescription
    }
}

public struct KeystrokeBurstMetadata: Codable {
    public let charCount: Int
    public let wpm: Double
    public let durationSeconds: Double
    public let flowState: FlowState
    public let terminatorKey: String?
    public let inferredCategory: String
    
    public init(
        charCount: Int,
        wpm: Double,
        durationSeconds: Double,
        flowState: FlowState,
        terminatorKey: String?,
        inferredCategory: String
    ) {
        self.charCount = charCount
        self.wpm = wpm
        self.durationSeconds = durationSeconds
        self.flowState = flowState
        self.terminatorKey = terminatorKey
        self.inferredCategory = inferredCategory
    }
}

public struct ActionRecord: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let deviceTarget: DeviceTarget
    public let type: ActionType
    public let appName: String
    public let windowTitle: String
    public let narrativeEnglish: String
    public let clickMetadata: ActionClickMetadata?
    public let burstMetadata: KeystrokeBurstMetadata?
    public let shortcutCombo: String?
    public let swipeMetadata: SwipeMetadata?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        deviceTarget: DeviceTarget = .mac,
        type: ActionType,
        appName: String,
        windowTitle: String,
        narrativeEnglish: String,
        clickMetadata: ActionClickMetadata? = nil,
        burstMetadata: KeystrokeBurstMetadata? = nil,
        shortcutCombo: String? = nil,
        swipeMetadata: SwipeMetadata? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.deviceTarget = deviceTarget
        self.type = type
        self.appName = appName
        self.windowTitle = windowTitle
        self.narrativeEnglish = narrativeEnglish
        self.clickMetadata = clickMetadata
        self.burstMetadata = burstMetadata
        self.shortcutCombo = shortcutCombo
        self.swipeMetadata = swipeMetadata
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SS"
        return formatter.string(from: timestamp)
    }
}
