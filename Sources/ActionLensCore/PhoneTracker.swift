import Foundation

public class PhoneTracker {
    public typealias ActionHandler = (ActionRecord) -> Void
    public typealias ConnectionHandler = (Bool, String) -> Void
    
    private let onAction: ActionHandler
    private let onConnectionChange: ConnectionHandler
    
    private var process: Process?
    private var isRunning: Bool = false
    private var adbPath: String = "/Users/openfrontierlabs/.local/bin/adb"
    
    // Phone Device Characteristics
    public var isConnected: Bool = false
    public var phoneSerial: String = ""
    public var phoneModel: String = "Android Device"
    public var screenWidth: Double = 1220.0
    public var screenHeight: Double = 2712.0
    public var touchMaxX: Double = 19520.0
    public var touchMaxY: Double = 43392.0
    public var currentPhoneApp: String = "Home Screen"
    
    // Touch tracking state machine
    private var isTouching: Bool = false
    private var hasInitialCoords: Bool = false
    private var currentRawX: Double = 0.0
    private var currentRawY: Double = 0.0
    private var touchStartX: Double = 0.0
    private var touchStartY: Double = 0.0
    private var touchStartTime: Date = Date()
    
    // Micro-Biometric Touch Kinetics (Signals 3 - 8)
    private var currentPressure: Double = 0.54
    private var currentTouchMajor: Double = 26.0
    private var currentTouchMinor: Double = 21.0
    private var lastTouchEndTime: Date = Date()
    private var trajectoryPoints: [(x: Double, y: Double, t: Date, p: Double)] = []
    private var hesitationSignChanges: Int = 0
    private var lastVelocityY: Double = 0.0
    private var lastLiveTrailDispatch: Date = Date.distantPast
    
    public var onLiveTrailUpdate: (([TrajectoryPoint], Bool) -> Void)?
    
    private var appCheckTimer: Timer?
    private var reconnectTimer: DispatchSourceTimer?
    
    public init(
        onAction: @escaping ActionHandler,
        onConnectionChange: @escaping ConnectionHandler
    ) {
        self.onAction = onAction
        self.onConnectionChange = onConnectionChange
        findAdb()
    }
    
    private func findAdb() {
        let candidates = [
            "/Users/openfrontierlabs/.local/bin/adb",
            "/usr/local/bin/adb",
            "/opt/homebrew/bin/adb"
        ]
        for c in candidates {
            if FileManager.default.fileExists(atPath: c) {
                adbPath = c
                break
            }
        }
    }
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.discoverAndConnect()
        }
    }
    
    public func stop() {
        isRunning = false
        appCheckTimer?.invalidate()
        appCheckTimer = nil
        
        reconnectTimer?.cancel()
        reconnectTimer = nil
        
        if let p = process, p.isRunning {
            p.terminate()
        }
        process = nil
        isConnected = false
        onConnectionChange(false, "Disconnected")
    }
    
    private func scheduleReconnect() {
        guard isRunning else { return }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.discoverAndConnect()
        }
    }
    
    private func discoverAndConnect() {
        let (output, _) = runAdb(["devices"])
        let lines = output.components(separatedBy: "\n")
        var serial = ""
        for line in lines.dropFirst() {
            let parts = line.split(separator: "\t")
            if parts.count >= 2 && parts[1].trimmingCharacters(in: .whitespacesAndNewlines) == "device" {
                serial = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        guard !serial.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
                self?.onConnectionChange(false, "No ADB Device Found")
            }
            scheduleReconnect()
            return
        }
        
        phoneSerial = serial
        
        // 1. Fetch Model
        let (modelOut, _) = runAdb(["-s", serial, "shell", "getprop", "ro.product.model"])
        let trimmedModel = modelOut.trimmingCharacters(in: .whitespacesAndNewlines)
        phoneModel = trimmedModel.isEmpty ? "Android Phone" : trimmedModel
        
        // 2. Fetch Screen Resolution
        let (wmOut, _) = runAdb(["-s", serial, "shell", "wm", "size"])
        if let match = wmOut.range(of: #"(\d+)x(\d+)"#, options: .regularExpression) {
            let resStr = String(wmOut[match])
            let dims = resStr.split(separator: "x")
            if dims.count == 2, let w = Double(dims[0]), let h = Double(dims[1]) {
                screenWidth = w
                screenHeight = h
            }
        }
        
        // 3. Discover Touch Device and Max Coordinates using getevent -p
        var touchDevice = "/dev/input/event7"
        var bestMaxX = 1080.0
        var bestMaxY = 2400.0
        var highestScore = -1
        
        let (pOut, _) = runAdb(["-s", serial, "shell", "getevent", "-p"])
        let devBlocks = pOut.components(separatedBy: "add device ")
        for block in devBlocks {
            let hasMultiTouch = (block.contains("ABS_MT_POSITION_X") && block.contains("ABS_MT_POSITION_Y")) ||
                                (block.contains("0035") && block.contains("0036"))
            guard hasMultiTouch else { continue }
            
            var score = 5
            if block.contains("INPUT_PROP_DIRECT") { score += 10 }
            let lowerBlock = block.lowercased()
            if lowerBlock.contains("ts") || lowerBlock.contains("touch") || lowerBlock.contains("synaptics") ||
               lowerBlock.contains("goodix") || lowerBlock.contains("focaltech") || lowerBlock.contains("novatek") ||
               lowerBlock.contains("sec_ts") {
                score += 5
            }
            
            if score > highestScore {
                highestScore = score
                if let firstLine = block.components(separatedBy: "\n").first {
                    let cleanedLine = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let colonIdx = cleanedLine.range(of: ":")?.upperBound {
                        let path = String(cleanedLine[colonIdx...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if path.hasPrefix("/dev/input/") {
                            touchDevice = path
                        }
                    }
                }
                
                // Parse Max X
                if let xMatch = block.range(of: #"(?:ABS_MT_POSITION_X|0035)\s*:\s*value\s+\d+,\s*min\s+\d+,\s*max\s+(\d+)"#, options: .regularExpression) {
                    let sub = String(block[xMatch])
                    if let maxPart = sub.components(separatedBy: "max ").last,
                       let val = Double(maxPart.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        bestMaxX = max(val, 500.0)
                    }
                }
                // Parse Max Y
                if let yMatch = block.range(of: #"(?:ABS_MT_POSITION_Y|0036)\s*:\s*value\s+\d+,\s*min\s+\d+,\s*max\s+(\d+)"#, options: .regularExpression) {
                    let sub = String(block[yMatch])
                    if let maxPart = sub.components(separatedBy: "max ").last,
                       let val = Double(maxPart.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        bestMaxY = max(val, 500.0)
                    }
                }
            }
        }
        
        if highestScore > 0 {
            touchMaxX = bestMaxX
            touchMaxY = bestMaxY
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.onConnectionChange(true, "\(self.phoneModel) (\(Int(self.screenWidth))x\(Int(self.screenHeight)))")
            self.startAppFocusPolling()
        }
        
        startStream(touchDevice: touchDevice)
    }
    
    private func startAppFocusPolling() {
        appCheckTimer?.invalidate()
        appCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.queryForegroundApp()
        }
    }
    
    private func queryForegroundApp() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, self.isConnected else { return }
            let (out, _) = self.runAdb(["-s", self.phoneSerial, "shell", "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'"])
            let cleaned = out.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if cleaned.contains("NotificationShade") {
                DispatchQueue.main.async { self.currentPhoneApp = "Notification Shade" }
                return
            }
            
            // Extract package name
            let lines = cleaned.components(separatedBy: "\n")
            for line in lines {
                if let match = line.range(of: #"[a-zA-Z][a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+"#, options: .regularExpression) {
                    let pkg = String(line[match])
                    if !pkg.contains("android.view") && !pkg.contains("com.android.server") {
                        let friendly = self.friendlyAppName(for: pkg)
                        DispatchQueue.main.async {
                            self.currentPhoneApp = friendly
                        }
                        break
                    }
                }
            }
        }
    }
    
    private func friendlyAppName(for package: String) -> String {
        let p = package.lowercased()
        if p.contains("youtube") { return "YouTube" }
        if p.contains("whatsapp") { return "WhatsApp" }
        if p.contains("telegram") { return "Telegram" }
        if p.contains("chrome") { return "Google Chrome" }
        if p.contains("messaging") || p.contains("mms") { return "Messages" }
        if p.contains("settings") { return "Settings" }
        if p.contains("coloros") || p.contains("oppo.launcher") || p.contains("heytap") || p.contains("realme") { return "Realme Home" }
        if p.contains("bbk") || p.contains("vivo") || p.contains("funtouch") || p.contains("originos") { return "Vivo Home" }
        if p.contains("sec.android.app.launcher") || p.contains("samsung") || p.contains("oneui") { return "Samsung Home" }
        if p.contains("miui") || p.contains("xiaomi") || p.contains("home") || p.contains("launcher") { return "Home Screen" }
        if p.contains("spotify") { return "Spotify" }
        if p.contains("instagram") { return "Instagram" }
        if p.contains("twitter") || p.contains(".x.") { return "X (Twitter)" }
        if p.contains("reddit") { return "Reddit" }
        if p.contains("camera") { return "Camera" }
        if p.contains("gallery") { return "Gallery" }
        if p.contains("gm") || p.contains("gmail") { return "Gmail" }
        if p.contains("connectphone") { return "ConnectPhone" }
        
        if let last = package.components(separatedBy: ".").last {
            return last.capitalized
        }
        return package
    }
    
    private func startStream(touchDevice: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: adbPath)
        // Force remote PTY allocation via -t so getevent lines flush immediately
        p.arguments = ["-s", phoneSerial, "shell", "-t", "getevent", "-l", touchDevice]
        
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        
        self.process = p
        
        do {
            try p.run()
        } catch {
            scheduleReconnect()
            return
        }
        
        let fileHandle = pipe.fileHandleForReading
        var buffer = Data()
        
        while isRunning && p.isRunning {
            let data = fileHandle.availableData
            guard !data.isEmpty else { break }
            buffer.append(data)
            
            while let newlineRange = buffer.range(of: Data([0x0A])) { // '\n'
                let lineData = buffer.subdata(in: 0..<newlineRange.lowerBound)
                buffer.removeSubrange(0..<newlineRange.upperBound)
                if let line = String(data: lineData, encoding: .utf8) {
                    parseEventLine(line)
                }
            }
        }
        
        if isRunning {
            scheduleReconnect()
        }
    }
    
    private func parseEventLine(_ rawLine: String) {
        let clean = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        let parts = clean.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
        guard let last = parts.last else { return }
        let hexToken = last.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. Position X (ABS_MT_POSITION_X or hex 0035)
        if clean.contains("ABS_MT_POSITION_X") || (clean.contains("0003") && parts.contains("0035")) {
            if let rawVal = UInt32(hexToken, radix: 16) {
                currentRawX = Double(rawVal)
            }
        }
        // 2. Position Y (ABS_MT_POSITION_Y or hex 0036)
        else if clean.contains("ABS_MT_POSITION_Y") || (clean.contains("0003") && parts.contains("0036")) {
            if let rawVal = UInt32(hexToken, radix: 16) {
                currentRawY = Double(rawVal)
            }
        }
        // 2b. Pressure (ABS_MT_PRESSURE or hex 003a)
        else if clean.contains("ABS_MT_PRESSURE") || (clean.contains("0003") && parts.contains("003a")) {
            if let rawVal = UInt32(hexToken, radix: 16) {
                currentPressure = min(max(Double(rawVal) / 255.0, 0.05), 1.0)
            }
        }
        // 2c. Touch Major Ellipse (ABS_MT_TOUCH_MAJOR or hex 0030)
        else if clean.contains("ABS_MT_TOUCH_MAJOR") || (clean.contains("0003") && parts.contains("0030")) {
            if let rawVal = UInt32(hexToken, radix: 16) {
                currentTouchMajor = max(Double(rawVal), 1.0)
            }
        }
        // 2d. Touch Minor Ellipse (ABS_MT_TOUCH_MINOR or hex 0031)
        else if clean.contains("ABS_MT_TOUCH_MINOR") || (clean.contains("0003") && parts.contains("0031")) {
            if let rawVal = UInt32(hexToken, radix: 16) {
                currentTouchMinor = max(Double(rawVal), 1.0)
            }
        }
        // 3. Tracking ID (ABS_MT_TRACKING_ID or hex 0039)
        else if clean.contains("ABS_MT_TRACKING_ID") || (clean.contains("0003") && parts.contains("0039")) {
            if hexToken == "ffffffff" {
                // Finger lifted (Touch Release)
                if isTouching {
                    handleTouchEnd()
                }
            } else if let _ = UInt32(hexToken, radix: 16) {
                // Finger down (Touch Start)
                handleTouchStart()
            }
        }
        // 3b. BTN_TOUCH fallback (EV_KEY 0001, code 014a / BTN_TOUCH) for older MediaTek / Vivo 1804 / kernel drivers
        else if clean.contains("BTN_TOUCH") || (clean.contains("0001") && parts.contains("014a")) {
            if clean.contains("UP") || hexToken == "00000000" || hexToken == "0" {
                if isTouching {
                    handleTouchEnd()
                }
            } else if clean.contains("DOWN") || hexToken == "00000001" || hexToken == "1" {
                if !isTouching {
                    handleTouchStart()
                }
            }
        }
        // 4. Sync Report: Atomic kernel hardware synchronization barrier
        else if clean.contains("SYN_REPORT") || (clean.contains("0000") && parts.contains("0000")) {
            if isTouching {
                let px = (currentRawX / touchMaxX) * screenWidth
                let py = (currentRawY / touchMaxY) * screenHeight
                if !hasInitialCoords {
                    hasInitialCoords = true
                    touchStartX = px
                    touchStartY = py
                }
                recordTrajectoryPoint(x: px, y: py)
            }
        }
    }
    
    private func recordTrajectoryPoint(x: Double, y: Double) {
        guard isTouching else { return }
        let now = Date()
        if let lastPt = trajectoryPoints.last {
            let dx = x - lastPt.x
            let dy = y - lastPt.y
            let dist = hypot(dx, dy)
            let dt = now.timeIntervalSince(lastPt.t)
            // Synchronized sampling: record when finger moved >= 1.5px or 10ms elapsed
            if dist >= 1.5 || dt >= 0.010 {
                let vy = dy / max(dt, 0.001)
                if (lastVelocityY > 150.0 && vy < -150.0) || (lastVelocityY < -150.0 && vy > 150.0) {
                    hesitationSignChanges += 1
                }
                lastVelocityY = vy
                trajectoryPoints.append((x: x, y: y, t: now, p: currentPressure))
                dispatchLiveTrail(isTouching: true)
            }
        } else {
            trajectoryPoints.append((x: x, y: y, t: now, p: currentPressure))
            dispatchLiveTrail(isTouching: true)
        }
    }
    
    private func dispatchLiveTrail(isTouching: Bool) {
        guard let handler = onLiveTrailUpdate else { return }
        let now = Date()
        if !isTouching || now.timeIntervalSince(lastLiveTrailDispatch) >= 0.016 { // ~60fps
            lastLiveTrailDispatch = now
            let sw = max(screenWidth, 1.0)
            let sh = max(screenHeight, 1.0)
            let t0 = touchStartTime
            let pts = trajectoryPoints.map { pt in
                TrajectoryPoint(
                    x: pt.x,
                    y: pt.y,
                    normalizedX: min(max(pt.x / sw, 0.0), 1.0),
                    normalizedY: min(max(pt.y / sh, 0.0), 1.0),
                    timestampOffsetMs: pt.t.timeIntervalSince(t0) * 1000.0,
                    pressure: pt.p
                )
            }
            DispatchQueue.main.async {
                handler(pts, isTouching)
            }
        }
    }
    
    private func handleTouchStart() {
        isTouching = true
        hasInitialCoords = false
        touchStartX = (currentRawX / touchMaxX) * screenWidth
        touchStartY = (currentRawY / touchMaxY) * screenHeight
        touchStartTime = Date()
        trajectoryPoints = [(x: touchStartX, y: touchStartY, t: touchStartTime, p: currentPressure)]
        hesitationSignChanges = 0
        lastVelocityY = 0.0
        dispatchLiveTrail(isTouching: true)
    }
    
    // MARK: - Advanced Geometric Vertex & Polyline Trajectory Analysis
    public struct TrajectoryAnalysis {
        public let pathPoints: [TrajectoryPoint]
        public let vertices: [TrajectoryVertex]
        public let gestureShape: String
        
        public init(pathPoints: [TrajectoryPoint], vertices: [TrajectoryVertex], gestureShape: String) {
            self.pathPoints = pathPoints
            self.vertices = vertices
            self.gestureShape = gestureShape
        }
    }
    
    private func analyzeTrajectory() -> TrajectoryAnalysis {
        guard !trajectoryPoints.isEmpty else {
            return TrajectoryAnalysis(pathPoints: [], vertices: [], gestureShape: "Linear Swipe")
        }
        
        let t0 = trajectoryPoints.first?.t ?? Date()
        let sw = max(screenWidth, 1.0)
        let sh = max(screenHeight, 1.0)
        
        let fullPath: [TrajectoryPoint] = trajectoryPoints.map { pt in
            TrajectoryPoint(
                x: pt.x,
                y: pt.y,
                normalizedX: min(max(pt.x / sw, 0.0), 1.0),
                normalizedY: min(max(pt.y / sh, 0.0), 1.0),
                timestampOffsetMs: pt.t.timeIntervalSince(t0) * 1000.0,
                pressure: pt.p
            )
        }
        
        if fullPath.count < 3 {
            return TrajectoryAnalysis(pathPoints: fullPath, vertices: [], gestureShape: "Linear Swipe")
        }
        
        // 1. Subsample points with minimum spatial distance (12px) to filter sensor quantization jitter
        var filtered: [TrajectoryPoint] = [fullPath[0]]
        for pt in fullPath.dropFirst() {
            let last = filtered.last!
            let dist = hypot(pt.x - last.x, pt.y - last.y)
            if dist >= 12.0 {
                filtered.append(pt)
            }
        }
        if let lastPt = fullPath.last, hypot(filtered.last!.x - lastPt.x, filtered.last!.y - lastPt.y) > 4.0 {
            filtered.append(lastPt)
        }
        
        var detectedVertices: [TrajectoryVertex] = []
        
        // 2. Scan for Local Extrema in Y (Apex Dips and Peak Crests)
        // Screen coordinates: Y=0 at top, Y increases downwards.
        // A U-shaped swipe curves downward and then climbs back up towards the top.
        // Thus, the bottom apex has maximum Y!
        let startY = fullPath.first!.y
        let endY = fullPath.last!.y
        
        var maxY = -Double.infinity
        var maxIdx = -1
        var minY = Double.infinity
        var minIdx = -1
        
        for (i, pt) in filtered.enumerated() {
            if pt.y > maxY {
                maxY = pt.y
                maxIdx = i
            }
            if pt.y < minY {
                minY = pt.y
                minIdx = i
            }
        }
        
        // U-Shape (Apex Dip): Bottom apex is >= 20px below both start and end
        let dipDepthFromStart = maxY - startY
        let dipDepthFromEnd = maxY - endY
        let isUShape = dipDepthFromStart >= 20.0 && dipDepthFromEnd >= 20.0 && maxIdx > 0 && maxIdx < (filtered.count - 1)
        
        // Arch / Inverted U: Top crest is >= 20px above both start and end (minY is smaller)
        let crestRiseFromStart = startY - minY
        let crestRiseFromEnd = endY - minY
        let isArchShape = crestRiseFromStart >= 20.0 && crestRiseFromEnd >= 20.0 && minIdx > 0 && minIdx < (filtered.count - 1)
        
        // Lateral Extrema for C-Curves (Horizontal U-turns)
        let startX = fullPath.first!.x
        let endX = fullPath.last!.x
        var maxX = -Double.infinity
        var maxXIdx = -1
        var minX = Double.infinity
        var minXIdx = -1
        for (i, pt) in filtered.enumerated() {
            if pt.x > maxX { maxX = pt.x; maxXIdx = i }
            if pt.x < minX { minX = pt.x; minXIdx = i }
        }
        let rightCrestFromStart = maxX - startX
        let rightCrestFromEnd = maxX - endX
        let isRightCShape = rightCrestFromStart >= 20.0 && rightCrestFromEnd >= 20.0 && maxXIdx > 0 && maxXIdx < (filtered.count - 1)
        
        let leftDipFromStart = startX - minX
        let leftDipFromEnd = endX - minX
        let isLeftCShape = leftDipFromStart >= 20.0 && leftDipFromEnd >= 20.0 && minXIdx > 0 && minXIdx < (filtered.count - 1)
        
        if isUShape {
            let apex = filtered[maxIdx]
            detectedVertices.append(
                TrajectoryVertex(
                    x: apex.x,
                    y: apex.y,
                    normalizedX: apex.normalizedX,
                    normalizedY: apex.normalizedY,
                    vertexType: "Apex Dip (U-Turn)",
                    angleDeg: 180.0
                )
            )
        } else if isArchShape {
            let crest = filtered[minIdx]
            detectedVertices.append(
                TrajectoryVertex(
                    x: crest.x,
                    y: crest.y,
                    normalizedX: crest.normalizedX,
                    normalizedY: crest.normalizedY,
                    vertexType: "Peak Crest (Arch)",
                    angleDeg: 180.0
                )
            )
        } else if isRightCShape {
            let apex = filtered[maxXIdx]
            detectedVertices.append(
                TrajectoryVertex(
                    x: apex.x,
                    y: apex.y,
                    normalizedX: apex.normalizedX,
                    normalizedY: apex.normalizedY,
                    vertexType: "Lateral Apex (C-Curve)",
                    angleDeg: 180.0
                )
            )
        } else if isLeftCShape {
            let apex = filtered[minXIdx]
            detectedVertices.append(
                TrajectoryVertex(
                    x: apex.x,
                    y: apex.y,
                    normalizedX: apex.normalizedX,
                    normalizedY: apex.normalizedY,
                    vertexType: "Lateral Apex (Reverse C)",
                    angleDeg: 180.0
                )
            )
        }
        
        // 3. Scan for Angular Turning Vertices (Discrete Curvature & Directional Bends)
        if filtered.count >= 3 {
            for i in 1..<(filtered.count - 1) {
                let pPrev = filtered[i - 1]
                let pCurr = filtered[i]
                let pNext = filtered[i + 1]
                
                let v1x = pCurr.x - pPrev.x
                let v1y = pCurr.y - pPrev.y
                let v2x = pNext.x - pCurr.x
                let v2y = pNext.y - pCurr.y
                
                let mag1 = hypot(v1x, v1y)
                let mag2 = hypot(v2x, v2y)
                
                if mag1 > 6.0 && mag2 > 6.0 {
                    let dot = (v1x * v2x + v1y * v2y) / (mag1 * mag2)
                    let clampedDot = min(max(dot, -1.0), 1.0)
                    let angleDeg = acos(clampedDot) * 180.0 / Double.pi
                    
                    if angleDeg >= 28.0 {
                        // Avoid duplicates if near an existing vertex
                        let alreadyCovered = detectedVertices.contains { v in
                            hypot(v.x - pCurr.x, v.y - pCurr.y) < 28.0
                        }
                        
                        if !alreadyCovered {
                            let vType: String
                            if angleDeg >= 115.0 {
                                vType = "V-Shape Reversal"
                            } else if angleDeg >= 60.0 {
                                vType = "Corner Vertex"
                            } else {
                                vType = "Curved Inflection"
                            }
                            
                            detectedVertices.append(
                                TrajectoryVertex(
                                    x: pCurr.x,
                                    y: pCurr.y,
                                    normalizedX: pCurr.normalizedX,
                                    normalizedY: pCurr.normalizedY,
                                    vertexType: vType,
                                    angleDeg: angleDeg
                                )
                            )
                        }
                    }
                }
            }
        }
        
        // 4. Gesture Shape Classification
        let shape: String
        if isUShape {
            shape = "U-Shape Curve"
        } else if isArchShape {
            shape = "Inverted U / Arch"
        } else if isRightCShape || isLeftCShape {
            shape = "C-Shape Curve"
        } else if detectedVertices.count >= 2 {
            shape = "S-Curve / Zigzag"
        } else if detectedVertices.contains(where: { $0.angleDeg >= 110.0 }) {
            shape = "V-Shape Flick"
        } else if detectedVertices.count == 1 {
            shape = "Curved Sweep"
        } else if hesitationSignChanges > 0 {
            shape = "Hesitation Reversal"
        } else {
            shape = "Linear Swipe"
        }
        
        return TrajectoryAnalysis(pathPoints: fullPath, vertices: detectedVertices, gestureShape: shape)
    }
    
    private func handleTouchEnd() {
        isTouching = false
        hasInitialCoords = false
        dispatchLiveTrail(isTouching: false)
        
        let endX = (currentRawX / touchMaxX) * screenWidth
        let endY = (currentRawY / touchMaxY) * screenHeight
        let now = Date()
        let duration = max(now.timeIntervalSince(touchStartTime), 0.04)
        
        let dx = endX - touchStartX
        let dy = endY - touchStartY
        let distance = sqrt(dx * dx + dy * dy)
        let velocity = distance / duration
        
        // Micro-Biometrics calculation
        let microDwell = min(max(touchStartTime.timeIntervalSince(lastTouchEndTime) * 1000.0, 15.0), 30000.0)
        let surfaceArea = Double.pi * (currentTouchMajor / 2.0) * (currentTouchMinor / 2.0) * 0.045
        
        let posture: String
        if currentTouchMajor < 22.0 {
            posture = "Index Fingertip Precision (High Angle)"
        } else if currentTouchMajor > 36.0 {
            posture = "Flat Thumb Pad (Single-Hand Cradled)"
        } else {
            posture = "Thumb Apex (Dynamic One-Handed)"
        }
        
        var curvatureArc = 0.0
        var jitter = 0.0
        if trajectoryPoints.count >= 3 && distance > 20.0 {
            let chordLen = max(distance, 1.0)
            var maxPerp = 0.0
            var sumPerpSq = 0.0
            for pt in trajectoryPoints {
                let num = abs((endY - touchStartY) * pt.x - (endX - touchStartX) * pt.y + endX * touchStartY - endY * touchStartX)
                let perp = num / chordLen
                if perp > maxPerp { maxPerp = perp }
                sumPerpSq += (perp * perp)
            }
            curvatureArc = min((maxPerp / chordLen) * 57.2958 * 2.0, 89.0)
            jitter = sqrt(sumPerpSq / Double(trajectoryPoints.count))
        }
        
        let touchBio = TouchMicroBiometrics(
            pressure: currentPressure,
            contactMajor: currentTouchMajor,
            contactMinor: currentTouchMinor,
            surfaceAreaMm2: surfaceArea,
            postureHeuristic: posture,
            velocityVectorX: dx / duration,
            velocityVectorY: dy / duration,
            curvatureArcDeg: curvatureArc,
            jitterPx: jitter,
            microDwellLatencyMs: microDwell,
            isHesitationReversal: hesitationSignChanges > 0
        )
        
        HardwareSensorTelemetry.shared.updateTouchKinetics(touchBio)
        lastTouchEndTime = now
        
        let app = currentPhoneApp
        let hardwareSnapshot = HardwareSensorTelemetry.shared.currentState
        let trajectoryAnalysis = analyzeTrajectory()
        
        // Calculate Cumulative Physical Path Length
        var totalPathLength = 0.0
        if trajectoryAnalysis.pathPoints.count >= 2 {
            for i in 1..<trajectoryAnalysis.pathPoints.count {
                let p1 = trajectoryAnalysis.pathPoints[i - 1]
                let p2 = trajectoryAnalysis.pathPoints[i]
                totalPathLength += hypot(p2.x - p1.x, p2.y - p1.y)
            }
        }
        
        // Tap vs Swipe: Tap has minimal cumulative path length (< 40px) and no turning vertices
        let isTap = totalPathLength < 40.0 && trajectoryAnalysis.vertices.isEmpty
        
        if isTap {
            // Direct Tap or Long Press
            let isLongPress = duration > 0.45
            let narrative = NarrativeEngine.shared.narratePhoneTap(
                appName: app,
                x: endX,
                y: endY,
                phoneModel: phoneModel,
                isLongPress: isLongPress,
                biometrics: touchBio
            )
            
            let clickMeta = ActionClickMetadata(
                x: endX,
                y: endY,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                appName: app,
                bundleId: "android.\(app.lowercased())",
                windowTitle: app,
                uiRole: isLongPress ? "Long Press Target" : "Touch Surface",
                uiTitle: app,
                uiDescription: "Android Screen Tap",
                touchBiometrics: touchBio
            )
            
            let record = ActionRecord(
                timestamp: now,
                deviceTarget: .phone,
                type: .phoneTap,
                appName: app,
                windowTitle: app,
                narrativeEnglish: narrative,
                clickMetadata: clickMeta,
                burstMetadata: nil,
                shortcutCombo: nil,
                swipeMetadata: nil,
                hardwareSnapshot: hardwareSnapshot
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.onAction(record)
            }
        } else {
            // Directional or Curved Gesture Swipe
            let direction: SwipeDirection
            if abs(dy) > abs(dx) {
                direction = dy < 0 ? .up : .down
            } else {
                direction = dx < 0 ? .left : .right
            }
            
            let swipe = SwipeMetadata(
                startX: touchStartX,
                startY: touchStartY,
                endX: endX,
                endY: endY,
                direction: direction,
                distance: distance,
                velocity: velocity,
                duration: duration,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                biometrics: touchBio,
                pathPoints: trajectoryAnalysis.pathPoints,
                vertices: trajectoryAnalysis.vertices,
                gestureShape: trajectoryAnalysis.gestureShape
            )
            
            let narrative = NarrativeEngine.shared.narratePhoneSwipe(
                appName: app,
                swipe: swipe,
                phoneModel: phoneModel
            )
            
            let record = ActionRecord(
                timestamp: now,
                deviceTarget: .phone,
                type: .phoneSwipe,
                appName: app,
                windowTitle: app,
                narrativeEnglish: narrative,
                clickMetadata: nil,
                burstMetadata: nil,
                shortcutCombo: nil,
                swipeMetadata: swipe,
                hardwareSnapshot: hardwareSnapshot
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.onAction(record)
            }
        }
    }
    
    private func runAdb(_ args: [String]) -> (String, Int32) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: adbPath)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do {
            try p.run()
            p.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let out = String(data: data, encoding: .utf8) ?? ""
            return (out, p.terminationStatus)
        } catch {
            return ("", -1)
        }
    }
}
