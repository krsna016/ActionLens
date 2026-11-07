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

// MARK: - Micro-Biometric Touch Kinetics (Signals 3 - 8)
public struct TouchMicroBiometrics: Codable {
    public let pressure: Double            // Signal 3: 0.0 to 1.0 (ABS_MT_PRESSURE)
    public let contactMajor: Double        // Contact ellipse major axis in px (ABS_MT_TOUCH_MAJOR)
    public let contactMinor: Double        // Contact ellipse minor axis in px (ABS_MT_TOUCH_MINOR)
    public let surfaceAreaMm2: Double      // Signal 4: Calculated physical contact area in mm^2
    public let postureHeuristic: String    // Signal 4: "Fingertip Precision", "Flat Thumb Pad", "Dual Thumb Stance"
    public let velocityVectorX: Double     // Signal 5: Linear X velocity (px/s)
    public let velocityVectorY: Double     // Signal 5: Linear Y velocity (px/s)
    public let curvatureArcDeg: Double     // Signal 6: Trajectory arc curvature angle (thumb joint bio-arc)
    public let jitterPx: Double            // Signal 6: Trajectory orthogonal tremor / jitter deviation
    public let microDwellLatencyMs: Double // Signal 7: Viewport pause interval (500ms - 1200ms latent interest)
    public let isHesitationReversal: Bool  // Signal 8: Scroll turbulence directional back-flip
    
    public init(
        pressure: Double = 0.52,
        contactMajor: Double = 26.0,
        contactMinor: Double = 21.0,
        surfaceAreaMm2: Double = 42.8,
        postureHeuristic: String = "Fingertip Precision",
        velocityVectorX: Double = 0.0,
        velocityVectorY: Double = 0.0,
        curvatureArcDeg: Double = 11.4,
        jitterPx: Double = 1.2,
        microDwellLatencyMs: Double = 680.0,
        isHesitationReversal: Bool = false
    ) {
        self.pressure = pressure
        self.contactMajor = contactMajor
        self.contactMinor = contactMinor
        self.surfaceAreaMm2 = surfaceAreaMm2
        self.postureHeuristic = postureHeuristic
        self.velocityVectorX = velocityVectorX
        self.velocityVectorY = velocityVectorY
        self.curvatureArcDeg = curvatureArcDeg
        self.jitterPx = jitterPx
        self.microDwellLatencyMs = microDwellLatencyMs
        self.isHesitationReversal = isHesitationReversal
    }
}

// MARK: - Micro-Biometric Keystroke Dynamics (Signals 1 - 2)
public struct KeystrokeMicroBiometrics: Codable {
    public let dwellTimeMs: Double        // Signal 1: Key press down-to-up contact time (ms)
    public let flightTimeMs: Double       // Signal 2: Inter-key latency between previous up and current down (ms)
    public let confidenceScore: Double    // Confidence / stress index (0.0 to 1.0)
    public let neuroMotorRhythm: String   // "Brisk Fluid", "Steady Rhythmic", "Hesitant Deliberate", "Fatigued Staccato"
    
    public init(
        dwellTimeMs: Double = 58.4,
        flightTimeMs: Double = 96.2,
        confidenceScore: Double = 0.94,
        neuroMotorRhythm: String = "Steady Rhythmic"
    ) {
        self.dwellTimeMs = dwellTimeMs
        self.flightTimeMs = flightTimeMs
        self.confidenceScore = confidenceScore
        self.neuroMotorRhythm = neuroMotorRhythm
    }
}

// MARK: - Comprehensive 45 Telemetry Vectors Snapshot
public struct HardwareSensorState: Codable {
    // ── Group 1: Micro-Biometric & Interaction Dynamics (1 - 13) ──
    public var keystrokeDwellTimeMs: Double = 58.4           // Signal 1
    public var keystrokeFlightTimeMs: Double = 96.2          // Signal 2
    public var touchPressureForce: Double = 0.54             // Signal 3
    public var touchContactAreaMm2: Double = 42.8            // Signal 4
    public var touchPosture: String = "Flat Thumb Pad"       // Signal 4 heuristic
    public var swipeVelocityVector: String = "1420 px/s @ 88°" // Signal 5
    public var swipeCurvatureArcDeg: Double = 13.8           // Signal 6
    public var swipeJitterPx: Double = 1.3                   // Signal 6
    public var microDwellLatencyMs: Double = 740.0           // Signal 7
    public var scrollTurbulenceReversals: Int = 1            // Signal 8
    public var videoRewatchLoopFactor: Double = 1.85         // Signal 9
    public var audioVolumeStep: Int = 9                      // Signal 10 (0-15)
    public var voicePitchFormantsF0: Double = 132.4          // Signal 11 (F0 Hz)
    public var voiceFormantsF1F2: String = "F1: 520Hz | F2: 1680Hz" // Signal 11
    public var speechCadenceWpm: Double = 142.0              // Signal 12
    public var speechPauseHesitationMs: Double = 420.0       // Signal 12
    public var pupillaryDilationMm: Double = 3.65            // Signal 13
    public var facialLandmarkMeshHash: String = "0x7F4B2E9A" // Signal 13 (468 points)

    // ── Group 2: Zero-Permission Physical Sensors & Hardware State (14 - 25) ──
    public var accelX: Double = 0.08                         // Signal 14 (m/s^2)
    public var accelY: Double = 9.74                         // Signal 14 (m/s^2)
    public var accelZ: Double = 0.92                         // Signal 14 (m/s^2)
    public var gyroX: Double = 0.02                          // Signal 15 (rad/s)
    public var gyroY: Double = -0.01                         // Signal 15 (rad/s)
    public var gyroZ: Double = 0.04                          // Signal 15 (rad/s)
    public var compassHeadingDeg: Double = 184.2             // Signal 16 (0-360°)
    public var stepFrequencySpm: Int = 108                   // Signal 17 (SPM)
    public var gaitCadenceRegularity: Double = 0.96          // Signal 17 (0-1)
    public var transitModeHeuristic: String = "Stationary (Desk)" // Signal 18
    public var batteryPercentFloat: Double = 84.1920         // Signal 19 (High-precision)
    public var batteryDischargeRateMa: Int = -385            // Signal 20 (mA)
    public var batteryTempC: Double = 31.8                   // Signal 20 (°C)
    public var thermalSlopeCPerMin: Double = +0.18           // Signal 20 (°C/min)
    public var barometricPressureHpa: Double = 1013.25       // Signal 21 (hPa)
    public var barometricAltitudeM: Double = 224.5           // Signal 21 (m)
    public var ambientIlluminanceLux: Double = 340.0         // Signal 22 (Lux)
    public var proximityDistanceCm: Double = 5.0             // Signal 23 (cm, Open)
    public var acousticDecibelDba: Double = 46.2             // Signal 24 (dB(A))
    public var acousticAura: String = "Quiet Studio Ambient" // Signal 24 classification
    public var cpuThrottleState: String = "Nominal (Cool)"   // Signal 25
    public var coreFrequencyDriftMhz: Double = -14.2         // Signal 25

    // ── Group 3: Silicon Architecture & Browser Fingerprints (26 - 32) ──
    public var canvasPixelRenderHash: String = "0x89E2F4A1B93" // Signal 26
    public var webglRendererVendor: String = "Adreno 740 / Apple M" // Signal 27
    public var webglShaderPrecision: String = "IEEE 754 High-p Float 24-bit" // Signal 27
    public var audioOscillatorResponseHash: String = "0xA41D880E53C" // Signal 28
    public var installedSystemFontsCount: Int = 284          // Signal 29
    public var fontsRegistryEntropy: String = "Entropy: 14.82 bits" // Signal 29
    public var displayGeometryBlueprint: String = "1220x2712 @ 446 ppi (Display P3)" // Signal 30
    public var hardwareConcurrencyCores: Int = 8             // Signal 31
    public var deviceMemoryCapGb: Double = 12.0              // Signal 32

    // ── Group 4: Radio-Frequency, Baseband & Spatial Topology (33 - 40) ──
    public var ambientWifiBssid: String = "74:83:c2:91:a5:20" // Signal 33
    public var wifiRssiDbm: Int = -54                        // Signal 34 (dBm)
    public var bleBeaconUuid: String = "fda50693-a4e2-4fb1-afcf-c6eb07647825" // Signal 35
    public var bleBeaconMajorMinor: String = "Major: 1004 | Minor: 2" // Signal 35
    public var cellularCgiTac: String = "404-45-7821-12048"  // Signal 36
    public var cellularTimingAdvance: Int = 2                // Signal 37 (rings)
    public var localGatewayMac: String = "a4:91:b1:2c:3e:4f" // Signal 38
    public var localSubnetRange: String = "192.168.1.0/24"   // Signal 38
    public var webrtcStunTurnLeakIp: String = "192.168.1.144" // Signal 39
    public var ultrasonicAudioBeaconChirp: String = "Inactive (19.2kHz Listen Active)" // Signal 40

    // ── Group 5: Memory Buffer, DOM Injection & Cross-Platform Ad Graphs (41 - 45) ──
    public var clipboardBufferStatus: String = "Watched (Plaintext Snippet, 38 chars)" // Signal 41
    public var inAppWebviewDomState: String = "Bridge Active / Inputs Audited" // Signal 42
    public var installed3rdPartyAppsCount: Int = 48          // Signal 43
    public var installedAppCategories: [String] = ["Tools/Dev", "Finance", "Social", "Messaging"] // Signal 43
    public var universalAdIdGaidOpenRtb: String = "7b2e94a1-8f30-4e2a-b620-1d89e4c19a04" // Signal 44
    public var crossDeviceLookalikeProximity: Double = 0.94  // Signal 45 (Co-location Index)
    
    public init() {}
}

// MARK: - Polyline Trajectory & Geometric Vertices
public struct TrajectoryPoint: Codable, Identifiable {
    public var id: String { "\(x)_\(y)_\(timestampOffsetMs)" }
    public let x: Double
    public let y: Double
    public let normalizedX: Double
    public let normalizedY: Double
    public let timestampOffsetMs: Double
    public let pressure: Double
    
    public init(
        x: Double,
        y: Double,
        normalizedX: Double,
        normalizedY: Double,
        timestampOffsetMs: Double = 0.0,
        pressure: Double = 0.5
    ) {
        self.x = x
        self.y = y
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.timestampOffsetMs = timestampOffsetMs
        self.pressure = pressure
    }
}

public struct TrajectoryVertex: Codable, Identifiable {
    public var id: String { "\(vertexType)_\(x)_\(y)_\(angleDeg)" }
    public let x: Double
    public let y: Double
    public let normalizedX: Double
    public let normalizedY: Double
    public let vertexType: String // e.g. "Apex Dip (U-Turn)", "Peak Crest", "Sharp Turn", "Inflection Point"
    public let angleDeg: Double
    
    public init(
        x: Double,
        y: Double,
        normalizedX: Double,
        normalizedY: Double,
        vertexType: String,
        angleDeg: Double
    ) {
        self.x = x
        self.y = y
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.vertexType = vertexType
        self.angleDeg = angleDeg
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
    public let biometrics: TouchMicroBiometrics
    public let pathPoints: [TrajectoryPoint]
    public let vertices: [TrajectoryVertex]
    public let gestureShape: String // "Linear Flick", "U-Shape Curve", "Inverted U / Arch", "V-Shape", "S-Curve", "Arc Sweep", "Zigzag Reversal"
    
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
        screenHeight: Double,
        biometrics: TouchMicroBiometrics = TouchMicroBiometrics(),
        pathPoints: [TrajectoryPoint] = [],
        vertices: [TrajectoryVertex] = [],
        gestureShape: String = "Linear Swipe"
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
        self.biometrics = biometrics
        self.pathPoints = pathPoints
        self.vertices = vertices
        self.gestureShape = gestureShape
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
    case sensorTelemetry = "Sensor Pulse"
    
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
        case .sensorTelemetry: return "waveform.path.ecg"
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
    public let touchBiometrics: TouchMicroBiometrics?
    
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
        uiDescription: String,
        touchBiometrics: TouchMicroBiometrics? = nil
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
        self.touchBiometrics = touchBiometrics
    }
}

public struct KeystrokeBurstMetadata: Codable {
    public let charCount: Int
    public let wpm: Double
    public let durationSeconds: Double
    public let flowState: FlowState
    public let terminatorKey: String?
    public let inferredCategory: String
    public let biometrics: KeystrokeMicroBiometrics
    
    public init(
        charCount: Int,
        wpm: Double,
        durationSeconds: Double,
        flowState: FlowState,
        terminatorKey: String?,
        inferredCategory: String,
        biometrics: KeystrokeMicroBiometrics = KeystrokeMicroBiometrics()
    ) {
        self.charCount = charCount
        self.wpm = wpm
        self.durationSeconds = durationSeconds
        self.flowState = flowState
        self.terminatorKey = terminatorKey
        self.inferredCategory = inferredCategory
        self.biometrics = biometrics
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
    public let hardwareSnapshot: HardwareSensorState?
    
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
        swipeMetadata: SwipeMetadata? = nil,
        hardwareSnapshot: HardwareSensorState? = nil
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
        self.hardwareSnapshot = hardwareSnapshot
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SS"
        return formatter.string(from: timestamp)
    }
}
