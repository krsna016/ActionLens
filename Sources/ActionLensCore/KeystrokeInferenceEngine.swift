import Cocoa

public class KeystrokeInferenceEngine {
    public typealias ActionHandler = (ActionRecord) -> Void
    public typealias WPMUpdateHandler = (Double, FlowState) -> Void
    public typealias PsychometricUpdateHandler = (PsychometricCognitiveState) -> Void
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let onAction: ActionHandler
    private let onWPMUpdate: WPMUpdateHandler
    public var onPsychometricUpdate: PsychometricUpdateHandler?
    
    // Dedicated low-latency serial queue for all keystroke math, entropy, and burst heuristics
    private let processingQueue = DispatchQueue(label: "com.actionlens.keystroke-engine", qos: .userInteractive)
    
    // Cached frontmost application to avoid blocking IPC calls to WindowServer on key events
    private var cachedAppName: String = "Desktop"
    private var appObserver: Any?
    
    // Typing burst accumulator (accessed strictly on processingQueue)
    private var burstCharCount: Int = 0
    private var burstStartTime: Date?
    private var lastKeyTime: Date?
    private var activeBurstApp: String = ""
    private var backspaceCount: Int = 0
    private var burstFlushWorkItem: DispatchWorkItem?
    private var isRunning: Bool = false
    
    // Micro-biometric timing telemetry (Signals 1 - 2)
    private var keyDownTimestamps: [UInt16: Date] = [:]
    private var lastKeyUpTime: Date? = nil
    private var dwellTimes: [Double] = []
    private var flightTimes: [Double] = []
    private var recentFlightTimes: [Double] = []
    
    // Throttled UI dispatch timestamps to eliminate main-thread RunLoop contention
    private var lastWpmDispatchTime: Date = Date.distantPast
    private var lastPsychometricDispatchTime: Date = Date.distantPast
    
    public init(
        onAction: @escaping ActionHandler,
        onWPMUpdate: @escaping WPMUpdateHandler
    ) {
        self.onAction = onAction
        self.onWPMUpdate = onWPMUpdate
    }
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // Initialize and observe frontmost app without blocking key events
        cachedAppName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Desktop"
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] note in
            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.cachedAppName = app.localizedName ?? "Desktop"
            }
        }
        
        let mask: NSEvent.EventTypeMask = [.keyDown, .keyUp]
        
        // Global monitor (events targeting external windows)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.enqueueEvent(event)
        }
        
        // Local monitor (events targeting ActionLens itself) - returns immediately with 0 latency
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.enqueueEvent(event)
            return event
        }
    }
    
    public func stop() {
        processingQueue.sync { [weak self] in
            self?.flushActiveBurst()
            self?.burstFlushWorkItem?.cancel()
            self?.burstFlushWorkItem = nil
        }
        
        if let g = globalMonitor {
            NSEvent.removeMonitor(g)
            globalMonitor = nil
        }
        if let l = localMonitor {
            NSEvent.removeMonitor(l)
            localMonitor = nil
        }
        if let obs = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            appObserver = nil
        }
        isRunning = false
    }
    
    // Extract immutable primitives immediately so the event monitor can return without waiting
    private func enqueueEvent(_ event: NSEvent) {
        let type = event.type
        let keyCode = event.keyCode
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers
        let app = self.cachedAppName
        let now = Date()
        
        processingQueue.async { [weak self] in
            self?.processKeyEvent(
                type: type,
                keyCode: keyCode,
                flags: flags,
                chars: chars,
                appName: app,
                timestamp: now
            )
        }
    }
    
    private func processKeyEvent(
        type: NSEvent.EventType,
        keyCode: UInt16,
        flags: NSEvent.ModifierFlags,
        chars: String?,
        appName: String,
        timestamp: Date
    ) {
        let now = timestamp
        let windowTitle = appName
        
        // Handle keyUp for dwell time calculation
        if type == .keyUp {
            if let downTime = keyDownTimestamps[keyCode] {
                let dwell = max(now.timeIntervalSince(downTime) * 1000.0, 5.0)
                if dwell < 800.0 {
                    dwellTimes.append(dwell)
                }
                keyDownTimestamps.removeValue(forKey: keyCode)
            }
            lastKeyUpTime = now
            return
        }
        
        // Track inter-key flight time on keyDown
        if let lastUp = lastKeyUpTime {
            let flight = max(now.timeIntervalSince(lastUp) * 1000.0, 5.0)
            if flight < 1200.0 {
                flightTimes.append(flight)
                recentFlightTimes.append(flight)
                if recentFlightTimes.count > 35 {
                    recentFlightTimes.removeFirst()
                }
                computePsychometricEntropy(timestamp: now)
            }
        }
        keyDownTimestamps[keyCode] = now
        
        // Reset idle burst timer asynchronously on processingQueue
        burstFlushWorkItem?.cancel()
        let flushItem = DispatchWorkItem { [weak self] in
            self?.flushActiveBurst()
        }
        burstFlushWorkItem = flushItem
        processingQueue.asyncAfter(deadline: .now() + 1.25, execute: flushItem)
        
        // 1. Check for Command / Control / Option Hotkeys
        let isCmd = flags.contains(.command)
        let isCtrl = flags.contains(.control)
        let isOpt = flags.contains(.option)
        let isShift = flags.contains(.shift)
        
        if isCmd || (isCtrl && !isOpt && !isShift) {
            flushActiveBurst()
            let combo = formatKeyCombo(keyCode: keyCode, chars: chars, isCmd: isCmd, isCtrl: isCtrl, isOpt: isOpt, isShift: isShift)
            let narrative = NarrativeEngine.shared.narrateShortcut(combo: combo, appName: appName)
            
            let record = ActionRecord(
                timestamp: now,
                type: .shortcut,
                appName: appName,
                windowTitle: windowTitle,
                narrativeEnglish: narrative,
                clickMetadata: nil,
                burstMetadata: nil,
                shortcutCombo: combo
            )
            onAction(record)
            return
        }
        
        // 2. Check for Backspace / Delete
        if keyCode == 51 || keyCode == 117 { // 51 = Backspace, 117 = Delete
            backspaceCount += 1
            if burstCharCount > 0 {
                burstCharCount = max(burstCharCount - 1, 0)
            }
            if backspaceCount >= 4 {
                let narrative = NarrativeEngine.shared.narrateDeletion(count: backspaceCount, appName: appName)
                let record = ActionRecord(
                    timestamp: now,
                    type: .keyAction,
                    appName: appName,
                    windowTitle: windowTitle,
                    narrativeEnglish: narrative,
                    clickMetadata: nil,
                    burstMetadata: nil,
                    shortcutCombo: "Backspace"
                )
                onAction(record)
                backspaceCount = 0
            }
            return
        } else {
            if backspaceCount > 0 {
                let narrative = NarrativeEngine.shared.narrateDeletion(count: backspaceCount, appName: appName)
                let record = ActionRecord(
                    timestamp: now,
                    type: .keyAction,
                    appName: appName,
                    windowTitle: windowTitle,
                    narrativeEnglish: narrative,
                    clickMetadata: nil,
                    burstMetadata: nil,
                    shortcutCombo: "Backspace"
                )
                onAction(record)
                backspaceCount = 0
            }
        }
        
        // 3. Check for Return / Enter key
        if keyCode == 36 || keyCode == 76 { // 36 = Return, 76 = Enter
            burstCharCount += 1
            flushActiveBurst(terminator: "Return")
            return
        }
        
        // 4. Check for Escape key
        if keyCode == 53 { // Escape
            flushActiveBurst()
            let record = ActionRecord(
                timestamp: now,
                type: .keyAction,
                appName: appName,
                windowTitle: windowTitle,
                narrativeEnglish: "You hit Escape in \(appName) to dismiss an active prompt or modal.",
                clickMetadata: nil,
                burstMetadata: nil,
                shortcutCombo: "Escape"
            )
            onAction(record)
            return
        }
        
        // 5. Accumulate into active typing burst
        if burstStartTime == nil || (activeBurstApp != appName && !activeBurstApp.isEmpty) {
            flushActiveBurst()
            burstStartTime = now
            activeBurstApp = appName
        }
        
        burstCharCount += 1
        lastKeyTime = now
        
        // Compute instantaneous WPM with 10Hz throttle to prevent main-thread saturation
        if let start = burstStartTime {
            let durationMin = max(now.timeIntervalSince(start) / 60.0, 0.005)
            let currentWPM = (Double(burstCharCount) / 5.0) / durationMin
            let state = classifyFlowState(wpm: currentWPM)
            
            if now.timeIntervalSince(lastWpmDispatchTime) >= 0.1 {
                lastWpmDispatchTime = now
                let boundedWPM = min(currentWPM, 180.0)
                DispatchQueue.main.async { [weak self] in
                    self?.onWPMUpdate(boundedWPM, state)
                }
            }
        }
    }
    
    public func flushActiveBurst(terminator: String? = nil) {
        guard burstCharCount > 0, let start = burstStartTime else {
            burstCharCount = 0
            burstStartTime = nil
            lastKeyTime = nil
            return
        }
        
        let end = lastKeyTime ?? Date()
        let durationSec = max(end.timeIntervalSince(start), 0.3)
        let durationMin = durationSec / 60.0
        let wpm = min((Double(burstCharCount) / 5.0) / max(durationMin, 0.008), 180.0)
        let flow = classifyFlowState(wpm: wpm)
        let app = activeBurstApp.isEmpty ? "your workspace" : activeBurstApp
        
        let avgDwell = dwellTimes.isEmpty ? 58.4 : Double(round((dwellTimes.reduce(0, +) / Double(dwellTimes.count)) * 10) / 10)
        let avgFlight = flightTimes.isEmpty ? 96.2 : Double(round((flightTimes.reduce(0, +) / Double(flightTimes.count)) * 10) / 10)
        let confidence = max(0.1, min(0.99, Double(round((1.0 - abs(avgDwell - 60.0) / 140.0) * 100) / 100)))
        
        let rhythm: String
        if avgDwell < 55.0 {
            rhythm = "Brisk Fluid Cadence"
        } else if avgDwell < 85.0 {
            rhythm = "Steady Rhythmic Cadence"
        } else if avgDwell < 150.0 {
            rhythm = "Hesitant Deliberate Cadence"
        } else {
            rhythm = "Fatigued Staccato Cadence"
        }
        
        let biometrics = KeystrokeMicroBiometrics(
            dwellTimeMs: avgDwell,
            flightTimeMs: avgFlight,
            confidenceScore: confidence,
            neuroMotorRhythm: rhythm
        )
        
        let category = inferCategory(count: burstCharCount, app: app)
        let meta = KeystrokeBurstMetadata(
            charCount: burstCharCount,
            wpm: wpm,
            durationSeconds: durationSec,
            flowState: flow,
            terminatorKey: terminator,
            inferredCategory: category,
            biometrics: biometrics
        )
        
        let englishStory = NarrativeEngine.shared.narrateBurst(metadata: meta, appName: app)
        
        let record = ActionRecord(
            timestamp: end,
            type: .keystrokeBurst,
            appName: app,
            windowTitle: app,
            narrativeEnglish: englishStory,
            clickMetadata: nil,
            burstMetadata: meta,
            shortcutCombo: nil
        )
        
        onAction(record)
        
        DispatchQueue.main.async { [weak self] in
            self?.onWPMUpdate(0.0, .idle)
        }
        
        // Reset state
        burstCharCount = 0
        burstStartTime = nil
        lastKeyTime = nil
        activeBurstApp = ""
        dwellTimes.removeAll()
        flightTimes.removeAll()
    }
    
    // MARK: - Neuro-Cognitive Psychometric Shannon Entropy
    private func computePsychometricEntropy(timestamp: Date) {
        guard recentFlightTimes.count >= 5 else { return }
        
        // Throttle psychometric entropy dispatch to ~6.6Hz (every 150ms)
        guard timestamp.timeIntervalSince(lastPsychometricDispatchTime) >= 0.15 else { return }
        lastPsychometricDispatchTime = timestamp
        
        let n = Double(recentFlightTimes.count)
        
        // 6 Discrete Shannon Entropy Bins
        var bins = [Double](repeating: 0.0, count: 6)
        for f in recentFlightTimes {
            if f < 60.0 { bins[0] += 1.0 }
            else if f < 100.0 { bins[1] += 1.0 }
            else if f < 150.0 { bins[2] += 1.0 }
            else if f < 220.0 { bins[3] += 1.0 }
            else if f < 320.0 { bins[4] += 1.0 }
            else { bins[5] += 1.0 }
        }
        
        var entropy = 0.0
        for count in bins where count > 0 {
            let p = count / n
            entropy -= p * (log(p) / log(2.0))
        }
        
        let roundedEntropy = Double(round(entropy * 100) / 100)
        
        let loadLevel: String
        if roundedEntropy <= 1.45 {
            loadLevel = "Deep Flow State"
        } else if roundedEntropy <= 2.05 {
            loadLevel = "Nominal Focus"
        } else {
            loadLevel = "Cognitive Friction"
        }
        
        // Backspace ratio & Stress Index
        let totalStrokes = max(burstCharCount + backspaceCount, 1)
        let backspaceRatio = Double(backspaceCount) / Double(totalStrokes)
        let stress = min(max(backspaceRatio * 1.4 + (roundedEntropy > 2.0 ? 0.25 : 0.08), 0.05), 0.95)
        let confidence = max(min(100.0 - (roundedEntropy / 2.58) * 45.0 - (backspaceRatio * 40.0), 99.0), 15.0)
        
        let hesitationRatio = Double(recentFlightTimes.filter { $0 > 240.0 }.count) / n
        let avgDwell = dwellTimes.isEmpty ? 58.0 : (dwellTimes.reduce(0, +) / Double(dwellTimes.count))
        let fatigue = min(max(avgDwell / 160.0, 0.05), 1.0)
        
        let state = PsychometricCognitiveState(
            shannonEntropyBits: roundedEntropy,
            cognitiveLoadLevel: loadLevel,
            stressAggressionIndex: Double(round(stress * 100) / 100),
            rhythmicConfidencePct: Double(round(confidence)),
            hesitationDoubtScore: Double(round(hesitationRatio * 100) / 100),
            motorFatigueIndex: Double(round(fatigue * 100) / 100)
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.onPsychometricUpdate?(state)
        }
    }
    
    private func classifyFlowState(wpm: Double) -> FlowState {
        if wpm >= 100 {
            return .sprinting
        } else if wpm >= 75 {
            return .deepFlow
        } else if wpm >= 40 {
            return .steady
        } else if wpm > 0 {
            return .thoughtful
        } else {
            return .idle
        }
    }
    
    private func inferCategory(count: Int, app: String) -> String {
        let appLower = app.lowercased()
        if appLower.contains("terminal") || appLower.contains("iterm") {
            return "Command Execution"
        } else if appLower.contains("code") || appLower.contains("xcode") {
            return "Code Authoring"
        } else if appLower.contains("chrome") || appLower.contains("safari") {
            return "Web Interaction & Search"
        } else if appLower.contains("obsidian") || appLower.contains("notes") {
            return "Note Synthesis"
        } else {
            return count > 30 ? "Prose Composition" : "Short Input"
        }
    }
    
    private func formatKeyCombo(keyCode: UInt16, chars: String?, isCmd: Bool, isCtrl: Bool, isOpt: Bool, isShift: Bool) -> String {
        var parts: [String] = []
        if isCtrl { parts.append("Ctrl") }
        if isOpt { parts.append("Opt") }
        if isShift { parts.append("Shift") }
        if isCmd { parts.append("Cmd") }
        
        let keyChar = chars?.uppercased() ?? ""
        if !keyChar.isEmpty && keyChar != " " {
            parts.append(keyChar)
        } else if keyCode == 49 {
            parts.append("Space")
        } else if keyCode == 36 {
            parts.append("Return")
        } else if keyCode == 48 {
            parts.append("Tab")
        }
        
        return parts.joined(separator: "+")
    }
}