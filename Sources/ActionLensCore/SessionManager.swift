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
    @Published public var swipeRenderStyle: String = "Polyline Curve" // "Polyline Curve" (Current) vs "Linear Vector" (Earlier)
    @Published public var isPhoneConnected: Bool = false
    @Published public var phoneStatusDescription: String = "Connecting..."
    @Published public var phoneModel: String = "Android Device"
    @Published public var phoneResolution: CGSize = CGSize(width: 1220, height: 2712)
    
    // 45 Granular Telemetry Vectors State
    @Published public var currentSensorState: HardwareSensorState = HardwareSensorState()
    
    // Advanced Intense Feature Vectors (Features 2, 3, 4, 5, 6, 7)
    @Published public var isHeatmapEnabled: Bool = false
    @Published public var isDigitalTwinEnabled: Bool = false {
        didSet {
            if isDigitalTwinEnabled {
                startDigitalTwinStream()
            } else {
                stopDigitalTwinStream()
            }
        }
    }
    @Published public var isIntentPredictionEnabled: Bool = true
    @Published public var isScrcpyRunning: Bool = false
    private var scrcpyProcess: Process? = nil
    @Published public var phoneTwinImage: NSImage? = nil
    @Published public var twinFrameId: UUID = UUID()
    @Published public var phoneScreenScale: Double = 1.0 // 1.0 = Compact, 1.35 = Large, 1.7 = Cinema
    @Published public var psychometricState: PsychometricCognitiveState = PsychometricCognitiveState()
    @Published public var primaryFocusCentroid: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @Published public var deadZoneCoveragePct: Double = 76.5
    @Published public var activePredictiveIntent: PredictiveIntentVector? = nil
    @Published public var liveAcousticSpectrum: AcousticSpectrumState = AcousticSpectrumState()
    @Published public var rfSpatialMesh: RFSpatialMeshState = RFSpatialMeshState()
    
    // Autonomous Algorithmic Cognitive Twin State (Feature Suite Part 2)
    @Published public var activeCognitiveTwin: CognitiveTwinProfile? = nil
    @Published public var isAutoSimulationEnabled: Bool = false
    @Published public var latestSimulatedActuation: SimulatedActuationEvent? = nil
    @Published public var exportedGraphJSON: String? = nil
    
    // UI Navigation State
    @Published public var selectedFilter: String = "All Events"
    @Published public var feedDisplayMode: String = "Tactical" // "Tactical" vs "Narrative"
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
        
        self.keyEngine?.onPsychometricUpdate = { [weak self] state in
            DispatchQueue.main.async {
                self?.psychometricState = state
            }
        }
        
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
                            HardwareSensorTelemetry.shared.activePhoneSerial = pt.phoneSerial
                            HardwareSensorTelemetry.shared.activeAdbPath = "/Users/openfrontierlabs/.local/bin/adb"
                            HardwareSensorTelemetry.shared.sampleTelemetry(phoneSerial: pt.phoneSerial, adbPath: "/Users/openfrontierlabs/.local/bin/adb")
                        } else {
                            HardwareSensorTelemetry.shared.activePhoneSerial = nil
                        }
                    }
                }
            }
        )
        
        self.phoneTracker?.onLiveTrailUpdate = { [weak self] trail, isTouching in
            DispatchQueue.main.async {
                self?.isPhoneTouching = isTouching
                self?.livePhoneTrail = trail
                if isTouching && trail.count >= 2 {
                    self?.computePredictiveIntent(from: trail)
                }
            }
        }
        
        // 45 Granular Telemetry Vectors Engine & Live Acoustic/RF Meshing
        HardwareSensorTelemetry.shared.onUpdate = { [weak self] state in
            DispatchQueue.main.async {
                self?.currentSensorState = state
                self?.liveAcousticSpectrum = AcousticSpectrumState(
                    ambientDbSpl: state.acousticDecibelDba,
                    peakDbSpl: state.acousticDecibelDba + 14.5,
                    roomAcousticAura: state.acousticAura,
                    spectralBands: [
                        min(max(state.acousticDecibelDba / 90.0 * 0.45 + Double.random(in: -0.05...0.05), 0.05), 1.0),
                        min(max(state.acousticDecibelDba / 90.0 * 0.72 + Double.random(in: -0.05...0.05), 0.1), 1.0),
                        min(max(state.acousticDecibelDba / 90.0 * 0.88 + Double.random(in: -0.05...0.05), 0.15), 1.0),
                        min(max(state.acousticDecibelDba / 90.0 * 0.95 + Double.random(in: -0.05...0.05), 0.2), 1.0),
                        min(max(state.acousticDecibelDba / 90.0 * 0.65 + Double.random(in: -0.05...0.05), 0.1), 1.0),
                        min(max(state.acousticDecibelDba / 90.0 * 0.48 + Double.random(in: -0.05...0.05), 0.05), 1.0),
                        min(max(state.acousticDecibelDba / 90.0 * 0.32 + Double.random(in: -0.05...0.05), 0.05), 1.0),
                        min(max(state.acousticDecibelDba / 90.0 * 0.18 + Double.random(in: -0.05...0.05), 0.02), 1.0)
                    ],
                    voicePitchF0Hz: state.voicePitchFormantsF0,
                    speechPauseHesitationMs: state.speechPauseHesitationMs
                )
                self?.rfSpatialMesh = RFSpatialMeshState(
                    wifiBssid: state.ambientWifiBssid,
                    wifiRssiDbm: state.wifiRssiDbm,
                    signalStrengthTier: state.wifiRssiDbm > -50 ? "Hyper-Local (<1.5m)" : (state.wifiRssiDbm > -70 ? "Room Boundary (2–4m)" : "Peripheral (>5m)"),
                    cellularCgiTac: state.cellularCgiTac,
                    cellularTimingAdvanceRings: state.cellularTimingAdvance,
                    estimatedRadialDistanceM: Double(state.cellularTimingAdvance) * 550.0,
                    bleBeaconUuid: state.bleBeaconUuid,
                    bleProximityDistanceM: 1.8,
                    crossDeviceLookalikeDensity: state.crossDeviceLookalikeProximity
                )
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
                updateSpatialHeatmapCentroid()
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
                updateSpatialHeatmapCentroid()
                if isDigitalTwinEnabled {
                    refreshDigitalTwin()
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
            if isDigitalTwinEnabled {
                refreshDigitalTwin()
            }
            
        case .appSwitch:
            currentApp = effectiveRecord.appName
            if isDigitalTwinEnabled && effectiveRecord.deviceTarget == .phone {
                refreshDigitalTwin()
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
        
        // Ingest into Autonomous User Cognitive Twin Engine (Part 2)
        let bioArc = record.swipeMetadata?.biometrics.curvatureArcDeg ?? 14.2
        let dwell = currentSensorState.keystrokeDwellTimeMs > 0 ? currentSensorState.keystrokeDwellTimeMs : 68.4
        let flight = currentSensorState.keystrokeFlightTimeMs > 0 ? currentSensorState.keystrokeFlightTimeMs : 94.2
        let press = currentSensorState.touchPressureForce > 0 ? currentSensorState.touchPressureForce : 0.54
        
        let profile = UserCognitiveTwinEngine.shared.ingestActuation(
            dwellMs: dwell,
            flightMs: flight,
            pressure: press,
            curvature: bioArc,
            wpm: currentWPM,
            ambientDb: currentSensorState.acousticDecibelDba
        )
        self.activeCognitiveTwin = profile
        
        // Predictive Auto-Actuation Simulation
        if isAutoSimulationEnabled, let intent = activePredictiveIntent {
            self.latestSimulatedActuation = UserCognitiveTwinEngine.shared.simulatePredictiveAutoActuation(
                targetX: intent.projectedTargetX,
                targetY: intent.projectedTargetY,
                confidencePct: intent.trajectoryConfidencePct
            )
        }
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
    
    // MARK: - Advanced Feature Utilities (Digital Twin & Heatmap Centroid)
    public func computePredictiveIntent(from trail: [TrajectoryPoint]) {
        guard isIntentPredictionEnabled, trail.count >= 2 else { return }
        let pCurr = trail[trail.count - 1]
        let pPrev = trail[trail.count - 2]
        
        let dx = Double(pCurr.normalizedX - pPrev.normalizedX)
        let dy = Double(pCurr.normalizedY - pPrev.normalizedY)
        let dist = sqrt(dx * dx + dy * dy)
        guard dist > 0.001 else { return }
        
        // Acceleration / Curvature if 3+ points available
        var ax = 0.0
        var ay = 0.0
        if trail.count >= 3 {
            let pPrev2 = trail[trail.count - 3]
            let dxOld = Double(pPrev.normalizedX - pPrev2.normalizedX)
            let dyOld = Double(pPrev.normalizedY - pPrev2.normalizedY)
            ax = dx - dxOld
            ay = dy - dyOld
        }
        
        // Extrapolate 180ms lead time forward (normalized velocity multiplier ~ 4.2)
        let leadFactor = 4.2
        let targetX = max(0.04, min(0.96, Double(pCurr.normalizedX) + dx * leadFactor + 0.5 * ax * leadFactor))
        let targetY = max(0.04, min(0.96, Double(pCurr.normalizedY) + dy * leadFactor + 0.5 * ay * leadFactor))
        
        let targetZone: String
        if targetY > 0.86 {
            targetZone = "Navigation Dock / Bottom Bar"
        } else if targetY < 0.12 {
            targetZone = "Top Header / Search Bar"
        } else if targetX < 0.18 {
            targetZone = "Left Navigation Rail"
        } else if targetX > 0.82 {
            targetZone = "Right Edge / Scroller"
        } else {
            targetZone = "Central Feed / Action Target"
        }
        
        let angleDeg = atan2(dy, dx) * 180.0 / .pi
        let curvaturePenalty = abs(ax) + abs(ay)
        let confidence = max(42.0, min(97.5, 95.0 - curvaturePenalty * 110.0))
        let velocityEst = dist * 2400.0 // estimated px/sec
        
        self.activePredictiveIntent = PredictiveIntentVector(
            originX: Double(pCurr.normalizedX),
            originY: Double(pCurr.normalizedY),
            projectedTargetX: targetX,
            projectedTargetY: targetY,
            velocityPxPerSec: Double(round(velocityEst)),
            intentionAngleDeg: Double(round(angleDeg * 10) / 10),
            trajectoryConfidencePct: Double(round(confidence * 10) / 10),
            leadTimeMs: 180.0,
            targetZoneLabel: targetZone
        )
    }
    
    private var twinStreamTimer: Timer?
    
    public func startDigitalTwinStream() {
        stopDigitalTwinStream()
        refreshDigitalTwin()
        
        // Continuous live mirror loop running every 0.65s while screen is awake
        twinStreamTimer = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true) { [weak self] _ in
            guard let self = self, self.isDigitalTwinEnabled else { return }
            if let pt = self.phoneTracker, pt.isConnected, pt.isScreenInteractive {
                self.refreshDigitalTwin()
            }
        }
    }
    
    public func stopDigitalTwinStream() {
        twinStreamTimer?.invalidate()
        twinStreamTimer = nil
    }
    
    public func refreshDigitalTwin() {
        guard isDigitalTwinEnabled, let pt = phoneTracker, pt.isConnected else { return }
        pt.captureLiveTwinSnapshot { [weak self] image in
            guard let self = self, let img = image else { return }
            self.phoneTwinImage = img
            self.twinFrameId = UUID()
        }
    }
    
    public func updateSpatialHeatmapCentroid() {
        guard !clickPings.isEmpty else { return }
        let sumX = clickPings.reduce(0.0) { $0 + $1.normalizedX }
        let sumY = clickPings.reduce(0.0) { $0 + $1.normalizedY }
        let count = Double(clickPings.count)
        primaryFocusCentroid = CGPoint(x: sumX / count, y: sumY / count)
        
        let dispX = clickPings.map { abs($0.normalizedX - (sumX / count)) }.reduce(0.0, +) / count
        let dispY = clickPings.map { abs($0.normalizedY - (sumY / count)) }.reduce(0.0, +) / count
        let coverage = min(max((dispX + dispY) * 1.8, 0.12), 0.75)
        deadZoneCoveragePct = Double(round((1.0 - coverage) * 1000) / 10)
    }
    
    // MARK: - Tactical Screen Canvas Flush (Clears Screen Overlays Without Wiping Vector DB)
    public func clearScreenCanvasOverlays() {
        clickPings.removeAll()
        phoneSwipesList.removeAll()
        livePhoneTrail.removeAll()
        activePredictiveIntent = nil
        toastMessage = "Canvas Overlays Flushed • Telemetry Vectors Preserved"
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
    
    // MARK: - scrcpy 60 FPS Hardware-Accelerated Twin Engine
    public func toggleScrcpyTwin() {
        if isScrcpyRunning {
            terminateScrcpyTwin()
        } else {
            launchScrcpyTwin()
        }
    }
    
    public func launchScrcpyTwin() {
        guard let pt = phoneTracker, pt.isConnected, !pt.phoneSerial.isEmpty else {
            toastMessage = "Phone disconnected: Cannot launch scrcpy"
            return
        }
        
        terminateScrcpyTwin()
        
        let scrcpyCandidates = [
            "/Users/openfrontierlabs/.local/bin/scrcpy",
            "/opt/homebrew/bin/scrcpy",
            "/usr/local/bin/scrcpy"
        ]
        guard let binPath = scrcpyCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            toastMessage = "scrcpy binary not found"
            return
        }
        
        let p = Process()
        p.executableURL = URL(fileURLWithPath: binPath)
        p.arguments = [
            "-s", pt.phoneSerial,
            "--window-title=ActionLens Digital Twin (60 FPS Metal)",
            "--always-on-top",
            "--stay-awake",
            "--no-audio",
            "--max-fps=60",
            "--video-bit-rate=4M",
            "--window-width=340"
        ]
        
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isScrcpyRunning = false
                self?.scrcpyProcess = nil
            }
        }
        
        do {
            try p.run()
            self.scrcpyProcess = p
            self.isScrcpyRunning = true
            self.toastMessage = "⚡️ scrcpy 60 FPS Metal Stream Active"
        } catch {
            self.toastMessage = "Failed to launch scrcpy: \(error.localizedDescription)"
        }
    }
    
    public func terminateScrcpyTwin() {
        if let p = scrcpyProcess, p.isRunning {
            p.terminate()
        }
        scrcpyProcess = nil
        isScrcpyRunning = false
    }
    
    // MARK: - Cognitive Twin Export & Simulation Controls
    public func triggerExportPersonaGraph() -> URL? {
        let (url, json) = UserCognitiveTwinEngine.shared.exportPersonaGraphJSON()
        if url != nil {
            self.exportedGraphJSON = json
            self.toastMessage = "Persona Graph (.json) exported successfully"
        }
        return url
    }
    
    public func triggerExportCoreMLWeights() -> URL? {
        let (url, _) = UserCognitiveTwinEngine.shared.exportCoreMLPersonaWeights()
        if url != nil {
            self.toastMessage = "CoreML Neural Weights (.mlmodel) exported"
        }
        return url
    }
    
    public func toggleAutoSimulation() {
        isAutoSimulationEnabled.toggle()
        toastMessage = isAutoSimulationEnabled ? "⚡️ Auto-Actuation Simulation ACTIVE" : "Simulation Mode OFF"
    }
    
    deinit {
        terminateScrcpyTwin()
        stopDigitalTwinStream()
    }
}
