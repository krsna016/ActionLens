import SwiftUI
import ActionLensCore

public struct ClickRadarView: View {
    @ObservedObject var manager: SessionManager
    
    public init(manager: SessionManager) {
        self.manager = manager
    }
    
    public var isPhoneCanvas: Bool {
        return manager.activeDeviceView == "Phone"
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // Header with Device Canvas Indicator
            HStack {
                Label(
                    isPhoneCanvas ? "PHONE DISPLAY RADAR & SWIPE TRACKER" : "LIVE CLICK RADAR & SCREEN MAPPING",
                    systemImage: isPhoneCanvas ? "iphone" : "scope"
                )
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isPhoneCanvas ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                
                Spacer()
                
                // Device Indicator Pill
                Text(isPhoneCanvas ? "\(manager.phoneModel)" : "Mac Retina Display")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 4)
            
            // Screen Radar Canvas (Switches between Mac widescreen and Phone portrait mockup)
            if isPhoneCanvas {
                phoneRadarCanvas
            } else {
                macRadarCanvas
            }
            
            // Recent Spatial Interceptions (Clicks, Taps, and Swipes)
            recentInterceptionsList
        }
        .padding(16)
        .background(ActionLensTheme.panelBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ActionLensTheme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Mac Radar Canvas
    private var macRadarCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ActionLensTheme.border, lineWidth: 1)
                )
            
            GeometryReader { geo in
                // Grid Crosshairs
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(ActionLensTheme.cyanAccent.opacity(0.12), lineWidth: 0.8)
                
                // Mac Click Pings
                ForEach(manager.clickPings.filter { $0.deviceTarget == .mac }) { ping in
                    let px = ping.normalizedX * geo.size.width
                    let py = ping.normalizedY * geo.size.height
                    
                    ZStack {
                        Circle()
                            .stroke(ActionLensTheme.cyanAccent.opacity(0.8), lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        Circle()
                            .fill(ActionLensTheme.mintAccent)
                            .frame(width: 6, height: 6)
                    }
                    .position(x: px, y: py)
                }
            }
            
            if manager.clickPings.filter({ $0.deviceTarget == .mac }).isEmpty {
                Text("Click anywhere on macOS to visualize radar pings")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
            }
        }
        .frame(height: 200)
    }
    
    // MARK: - Phone Radar Canvas (Vertical Phone Frame with Taps & Swipes)
    private var phoneRadarCanvas: some View {
        GeometryReader { geo in
            let frameW: CGFloat = 136
            let frameH: CGFloat = 256
            let offsetX = (geo.size.width - frameW) / 2
            let offsetY = (geo.size.height - frameH) / 2
            
            ZStack {
                // Phone Bezel Frame
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 140, height: 260)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ActionLensTheme.mintAccent.opacity(0.4), lineWidth: 1.5)
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                
                // Camera Pill Notch
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 32, height: 6)
                    .position(x: geo.size.width / 2, y: (geo.size.height / 2) - 118)
                
                // Phone Taps
                ForEach(manager.clickPings.filter { $0.deviceTarget == .phone }) { ping in
                    let px = offsetX + CGFloat(ping.normalizedX) * frameW
                    let py = offsetY + CGFloat(ping.normalizedY) * frameH
                    
                    ZStack {
                        Circle()
                            .stroke(ActionLensTheme.mintAccent.opacity(0.9), lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                        Circle()
                            .fill(ActionLensTheme.cyanAccent)
                            .frame(width: 5, height: 5)
                    }
                    .position(x: px, y: py)
                }
                
                // Phone Swipes (Vectors with Arrows)
                ForEach(Array(manager.phoneSwipesList.suffix(6).enumerated()), id: \.offset) { _, swipe in
                    let sx = offsetX + CGFloat(swipe.normalizedStartX) * frameW
                    let sy = offsetY + CGFloat(swipe.normalizedStartY) * frameH
                    let ex = offsetX + CGFloat(swipe.normalizedEndX) * frameW
                    let ey = offsetY + CGFloat(swipe.normalizedEndY) * frameH
                    
                    Path { p in
                        p.move(to: CGPoint(x: sx, y: sy))
                        p.addLine(to: CGPoint(x: ex, y: ey))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [ActionLensTheme.cyanAccent, ActionLensTheme.amberAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 2])
                    )
                    
                    // Arrowhead end dot
                    Circle()
                        .fill(ActionLensTheme.amberAccent)
                        .frame(width: 7, height: 7)
                        .position(x: ex, y: ey)
                }
                
                if manager.totalPhoneTaps == 0 && manager.totalPhoneSwipes == 0 {
                    VStack(spacing: 4) {
                        Text("Tap or swipe on phone")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                        Text("\(Int(manager.phoneResolution.width))x\(Int(manager.phoneResolution.height))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
        }
        .frame(height: 260)
    }
    
    // MARK: - Recent Interceptions List
    private var recentInterceptionsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECENT SPATIAL INTERCEPTIONS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(ActionLensTheme.textSecondary)
            
            ScrollView {
                VStack(spacing: 5) {
                    let recentRecords = manager.records
                        .filter { record in
                            if manager.activeDeviceView == "Mac" { return record.deviceTarget == .mac }
                            if manager.activeDeviceView == "Phone" { return record.deviceTarget == .phone }
                            return true
                        }
                        .suffix(5)
                        .reversed()
                    
                    ForEach(recentRecords) { record in
                        HStack(spacing: 8) {
                            // Device Tag
                            Image(systemName: record.deviceTarget.icon)
                                .font(.system(size: 10))
                                .foregroundColor(record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                            
                            if let swipe = record.swipeMetadata {
                                Image(systemName: swipe.direction.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(ActionLensTheme.amberAccent)
                                Text(swipe.direction.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.amberAccent)
                                Text("(\(Int(swipe.distance))px)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.textSecondary)
                            } else if let click = record.clickMetadata {
                                Text("(\(Int(click.x)), \(Int(click.y)))")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.textPrimary)
                            }
                            
                            Text(record.appName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(ActionLensTheme.textSecondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(3)
                            
                            Spacer()
                            
                            Text(record.formattedTime)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textTertiary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(ActionLensTheme.cardBackground)
                        .cornerRadius(6)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }
}
