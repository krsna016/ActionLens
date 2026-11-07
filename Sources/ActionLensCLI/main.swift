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
      live           Stream live Mac & Phone interactions to terminal stdout
      status         Display Mac Accessibility & ADB Phone device metrics
      help           Display this manual

    \u{001B}[1mOPTIONS FOR LIVE STREAM:\u{001B}[0m
      actionlens live           # Streams both Mac & Phone interactions
      actionlens live --phone   # Filter stream strictly to ADB Phone
      actionlens live --mac     # Filter stream strictly to Mac Display
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
    // Query devices directly
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
        // Resolution
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

func runLiveStream(filterTarget: DeviceTarget?) {
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
                    print("  \u{001B}[90m└─ Swipe: \(swipe.direction.rawValue) | Distance: \(Int(swipe.distance))px | Velocity: \(Int(swipe.velocity))px/s | Start: (\(Int(swipe.startX)), \(Int(swipe.startY))) → End: (\(Int(swipe.endX)), \(Int(swipe.endY)))\u{001B}[0m")
                } else if let click = rec.clickMetadata {
                    print("  \u{001B}[90m└─ Target: \(click.uiRole) \"\(click.uiTitle)\" | Coords: (\(Int(click.x)), \(Int(click.y))) | Screen: \(Int(click.screenWidth))x\(Int(click.screenHeight))\u{001B}[0m")
                } else if let burst = rec.burstMetadata {
                    print("  \u{001B}[90m└─ Cadence: \(burst.charCount) characters | Velocity: \(Int(burst.wpm)) WPM | Flow: \(burst.flowState.rawValue)\u{001B}[0m")
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
        runLiveStream(filterTarget: filter)
    case "status", "--status", "-s":
        checkStatus()
    case "help", "--help", "-h":
        printHelp()
    default:
        print("Unknown command: \(cmd)")
        printHelp()
    }
}
