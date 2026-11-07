import Cocoa
import ApplicationServices

public class MouseTracker {
    public typealias ActionHandler = (ActionRecord) -> Void
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let onAction: ActionHandler
    
    private var lastClickTime: Date = Date.distantPast
    private var lastClickPoint: CGPoint = .zero
    private var isRunning: Bool = false
    
    public init(onAction: @escaping ActionHandler) {
        self.onAction = onAction
    }
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        let mask: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .leftMouseDragged
        ]
        
        // Global monitor (events targeting other applications)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleMouseEvent(event)
        }
        
        // Local monitor (events targeting ActionLens itself)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }
    }
    
    public func stop() {
        if let g = globalMonitor {
            NSEvent.removeMonitor(g)
            globalMonitor = nil
        }
        if let l = localMonitor {
            NSEvent.removeMonitor(l)
            localMonitor = nil
        }
        isRunning = false
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        let cocoaPoint = NSEvent.mouseLocation
        let primaryScreen = NSScreen.screens.first ?? NSScreen.main
        let screenHeight = primaryScreen?.frame.height ?? 1080.0
        let screenWidth = primaryScreen?.frame.width ?? 1920.0
        
        // Convert to standard Top-Left origin coordinates for intuitive screen mapping
        let screenX = Double(cocoaPoint.x)
        let screenY = Double(screenHeight - cocoaPoint.y)
        let clickPoint = CGPoint(x: screenX, y: screenY)
        
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName ?? "Desktop"
        let bundleId = frontApp?.bundleIdentifier ?? "com.apple.finder"
        
        // UI Accessibility inspection
        let inspected = AccessibilityInspector.shared.inspect(at: clickPoint)
        let windowTitle = inspected.windowTitle.isEmpty ? (frontApp?.localizedName ?? "") : inspected.windowTitle
        
        var actionType: ActionType = .leftClick
        if event.type == .rightMouseDown {
            actionType = .rightClick
        } else if event.type == .leftMouseDown {
            if event.clickCount >= 2 {
                actionType = .doubleClick
            } else {
                actionType = .leftClick
            }
        } else if event.type == .leftMouseDragged {
            actionType = .drag
        }
        
        let englishStory = NarrativeEngine.shared.narrateClick(
            type: actionType,
            element: inspected,
            appName: appName,
            windowTitle: windowTitle,
            x: screenX,
            y: screenY
        )
        
        let clickMeta = ActionClickMetadata(
            x: screenX,
            y: screenY,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            appName: appName,
            bundleId: bundleId,
            windowTitle: windowTitle,
            uiRole: inspected.role,
            uiTitle: inspected.title,
            uiDescription: inspected.description
        )
        
        let record = ActionRecord(
            timestamp: Date(),
            type: actionType,
            appName: appName,
            windowTitle: windowTitle,
            narrativeEnglish: englishStory,
            clickMetadata: clickMeta,
            burstMetadata: nil,
            shortcutCombo: nil
        )
        
        onAction(record)
    }
}
