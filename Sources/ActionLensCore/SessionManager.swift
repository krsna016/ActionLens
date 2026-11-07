import Cocoa
import Combine

public struct ClickPing: Identifiable {
    public let id = UUID()
    public let x: Double
    public let y: Double
    public let normalizedX: Double
    public let normalizedY: Double
    public let timestamp: Date
    public let appName: String
    public let deviceTarget: DeviceTarget
    
    public init(
        x: Double,
        y: Double,
        normalizedX: Double,
        normalizedY: Double,
        timestamp: Date,
        appName: String,
        deviceTarget: DeviceTarget = .mac
    ) {
        self.x = x
        self.y = y
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.timestamp = timestamp
        self.appName = appName
        self.deviceTarget = deviceTarget
    }
}

public class SessionManager: ObservableObject {
    public static let shared = SessionManager()
    
    // MARK: - Published State for SwiftUI GUI
    @Published public var records: [ActionRecord] = []
    @Published public var totalClicks: Int = 0
    @Published public var totalKeystrokes: Int = 0
    @Published public var totalPhoneTaps: Int = 0
    @Published public var totalPhoneSwipes: Int = 0
    
    @Published public var currentWPM: Double = 0.0
    @Published public var currentFlowState: FlowState = .idle
    @Published public var currentApp: String = "Desktop"
    @Published public var currentWindowTitle: String = ""
    @Published public var isRecording: Bool = true
    @Published public var sessionStory: String = ""
    @Published public var appCounts: [String: Int] = [:]
    @Published public var clickPings: [ClickPing] = []
    @Published public var phoneSwipesList: [SwipeMetadata] = []
    @Published public var livePhoneTrail: [TrajectoryPoint] = []
    @Published public var isPhoneTouching: Bool = false
    
    // Multi-Device Switcher State ("Mac", "Phone", "Unified")
    @Published public var activeDeviceView: String = "Unified"
    @Published public var radarCanvasDevice: String = "Phone"
    @Published public var isPhoneConnected: Bool = false
    @Published public var phoneStatusDescription: String = "Connecting..."
    @Published public var phoneModel: String = "Android Device"
    @Published public var phoneResolution: CGSize = CGSize(width: 1220, height: 2712)
    
    // 45 Granular Telemetry Vectors State
    @Published public var currentSensorState: HardwareSensorState = HardwareSensorState()
    
    // UI Navigation State
    @Published public var selectedFilter: String = "All Events"
    @Published public var searchText: String = ""
    @Published public var isMiniHUD: Bool = false
    @Published public var rightTab: String = "Click Radar"
    @Published public var telemetryMatrixGroup: Int = 0
    @Published public var toastMessage: String? = nil
    
    public let sessionStartTime = Date()
    private var mouseTracker: MouseTracker?
    private var keyEngine: KeystrokeInferenceEngine?
    public var phoneTracker: PhoneTracker?
    private var appSwitchObserver: Any?
    private var storyTimer: Timer?
    private var lastFocusedApp: String = ""
    
    public init() {
        setupEngines()
        setupAppSwitchObserver()
        startStoryTimer()
    }
    
    private func setupEngines() {
        // Mac Trackers
        self.mouseTracker = MouseTracker { [weak self] record in
            DispatchQueue.main.async {
                self?.handleNewRecord(record)
            }
        }
        
        self.keyEngine = KeystrokeInferenceEngine(
            onAction: { [weak self] record in
                DispatchQueue.main.async {
                    self?.handleNewRecord(record)
                }
            },
            onWPMUpdate: { [weak self] wpm, state in
                DispatchQueue.main.async {
                    self?.currentWPM = wpm
                    self?.currentFlowState = state
                }
            }
        )
        
        // Android ADB Phone Tracker
        self.phoneTracker = PhoneTracker(
            onAction: { [weak self] record in
                DispatchQueue.main.async {
                    self?.handleNewRecord(record)
                }
            },
            onConnectionChange: { [weak self] connected, desc in
                DispatchQueue.main.async {
                    self?.isPhoneConnected = connected
                    self?.phoneStatusDescription = desc
                    if let pt = self?.phoneTracker {
                        self?.phoneModel = pt.phoneModel
                        self?.phoneResolution = CGSize(width: pt.screenWidth, height: pt.screenHeight)
                        if connected {
                            HardwareSensorTelemetry.shared.sampleTelemetry(phoneSerial: pt.phoneSerial, adbPath: "/Users/openfrontierlabs/.local/bin/adb")
                        }
                    }
                }
            }
        )
        
        self.phoneTracker?.onLiveTrailUpdate = { [weak self] trail, isTouching in
            DispatchQueue.main.async {
                self?.isPhoneTouching = isTouching
                self?.livePhoneTrail = trail
            }
        }
        
        // 45 Granular Telemetry Vectors Engine
        HardwareSensorTelemetry.shared.onUpdate = { [weak self] state in
            DispatchQueue.main.async {
                self?.currentSensorState = state
            }
        }
        HardwareSensorTelemetry.shared.start()
        
        mouseTracker?.start()
        keyEngine?.start()
        phoneTracker?.start()
    }
    
    private func setupAppSwitchObserver() {
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self = self, self.isRecording else { return }
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            let appName = app.localizedName ?? "Desktop"
            guard appName != self.lastFocusedApp else { return }
            
            let previous = self.lastFocusedApp
            self.lastFocusedApp = appName
            self.currentApp = appName
            
            let narrative = NarrativeEngine.shared.narrateAppSwitch(from: previous, to: appName, windowTitle: appName)
            let record = ActionRecord(
                timestamp: Date(),
                deviceTarget: .mac,
                type: .appSwitch,
                appName: appName,
                windowTitle: appName,
                narrativeEnglish: narrative,
                clickMetadata: nil,
                burstMetadata: nil,
                shortcutCombo: nil,
                swipeMetadata: nil
            )
            self.handleNewRecord(record)
        }
    }
    
    private func startStoryTimer() {
        storyTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.updateSessionStory()
        }
    }
    
    public func handleNewRecord(_ record: ActionRecord) {
        guard isRecording else { return }
        
        let effectiveRecord: ActionRecord
        if record.hardwareSnapshot == nil {
            effectiveRecord = ActionRecord(
                id: record.id,
                timestamp: record.timestamp,
                deviceTarget: record.deviceTarget,
                type: record.type,
                appName: record.appName,
                windowTitle: record.windowTitle,
                narrativeEnglish: record.narrativeEnglish,
                clickMetadata: record.clickMetadata,
                burstMetadata: record.burstMetadata,
                shortcutCombo: record.shortcutCombo,
                swipeMetadata: record.swipeMetadata,
                hardwareSnapshot: currentSensorState
            )
        } else {
            effectiveRecord = record
        }
        
        records.append(effectiveRecord)
        currentApp = effectiveRecord.appName
        currentWindowTitle = effectiveRecord.windowTitle
        
        // Update counters
        switch effectiveRecord.type {
        case .leftClick, .rightClick, .doubleClick:
            totalClicks += 1
            if let click = record.clickMetadata {
                let ping = ClickPing(
                    x: click.x,
                    y: click.y,
                    normalizedX: click.normalizedX,
                    normalizedY: click.normalizedY,
                    timestamp: record.timestamp,
                    appName: record.appName,
                    deviceTarget: .mac
                )
                clickPings.append(ping)
                if clickPings.count > 40 {
                    clickPings.removeFirst()
                }
            }
            
        case .phoneTap:
            totalPhoneTaps += 1
            if let click = record.clickMetadata {
                let ping = ClickPing(
                    x: click.x,
                    y: click.y,
                    normalizedX: click.normalizedX,
                    normalizedY: click.normalizedY,
                    timestamp: record.timestamp,
                    appName: record.appName,
                    deviceTarget: .phone
                )
                clickPings.append(ping)
                if clickPings.count > 40 {
                    clickPings.removeFirst()
                }
            }
            
        case .phoneSwipe:
            totalPhoneSwipes += 1
            if let swipe = record.swipeMetadata {
                phoneSwipesList.append(swipe)
                if phoneSwipesList.count > 25 {
                    phoneSwipesList.removeFirst()
                }
            }
            
        case .keystrokeBurst:
            if let burst = record.burstMetadata {
                totalKeystrokes += burst.charCount
            }
            
        case .keyAction, .shortcut, .phoneKey:
            totalKeystrokes += 1
            
        default:
            break
        }
        
        appCounts[record.appName, default: 0] += 1
        
        // Maintain sensible history limit for smooth 60fps UI
        if records.count > 1200 {
            records.removeFirst(100)
        }
        
        updateSessionStory()
    }
    
    public func updateSessionStory() {
        let elapsed = max(Date().timeIntervalSince(sessionStartTime) / 60.0, 0.1)
        
        let bursts = records.compactMap { $0.burstMetadata }
        let totalBurstChars = bursts.reduce(0) { $0 + $1.charCount }
        let totalBurstTimeMin = bursts.reduce(0.0) { $0 + $1.durationSeconds } / 60.0
        let avgWPM = totalBurstTimeMin > 0 ? (Double(totalBurstChars) / 5.0) / totalBurstTimeMin : currentWPM
        
        self.sessionStory = NarrativeEngine.shared.composeSessionNarrative(
            records: records,
            elapsedMinutes: elapsed,
            appCounts: appCounts,
            avgWPM: avgWPM
        )
    }
    
    public func toggleRecording() {
        isRecording.toggle()
        if !isRecording {
            keyEngine?.flushActiveBurst()
        }
    }
    
    public func clearHistory() {
        records.removeAll()
        clickPings.removeAll()
        phoneSwipesList.removeAll()
        totalClicks = 0
        totalKeystrokes = 0
        totalPhoneTaps = 0
        totalPhoneSwipes = 0
        appCounts.removeAll()
        updateSessionStory()
    }
}
