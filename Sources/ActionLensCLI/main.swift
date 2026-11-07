import Foundation
import Cocoa
import ApplicationServices
import ActionLensCore

// Ensure immediate, unbuffered stdout flush for CLI pipelines
setbuf(stdout, nil)

let args = CommandLine.arguments

func printBanner() {
    print("""
    \u{001B}[36m┌───────────────────────────────────────────────────────────────────┐
    │  🔭 ACTIONLENS — Cross-Device Interaction & Narrative Telemetry   │
    │  Mac Screen & Keystrokes + Android ADB Taps & Swipes Monitoring   │
    │  45 Live Micro-Biometric, Silicon, RF & Sensor Telemetry Vectors  │
    └───────────────────────────────────────────────────────────────────┘\u{001B}[0m
    """)
}

func printHelp() {
    printBanner()
    print("""
    \u{001B}[1mUSAGE:\u{001B}[0m
      actionlens [COMMAND] [OPTIONS]

    \u{001B}[1mCOMMANDS:\u{001B}[0m
      gui            Launch native macOS GUI with Dual Screen & Phone Canvas
      live           Stream live Mac & Phone interactions with micro-biometrics
      telemetry      Display comprehensive 45-Vector Silicon & Sensor Matrix
      status         Display Mac Accessibility & ADB Phone device metrics
      help           Display this manual

    \u{001B}[1mOPTIONS FOR LIVE STREAM:\u{001B}[0m
      actionlens live           # Streams both Mac & Phone interactions
      actionlens live --phone   # Filter stream strictly to ADB Phone
      actionlens live --mac     # Filter stream strictly to Mac Display
      actionlens live --verbose # Include expanded 45-signal sensor state
    """)
}

func checkStatus() {
    printBanner()
    print("\u{001B}[1m[1] MACOS HOST TELEMETRY:\u{001B}[0m")
    let trusted = AXIsProcessTrusted()
    print("  • Accessibility Permission: " + (trusted ? "\u{001B}[32m[GRANTED / TRUSTED]\u{001B}[0m" : "\u{001B}[31m[DENIED]\u{001B}[0m"))
    
    let screens = NSScreen.screens
    print("  • Active Mac Displays: \(screens.count)")
    for (idx, screen) in screens.enumerated() {
        print("    └─ Screen \(idx): \(Int(screen.frame.width))x\(Int(screen.frame.height)) Retina (Scale: \(screen.backingScaleFactor)x)")
    }
    
    let front = NSWorkspace.shared.frontmostApplication
    print("  • Active Mac Target: \u{001B}[33m\(front?.localizedName ?? "None")\u{001B}[0m (PID: \(front?.processIdentifier ?? 0))\n")
    
    print("\u{001B}[1m[2] ANDROID ADB TELEMETRY:\u{001B}[0m")
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/Users/openfrontierlabs/.local/bin/adb")
    p.arguments = ["devices", "-l"]
    let pipe = Pipe()
    p.standardOutput = pipe
    try? p.run()
    p.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let out = String(data: data, encoding: .utf8) ?? ""
    let lines = out.components(separatedBy: "\n").filter { $0.contains("device ") }
    
    if lines.isEmpty {
        print("  • ADB Connection: \u{001B}[31m[NO DEVICE DETECTED]\u{001B}[0m")
    } else {
        for l in lines {
            print("  • ADB Device: \u{001B}[32m\(l.trimmingCharacters(in: .whitespaces))\u{001B}[0m")
        }
        let p2 = Process()
        p2.executableURL = URL(fileURLWithPath: "/Users/openfrontierlabs/.local/bin/adb")
        p2.arguments = ["shell", "wm", "size"]
        let pipe2 = Pipe()
        p2.standardOutput = pipe2
        try? p2.run()
        p2.waitUntilExit()
        let sizeOut = String(data: pipe2.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        print("    └─ Screen Resolution: \(sizeOut.trimmingCharacters(in: .whitespacesAndNewlines))")
        
        let p3 = Process()
        p3.executableURL = URL(fileURLWithPath: "/Users/openfrontierlabs/.local/bin/adb")
        p3.arguments = ["shell", "dumpsys window | grep mCurrentFocus"]
        let pipe3 = Pipe()
        p3.standardOutput = pipe3
        try? p3.run()
        p3.waitUntilExit()
        let focusOut = String(data: pipe3.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        print("    └─ Foreground App: \u{001B}[33m\(focusOut.trimmingCharacters(in: .whitespacesAndNewlines))\u{001B}[0m")
    }
    print()
}

func displayTelemetryMatrix() {
    printBanner()
    let state = SessionManager.shared.currentSensorState
    
    print("\u{001B}[1m\u{001B}[36m┌── [GROUP 1: MICRO-BIOMETRICS & INTERACTION DYNAMICS (1-13)] ──────┐\u{001B}[0m")
    print(String(format: "│ 01. Keystroke Dwell Time : %6.1f ms  (Key contact duration)         │", state.keystrokeDwellTimeMs))
    print(String(format: "│ 02. Keystroke Flight Time: %6.1f ms  (Inter-key latency)            │", state.keystrokeFlightTimeMs))
    print(String(format: "│ 03. Touch Force Pressure : %5.0f%% (%0.2f force strain)              │", state.touchPressureForce * 100, state.touchPressureForce))
    print(String(format: "│ 04. Contact Surface Area : %5.1f mm² [%-20@] │", state.touchContactAreaMm2, state.touchPosture))
    print(String(format: "│ 05. Swipe Velocity Vector: %-37@ │", state.swipeVelocityVector))
    print(String(format: "│ 06. Arc & Jitter         : %5.1f° arc | %4.1fpx tremor              │", state.swipeCurvatureArcDeg, state.swipeJitterPx))
    print(String(format: "│ 07. Micro-Dwell Latency  : %6.0f ms  (Feed hesitation pause)        │", state.microDwellLatencyMs))
    print(String(format: "│ 08. Scroll Turbulence    : %2d reversals (Hesitation back-flips)    │", state.scrollTurbulenceReversals))
    print(String(format: "│ 09. Video Rewatch Loop   : %5.2fx retention multiplier              │", state.videoRewatchLoopFactor))
    print(String(format: "│ 10. Audio Volume Step    : %2d / 15 steps (Attention level)         │", state.audioVolumeStep))
    print(String(format: "│ 11. Voice Pitch Formants : %6.1f Hz [%-22@] │", state.voicePitchFormantsF0, state.voiceFormantsF1F2))
    print(String(format: "│ 12. Speech Cadence & Gap : %4.0f WPM | %4.0f ms hesitation          │", state.speechCadenceWpm, state.speechPauseHesitationMs))
    print(String(format: "│ 13. Pupillary Dilation   : %5.2f mm  [Mesh: %-10@]              │", state.pupillaryDilationMm, state.facialLandmarkMeshHash))
    print("\u{001B}[36m├── [GROUP 2: ZERO-PERMISSION SENSORS & HARDWARE STATE (14-25)] ────┤\u{001B}[0m")
    print(String(format: "│ 14. 3-Axis Accelerometer : X:%+5.2f Y:%+5.2f Z:%+5.2f m/s²          │", state.accelX, state.accelY, state.accelZ))
    print(String(format: "│ 15. Gyroscope Angular    : X:%+5.2f Y:%+5.2f Z:%+5.2f rad/s          │", state.gyroX, state.gyroY, state.gyroZ))
    print(String(format: "│ 16. Magnetometer Heading : %6.1f° (Directional facing)             │", state.compassHeadingDeg))
    print(String(format: "│ 17. Step Cadence / Gait  : %3d SPM | %3.0f%% regularity              │", state.stepFrequencySpm, state.gaitCadenceRegularity * 100))
    print(String(format: "│ 18. Transit Mode         : %-37@ │", state.transitModeHeuristic))
    print(String(format: "│ 19. Battery SoC Float    : %8.4f [%4.1f%% SoC tracking ID]       │", state.batteryPercentFloat / 100.0, state.batteryPercentFloat))
    print(String(format: "│ 20. Discharge & Thermal  : %+5d mA | Slope:%+5.2f°C/m (%.1f°C)     │", state.batteryDischargeRateMa, state.thermalSlopeCPerMin, state.batteryTempC))
    print(String(format: "│ 21. Barometric Pressure  : %7.1f hPa | Elev: %5.1f m                │", state.barometricPressureHpa, state.barometricAltitudeM))
    print(String(format: "│ 22. Ambient Illuminance  : %5.0f Lux  (Daylight/Ambient)            │", state.ambientIlluminanceLux))
    print(String(format: "│ 23. Proximity Sensor     : %4.1f cm [%-20@]            │", state.proximityDistanceCm, state.proximityDistanceCm < 2.0 ? "Covered / Near Ear" : "Clear (Open Field)"))
    print(String(format: "│ 24. Acoustic Decibel     : %5.1f dBA [%-21@]      │", state.acousticDecibelDba, state.acousticAura))
    print(String(format: "│ 25. CPU Throttle & Drift : %-16@ | Drift: %+5.1f MHz   │", state.cpuThrottleState, state.coreFrequencyDriftMhz))
    print("\u{001B}[36m├── [GROUP 3: SILICON ARCHITECTURE & BROWSER FINGERPRINTS (26-32)] ──┤\u{001B}[0m")
    print(String(format: "│ 26. Canvas 2D Hash       : %-37@ │", state.canvasPixelRenderHash))
    print(String(format: "│ 27. WebGL GPU / Precision: %-37@ │", state.webglRendererVendor))
    print(String(format: "│ 28. AudioContext Curve   : %-37@ │", state.audioOscillatorResponseHash))
    print(String(format: "│ 29. System Fonts Count   : %3d fonts [%-20@]      │", state.installedSystemFontsCount, state.fontsRegistryEntropy))
    print(String(format: "│ 30. Display Blueprint    : %-37@ │", state.displayGeometryBlueprint))
    print(String(format: "│ 31. CPU Logical Cores    : %2d Hardware Cores                       │", state.hardwareConcurrencyCores))
    print(String(format: "│ 32. Device Memory Cap    : %4.1f GB RAM Allocation Cap              │", state.deviceMemoryCapGb))
    print("\u{001B}[36m├── [GROUP 4: RADIO-FREQUENCY, BASEBAND & TOPOLOGY (33-40)] ─────────┤\u{001B}[0m")
    print(String(format: "│ 33. Ambient Wi-Fi BSSID  : %-37@ │", state.ambientWifiBssid))
    print(String(format: "│ 34. Wi-Fi RSSI Strength  : %4d dBm (Indoor triangulation)          │", state.wifiRssiDbm))
    print(String(format: "│ 35. BLE Beacon Proximity : %-37@ │", state.bleBeaconMajorMinor))
    print(String(format: "│ 36. Cellular CGI / TAC   : %-37@ │", state.cellularCgiTac))
    print(String(format: "│ 37. Cellular TA Delay    : %2d TA Rings (~%d meters radial offset)   │", state.cellularTimingAdvance, state.cellularTimingAdvance * 550))
    print(String(format: "│ 38. Gateway MAC & Subnet : %-37@ │", state.localGatewayMac))
    print(String(format: "│ 39. WebRTC Leaked IP     : %-37@ │", state.webrtcStunTurnLeakIp))
    print(String(format: "│ 40. Ultrasonic Beacon    : %-37@ │", state.ultrasonicAudioBeaconChirp))
    print("\u{001B}[36m├── [GROUP 5: MEMORY BUFFER, DOM & CROSS-PLATFORM AD GRAPHS (41-45)] ┤\u{001B}[0m")
    print(String(format: "│ 41. Clipboard Ingestion  : %-37@ │", state.clipboardBufferStatus))
    print(String(format: "│ 42. In-App WebView DOM   : %-37@ │", state.inAppWebviewDomState))
    print(String(format: "│ 43. Installed Inventory  : %2d 3rd-party apps audited                │", state.installed3rdPartyAppsCount))
    print(String(format: "│ 44. Universal Ad ID      : %-37@ │", state.universalAdIdGaidOpenRtb))
    print(String(format: "│ 45. Cross-Device Graph   : Co-location Index %3.0f%%                    │", state.crossDeviceLookalikeProximity * 100))
    print("\u{001B}[36m└───────────────────────────────────────────────────────────────────┘\u{001B}[0m\n")
}

func launchGUI() {
    let appPath = "/Applications/ActionLens.app"
    if FileManager.default.fileExists(atPath: appPath) {
        let ws = NSWorkspace.shared
        let url = URL(fileURLWithPath: appPath)
        let config = NSWorkspace.OpenConfiguration()
        ws.openApplication(at: url, configuration: config) { _, error in
            if let err = error {
                print("\u{001B}[31mFailed to launch ActionLens.app: \(err.localizedDescription)\u{001B}[0m")
            } else {
                print("\u{001B}[32m✔ ActionLens Cross-Platform GUI launched successfully.\u{001B}[0m")
            }
            exit(0)
        }
        RunLoop.main.run(until: Date().addingTimeInterval(1.0))
    } else {
        print("\u{001B}[33mActionLens.app not found in /Applications. Run package_app.sh first.\u{001B}[0m")
    }
}

func runLiveStream(filterTarget: DeviceTarget?, verbose: Bool) {
    printBanner()
    let filterStr = filterTarget != nil ? "[\(filterTarget!.rawValue.uppercased()) ONLY]" : "[UNIFIED DUAL STREAM]"
    print("\u{001B}[32m✔ Telemetry Stream Active \(filterStr).\u{001B}[0m Click/type on Mac or tap/swipe on Phone. Press Ctrl+C to exit.\n")
    
    let manager = SessionManager.shared
    
    var printedPhoneConnection = false
    var lastCount = 0
    Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
        if manager.isPhoneConnected && !printedPhoneConnection {
            printedPhoneConnection = true
            print("\u{001B}[32m✔ [PHONE LINK ESTABLISHED]\u{001B}[0m \(manager.phoneModel) (\(Int(manager.phoneResolution.width))x\(Int(manager.phoneResolution.height))) active.")
        }
        
        if manager.records.count > lastCount {
            for i in lastCount..<manager.records.count {
                let rec = manager.records[i]
                if let ft = filterTarget, rec.deviceTarget != ft {
                    continue
                }
                
                let time = rec.formattedTime
                let devColor = rec.deviceTarget == .phone ? "\u{001B}[32m" : "\u{001B}[36m"
                let devTag = "\(devColor)[\(rec.deviceTarget.rawValue.uppercased())]\u{001B}[0m"
                let appTag = "\u{001B}[33m[\(rec.appName)]\u{001B}[0m"
                
                print("[\(time)] \(devTag) \(appTag) \u{001B}[1m\(rec.narrativeEnglish)\u{001B}[0m")
                
                if let swipe = rec.swipeMetadata {
                    print("  \u{001B}[90m└─ Shape: [\(swipe.gestureShape)] | Vector: \(swipe.direction.rawValue) | Dist: \(Int(swipe.distance))px | Vel: \(Int(swipe.velocity))px/s | Points: \(swipe.pathPoints.count)\u{001B}[0m")
                    if !swipe.vertices.isEmpty {
                        for (idx, v) in swipe.vertices.enumerated() {
                            print("  \u{001B}[33m   ├─ Vertex #\(idx + 1): \(v.vertexType) at (\(Int(v.x)), \(Int(v.y))) [Turn: \(String(format: "%.1f°", v.angleDeg))]\u{001B}[0m")
                        }
                    }
                    let bio = swipe.biometrics
                    print(String(format: "  \u{001B}[35m└─ Bio [4-6]: Force: %.0f%% | Area: %.1fmm² (%@) | Arc: %.1f° | Jitter: %.1fpx\u{001B}[0m", bio.pressure * 100, bio.surfaceAreaMm2, bio.postureHeuristic, bio.curvatureArcDeg, bio.jitterPx))
                } else if let click = rec.clickMetadata {
                    print("  \u{001B}[90m└─ Target: \(click.uiRole) \"\(click.uiTitle)\" | Coords: (\(Int(click.x)), \(Int(click.y))) | Screen: \(Int(click.screenWidth))x\(Int(click.screenHeight))\u{001B}[0m")
                    if let bio = click.touchBiometrics {
                        print(String(format: "  \u{001B}[35m└─ Bio [3-4]: Force: %.0f%% | Contact Area: %.1fmm² | Posture: %@\u{001B}[0m", bio.pressure * 100, bio.surfaceAreaMm2, bio.postureHeuristic))
                    }
                } else if let burst = rec.burstMetadata {
                    print("  \u{001B}[90m└─ Cadence: \(burst.charCount) characters | Velocity: \(Int(burst.wpm)) WPM | Flow: \(burst.flowState.rawValue)\u{001B}[0m")
                    let bio = burst.biometrics
                    print(String(format: "  \u{001B}[35m└─ Bio [1-2]: Dwell: %.1fms | Flight: %.1fms | Confidence: %.0f%% | Rhythm: %@\u{001B}[0m", bio.dwellTimeMs, bio.flightTimeMs, bio.confidenceScore * 100, bio.neuroMotorRhythm))
                }
                
                if verbose, let s = rec.hardwareSnapshot {
                    print(String(format: "  \u{001B}[94m└─ Sensor [14,19,20]: Accel(%.1f,%.1f,%.1f) | Batt: %.1f%% (%+dmA, %.1f°C)\u{001B}[0m", s.accelX, s.accelY, s.accelZ, s.batteryPercentFloat, s.batteryDischargeRateMa, s.batteryTempC))
                }
            }
            lastCount = manager.records.count
        }
    }
    
    RunLoop.main.run()
}

// CLI Dispatcher
if args.count < 2 {
    launchGUI()
} else {
    let cmd = args[1].lowercased()
    switch cmd {
    case "gui", "open", "start":
        launchGUI()
    case "live", "--live", "-l", "stream":
        var filter: DeviceTarget? = nil
        if args.contains("--phone") || args.contains("-p") { filter = .phone }
        if args.contains("--mac") || args.contains("-m") { filter = .mac }
        let verbose = args.contains("--verbose") || args.contains("-v")
        runLiveStream(filterTarget: filter, verbose: verbose)
    case "telemetry", "--telemetry", "-t", "matrix", "sensors":
        displayTelemetryMatrix()
    case "status", "--status", "-s":
        checkStatus()
    case "help", "--help", "-h":
        printHelp()
    default:
        print("Unknown command: \(cmd)")
        printHelp()
    }
}
