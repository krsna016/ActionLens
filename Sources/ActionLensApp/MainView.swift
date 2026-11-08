import SwiftUI
import ActionLensCore

public struct MainView: View {
    @ObservedObject var manager = SessionManager.shared
    
    let deviceOptions = ["Unified", "Mac", "Phone"]
    let tabs = ["Click Radar", "Keystroke WPM", "Session Story", "45 Vectors", "Cognitive Twin"]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            ActionLensTheme.background.ignoresSafeArea()
            
            if manager.isMiniHUD {
                MiniHUDView(manager: manager) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        manager.isMiniHUD = false
                    }
                }
                .frame(width: 380, height: 80)
                .padding(16)
            } else {
                VStack(spacing: 0) {
                    // Top Command Bar
                    headerBar
                    
                    // Device Switcher Bar (Mac / Phone / Unified)
                    deviceSwitcherBar
                    
                    Divider().background(ActionLensTheme.border)
                    
                    // Main Split Pane
                    HStack(spacing: 16) {
                        // Left Pane: Live Narrative Feed (Beautiful English Stream)
                        LiveNarrativeFeedView(manager: manager)
                            .frame(minWidth: 500)
                        
                        // Right Pane: Telemetry / Radar / Storybook
                        VStack(spacing: 12) {
                            // Tab Selector
                            HStack(spacing: 6) {
                                ForEach(tabs, id: \.self) { tab in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            manager.rightTab = tab
                                        }
                                    }) {
                                        Label(tab.uppercased(), systemImage: iconForTab(tab))
                                            .font(.system(size: 11.5, weight: manager.rightTab == tab ? .black : .bold, design: .monospaced))
                                            .lineLimit(1)
                                            .foregroundColor(manager.rightTab == tab ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(manager.rightTab == tab ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
                                            .cornerRadius(ActionLensTheme.tacticalRadius)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                                    .stroke(manager.rightTab == tab ? ActionLensTheme.cyanAccent.opacity(0.7) : ActionLensTheme.border, lineWidth: 0.8)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            
                            // Tab Content
                            switch manager.rightTab {
                            case "Click Radar":
                                ClickRadarView(manager: manager)
                            case "Keystroke WPM":
                                KeystrokeTelemetryView(manager: manager)
                            case "Session Story":
                                SessionStorybookView(manager: manager)
                            case "45 Vectors":
                                TelemetryMatrixView(manager: manager)
                            case "Cognitive Twin":
                                CognitiveTwinView(manager: manager)
                            default:
                                ClickRadarView(manager: manager)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .frame(width: 530)
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 1160, minHeight: 760)
    }
    
    private func iconForTab(_ tab: String) -> String {
        switch tab {
        case "Click Radar": return "scope"
        case "Keystroke WPM": return "speedometer"
        case "Session Story": return "book.pages"
        case "45 Vectors": return "waveform.path.ecg"
        case "Cognitive Twin": return "brain.head.profile"
        default: return "circle"
        }
    }
    
    // Top Header Bar
    private var headerBar: some View {
        HStack(spacing: 14) {
            // Branding & C4ISR Military Status
            HStack(spacing: 8) {
                Circle()
                    .fill(manager.isRecording ? ActionLensTheme.mintAccent : ActionLensTheme.coralAccent)
                    .frame(width: 9, height: 9)
                    .shadow(color: manager.isRecording ? ActionLensTheme.mintAccent.opacity(0.8) : ActionLensTheme.coralAccent.opacity(0.8), radius: 4)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("ACTIONLENS // C4ISR")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textPrimary)
                    Text(manager.isRecording ? "● REC: LIVE [52-VEC TELEMETRY]" : "■ HOLD: TELEMETRY PAUSED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(manager.isRecording ? ActionLensTheme.mintAccent : ActionLensTheme.coralAccent)
                }
            }
            
            Spacer()
            
            // Military KPI Instrumentation Gauges
            HStack(spacing: 8) {
                kpiBadge(title: "MAC CLK", value: String(format: "%03d", manager.totalClicks), icon: "cursorarrow.click.2", color: ActionLensTheme.cyanAccent)
                kpiBadge(title: "PHN TAP", value: String(format: "%03d", manager.totalPhoneTaps), icon: "hand.tap.fill", color: ActionLensTheme.mintAccent)
                kpiBadge(title: "SWP VEC", value: String(format: "%03d", manager.totalPhoneSwipes), icon: "hand.draw.fill", color: ActionLensTheme.amberAccent)
                kpiBadge(title: "KEY EVT", value: String(format: "%03d", manager.totalKeystrokes), icon: "keyboard", color: ActionLensTheme.coralAccent)
                
                // Frontmost Focus
                HStack(spacing: 6) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 12))
                        .foregroundColor(ActionLensTheme.purpleAccent)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ACTIVE FOCUS")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                        Text(manager.currentApp.isEmpty ? "SYSTEM" : manager.currentApp)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textPrimary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5.5)
                .background(ActionLensTheme.cardBackground)
                .cornerRadius(ActionLensTheme.tacticalRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                        .stroke(ActionLensTheme.border, lineWidth: 0.8)
                )
            }
            
            Spacer()
            
            // Tactical Action Controls
            HStack(spacing: 6) {
                // Pause / Stream Switch
                Button(action: { manager.toggleRecording() }) {
                    HStack(spacing: 4) {
                        Image(systemName: manager.isRecording ? "pause.fill" : "play.fill")
                            .font(.system(size: 11))
                        Text(manager.isRecording ? "PAUSE" : "RESUME")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(manager.isRecording ? ActionLensTheme.cyanAccent : ActionLensTheme.mintAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(manager.isRecording ? ActionLensTheme.cyanAccent.opacity(0.5) : ActionLensTheme.mintAccent.opacity(0.5), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help(manager.isRecording ? "Pause Telemetry Stream" : "Resume Telemetry Stream")
                
                // FLUSH SCREEN CANVAS (Preserves all database vectors)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        manager.clearScreenCanvasOverlays()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "eraser.line.dashed")
                            .font(.system(size: 11))
                        Text("FLUSH CANVAS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(ActionLensTheme.amberAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ActionLensTheme.amberAccent.opacity(0.12))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(ActionLensTheme.amberAccent.opacity(0.6), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Flush on-screen radar clutter & keystroke trails without deleting recorded telemetry vectors")
                
                // PURGE DATABASE (Full Wipe)
                Button(action: { manager.clearHistory() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("PURGE DB")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(ActionLensTheme.coralAccent.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ActionLensTheme.coralAccent.opacity(0.10))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(ActionLensTheme.coralAccent.opacity(0.4), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Purge complete chronicle and vector database")
                
                // Mini HUD Shrink
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        manager.isMiniHUD = true
                    }
                }) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 11))
                        .foregroundColor(ActionLensTheme.cyanAccent)
                        .padding(7)
                        .background(ActionLensTheme.cyanAccent.opacity(0.15))
                        .cornerRadius(ActionLensTheme.tacticalRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                .stroke(ActionLensTheme.cyanAccent.opacity(0.4), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help("Shrink to Floating Mini HUD")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(ActionLensTheme.panelBackground)
        .overlay(
            Rectangle()
                .frame(height: 0.8)
                .foregroundColor(ActionLensTheme.border),
            alignment: .bottom
        )
    }
    
    // Multi-Device Switcher Bar
    private var deviceSwitcherBar: some View {
        HStack(spacing: 12) {
            Text("DEVICE TARGET:")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(ActionLensTheme.textTertiary)
            
            // Segmented Tactical Switcher
            HStack(spacing: 4) {
                deviceButton(title: "UNIFIED DUAL", mode: "Unified", icon: "sparkles")
                deviceButton(title: "MAC DISPLAY", mode: "Mac", icon: "laptopcomputer")
                deviceButton(title: "PHONE (\(manager.phoneModel))", mode: "Phone", icon: "iphone")
            }
            
            Spacer()
            
            // ADB Phone Connection Status Pill
            HStack(spacing: 6) {
                Circle()
                    .fill(manager.isPhoneConnected ? ActionLensTheme.mintAccent : ActionLensTheme.amberAccent)
                    .frame(width: 7, height: 7)
                Text(manager.isPhoneConnected ? "ADB LINK: \(manager.phoneStatusDescription) | 120Hz KINETICS" : "ADB: OFFLINE / DISCONNECTED")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(manager.isPhoneConnected ? ActionLensTheme.mintAccent : ActionLensTheme.amberAccent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.5))
            .cornerRadius(ActionLensTheme.tacticalRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                    .stroke(manager.isPhoneConnected ? ActionLensTheme.mintAccent.opacity(0.3) : ActionLensTheme.amberAccent.opacity(0.3), lineWidth: 0.8)
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(ActionLensTheme.background.opacity(0.95))
    }
    
    private func deviceButton(title: String, mode: String, icon: String) -> some View {
        let isSelected = manager.activeDeviceView == mode
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                manager.activeDeviceView = mode
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .black : .bold, design: .monospaced))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 5.5)
            .background(isSelected ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
            .cornerRadius(ActionLensTheme.tacticalRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                    .stroke(isSelected ? ActionLensTheme.cyanAccent.opacity(0.7) : ActionLensTheme.border, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func kpiBadge(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
                Text(value)
                    .font(.system(size: 14.5, weight: .black, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5.5)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
}
