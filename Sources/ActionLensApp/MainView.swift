import SwiftUI
import ActionLensCore

public struct MainView: View {
    @ObservedObject var manager = SessionManager.shared
    
    let deviceOptions = ["Unified", "Mac", "Phone"]
    let tabs = ["Click Radar", "Keystroke WPM", "Session Story"]
    
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
                            .frame(minWidth: 460)
                        
                        // Right Pane: Telemetry / Radar / Storybook
                        VStack(spacing: 12) {
                            // Tab Selector
                            HStack(spacing: 8) {
                                ForEach(tabs, id: \.self) { tab in
                                    Button(action: { manager.rightTab = tab }) {
                                        Label(tab, systemImage: iconForTab(tab))
                                            .font(.system(size: 11, weight: manager.rightTab == tab ? .bold : .medium))
                                            .foregroundColor(manager.rightTab == tab ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(manager.rightTab == tab ? ActionLensTheme.cyanAccent.opacity(0.15) : Color.clear)
                                            .cornerRadius(6)
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
                            default:
                                ClickRadarView(manager: manager)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .frame(width: 380)
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 880, minHeight: 600)
    }
    
    private func iconForTab(_ tab: String) -> String {
        switch tab {
        case "Click Radar": return "scope"
        case "Keystroke WPM": return "speedometer"
        case "Session Story": return "book.pages"
        default: return "circle"
        }
    }
    
    // Top Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            // Branding & Live Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(manager.isRecording ? ActionLensTheme.mintAccent : ActionLensTheme.coralAccent)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("ACTIONLENS")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textPrimary)
                    Text(manager.isRecording ? "CROSS-PLATFORM INTERACTION TELEMETRY" : "TELEMETRY PAUSED")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(manager.isRecording ? ActionLensTheme.mintAccent : ActionLensTheme.coralAccent)
                }
            }
            
            Spacer()
            
            // KPI Quick Badges
            HStack(spacing: 10) {
                kpiBadge(title: "MAC CLICKS", value: "\(manager.totalClicks)", icon: "cursorarrow.click.2", color: ActionLensTheme.cyanAccent)
                kpiBadge(title: "PHONE TAPS", value: "\(manager.totalPhoneTaps)", icon: "hand.tap.fill", color: ActionLensTheme.mintAccent)
                kpiBadge(title: "SWIPES", value: "\(manager.totalPhoneSwipes)", icon: "hand.draw.fill", color: ActionLensTheme.amberAccent)
                kpiBadge(title: "KEYSTROKES", value: "\(manager.totalKeystrokes)", icon: "keyboard", color: ActionLensTheme.coralAccent)
                
                // Frontmost Focus
                HStack(spacing: 6) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 11))
                        .foregroundColor(ActionLensTheme.purpleAccent)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ACTIVE FOCUS")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                        Text(manager.currentApp)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ActionLensTheme.textPrimary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ActionLensTheme.cardBackground)
                .cornerRadius(6)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: { manager.toggleRecording() }) {
                    Image(systemName: manager.isRecording ? "pause.fill" : "play.fill")
                        .foregroundColor(ActionLensTheme.textPrimary)
                        .padding(7)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(manager.isRecording ? "Pause Telemetry Stream" : "Resume Telemetry Stream")
                
                Button(action: { manager.clearHistory() }) {
                    Image(systemName: "trash")
                        .foregroundColor(ActionLensTheme.textSecondary)
                        .padding(7)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Clear Chronicle")
                
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        manager.isMiniHUD = true
                    }
                }) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .foregroundColor(ActionLensTheme.cyanAccent)
                        .padding(7)
                        .background(ActionLensTheme.cyanAccent.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Shrink to Floating Mini HUD")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ActionLensTheme.panelBackground)
    }
    
    // Multi-Device Switcher Bar
    private var deviceSwitcherBar: some View {
        HStack(spacing: 12) {
            Text("DEVICE TARGET:")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(ActionLensTheme.textTertiary)
            
            // Segmented Switcher
            HStack(spacing: 4) {
                deviceButton(title: "Unified Dual", mode: "Unified", icon: "sparkles")
                deviceButton(title: "Mac Display", mode: "Mac", icon: "laptopcomputer")
                deviceButton(title: "Phone (\(manager.phoneModel))", mode: "Phone", icon: "iphone")
            }
            
            Spacer()
            
            // ADB Phone Connection Status Pill
            HStack(spacing: 6) {
                Circle()
                    .fill(manager.isPhoneConnected ? ActionLensTheme.mintAccent : ActionLensTheme.amberAccent)
                    .frame(width: 7, height: 7)
                Text(manager.isPhoneConnected ? "ADB: \(manager.phoneStatusDescription)" : "ADB: Disconnected")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(manager.isPhoneConnected ? ActionLensTheme.mintAccent : ActionLensTheme.amberAccent)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .cornerRadius(5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(ActionLensTheme.background.opacity(0.95))
    }
    
    private func deviceButton(title: String, mode: String, icon: String) -> some View {
        let isSelected = manager.activeDeviceView == mode
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                manager.activeDeviceView = mode
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? ActionLensTheme.textPrimary : ActionLensTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(isSelected ? ActionLensTheme.cyanAccent.opacity(0.25) : Color.white.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? ActionLensTheme.cyanAccent.opacity(0.8) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func kpiBadge(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textPrimary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(6)
    }
}
