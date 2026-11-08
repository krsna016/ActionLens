import SwiftUI
import ActionLensCore

public struct ClickRadarView: View {
    @ObservedObject var manager: SessionManager
    
    public init(manager: SessionManager) {
        self.manager = manager
    }
    
    public var isPhoneCanvas: Bool {
        if manager.activeDeviceView == "Phone" { return true }
        if manager.activeDeviceView == "Mac" { return false }
        return manager.radarCanvasDevice == "Phone"
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // Header with Interactive Canvas Mode Switcher
            HStack(spacing: 8) {
                // Device Toggle Switch
                HStack(spacing: 3) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.radarCanvasDevice = "Phone"
                            manager.activeDeviceView = "Phone"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "iphone")
                            Text(manager.phoneModel.isEmpty ? "Phone" : manager.phoneModel)
                                .lineLimit(1)
                        }
                        .font(.system(size: 10, weight: isPhoneCanvas ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isPhoneCanvas ? ActionLensTheme.mintAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isPhoneCanvas ? ActionLensTheme.mintAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.radarCanvasDevice = "Mac"
                            manager.activeDeviceView = "Mac"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "laptopcomputer")
                            Text("Mac Screen")
                        }
                        .font(.system(size: 10, weight: !isPhoneCanvas ? .bold : .medium, design: .monospaced))
                        .foregroundColor(!isPhoneCanvas ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(!isPhoneCanvas ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Mode / Status Badge
                Text(isPhoneCanvas ? "\(Int(manager.phoneResolution.width))x\(Int(manager.phoneResolution.height))" : "Mac Retina")
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(isPhoneCanvas ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 4)
            
            // Swipe Style Switcher (Switch between Linear Vector and Polyline Curve)
            if isPhoneCanvas {
                HStack(spacing: 6) {
                    Text("SWIPE STYLE:")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textTertiary)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.swipeRenderStyle = "Polyline Curve"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                            Text("Curve & Vertex")
                                .lineLimit(1)
                        }
                        .font(.system(size: 11, weight: manager.swipeRenderStyle == "Polyline Curve" ? .bold : .medium, design: .monospaced))
                        .foregroundColor(manager.swipeRenderStyle == "Polyline Curve" ? ActionLensTheme.amberAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(manager.swipeRenderStyle == "Polyline Curve" ? ActionLensTheme.amberAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(ActionLensTheme.tacticalRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                .stroke(manager.swipeRenderStyle == "Polyline Curve" ? ActionLensTheme.amberAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.swipeRenderStyle = "Linear Vector"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                            Text("Linear Vector")
                                .lineLimit(1)
                        }
                        .font(.system(size: 11, weight: manager.swipeRenderStyle == "Linear Vector" ? .bold : .medium, design: .monospaced))
                        .foregroundColor(manager.swipeRenderStyle == "Linear Vector" ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(manager.swipeRenderStyle == "Linear Vector" ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(ActionLensTheme.tacticalRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                .stroke(manager.swipeRenderStyle == "Linear Vector" ? ActionLensTheme.cyanAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Secondary HUD Controls: Multi-Tier Grid (Wrap-Free, Crisp Fonts)
            if isPhoneCanvas {
                VStack(spacing: 6) {
                    // Row 1: Overlays, Intent & Scale (3 Equal Width Buttons)
                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                manager.isHeatmapEnabled.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: manager.isHeatmapEnabled ? "flame.fill" : "flame")
                                    .font(.system(size: 10))
                                Text(manager.isHeatmapEnabled ? "HEATMAP: ON" : "HEATMAP: OFF")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10.5, weight: manager.isHeatmapEnabled ? .bold : .medium, design: .monospaced))
                            .foregroundColor(manager.isHeatmapEnabled ? ActionLensTheme.coralAccent : ActionLensTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(manager.isHeatmapEnabled ? ActionLensTheme.coralAccent.opacity(0.18) : Color.white.opacity(0.04))
                            .cornerRadius(ActionLensTheme.tacticalRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                    .stroke(manager.isHeatmapEnabled ? ActionLensTheme.coralAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            manager.isIntentPredictionEnabled.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: manager.isIntentPredictionEnabled ? "target" : "scope")
                                    .font(.system(size: 10))
                                Text(manager.isIntentPredictionEnabled ? "INTENT: ON" : "INTENT: OFF")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10.5, weight: manager.isIntentPredictionEnabled ? .bold : .medium, design: .monospaced))
                            .foregroundColor(manager.isIntentPredictionEnabled ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(manager.isIntentPredictionEnabled ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
                            .cornerRadius(ActionLensTheme.tacticalRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                    .stroke(manager.isIntentPredictionEnabled ? ActionLensTheme.cyanAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                if manager.phoneScreenScale < 1.2 {
                                    manager.phoneScreenScale = 1.35
                                } else if manager.phoneScreenScale < 1.5 {
                                    manager.phoneScreenScale = 1.7
                                } else {
                                    manager.phoneScreenScale = 1.0
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 10))
                                Text(manager.phoneScreenScale < 1.2 ? "SCALE: 1x" : (manager.phoneScreenScale < 1.5 ? "SCALE: 1.4x" : "SCALE: 1.7x"))
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(ActionLensTheme.amberAccent.opacity(0.15))
                            .cornerRadius(ActionLensTheme.tacticalRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                    .stroke(ActionLensTheme.amberAccent.opacity(0.5), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    
                    // Row 2: Live Screen Mirroring & Canvas Maintenance (3 Equal Width Buttons)
                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                manager.isDigitalTwinEnabled.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(manager.isDigitalTwinEnabled ? ActionLensTheme.mintAccent : Color.gray)
                                    .frame(width: 6, height: 6)
                                Text(manager.isDigitalTwinEnabled ? "TWIN: LIVE" : "TWIN: OFF")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10.5, weight: manager.isDigitalTwinEnabled ? .bold : .medium, design: .monospaced))
                            .foregroundColor(manager.isDigitalTwinEnabled ? ActionLensTheme.mintAccent : ActionLensTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(manager.isDigitalTwinEnabled ? ActionLensTheme.mintAccent.opacity(0.18) : Color.white.opacity(0.04))
                            .cornerRadius(ActionLensTheme.tacticalRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                    .stroke(manager.isDigitalTwinEnabled ? ActionLensTheme.mintAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                manager.toggleScrcpyTwin()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                Text(manager.isScrcpyRunning ? "SCRCPY: 60FPS" : "SCRCPY: OFF")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10.5, weight: manager.isScrcpyRunning ? .bold : .medium, design: .monospaced))
                            .foregroundColor(manager.isScrcpyRunning ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(manager.isScrcpyRunning ? ActionLensTheme.cyanAccent.opacity(0.22) : Color.white.opacity(0.04))
                            .cornerRadius(ActionLensTheme.tacticalRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                    .stroke(manager.isScrcpyRunning ? ActionLensTheme.cyanAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                manager.clearScreenCanvasOverlays()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "eraser.line.dashed")
                                    .font(.system(size: 10))
                                Text("FLUSH")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(ActionLensTheme.amberAccent.opacity(0.15))
                            .cornerRadius(ActionLensTheme.tacticalRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                    .stroke(ActionLensTheme.amberAccent.opacity(0.5), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Flush on-screen radar pings and clutter (preserves telemetry database)")
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                // Mac Canvas Controls
                HStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.isHeatmapEnabled.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: manager.isHeatmapEnabled ? "flame.fill" : "flame")
                                .font(.system(size: 10))
                            Text(manager.isHeatmapEnabled ? "HEATMAP: ON" : "HEATMAP: OFF")
                                .lineLimit(1)
                        }
                        .font(.system(size: 11, weight: manager.isHeatmapEnabled ? .bold : .medium, design: .monospaced))
                        .foregroundColor(manager.isHeatmapEnabled ? ActionLensTheme.coralAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(manager.isHeatmapEnabled ? ActionLensTheme.coralAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(ActionLensTheme.tacticalRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                .stroke(manager.isHeatmapEnabled ? ActionLensTheme.coralAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        manager.isIntentPredictionEnabled.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: manager.isIntentPredictionEnabled ? "target" : "scope")
                                .font(.system(size: 10))
                            Text(manager.isIntentPredictionEnabled ? "INTENT: ON" : "INTENT: OFF")
                                .lineLimit(1)
                        }
                        .font(.system(size: 11, weight: manager.isIntentPredictionEnabled ? .bold : .medium, design: .monospaced))
                        .foregroundColor(manager.isIntentPredictionEnabled ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(manager.isIntentPredictionEnabled ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(ActionLensTheme.tacticalRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                .stroke(manager.isIntentPredictionEnabled ? ActionLensTheme.cyanAccent.opacity(0.6) : ActionLensTheme.border, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.clearScreenCanvasOverlays()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "eraser.line.dashed")
                                .font(.system(size: 10))
                            Text("FLUSH RADAR")
                                .lineLimit(1)
                        }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.amberAccent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(ActionLensTheme.amberAccent.opacity(0.15))
                        .cornerRadius(ActionLensTheme.tacticalRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                .stroke(ActionLensTheme.amberAccent.opacity(0.5), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Flush on-screen radar pings and clutter (preserves telemetry database)")
                    
                    if manager.isHeatmapEnabled {
                        Spacer()
                        Text("DEAD-ZONE: \(Int(manager.deadZoneCoveragePct))%")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.coralAccent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(ActionLensTheme.tacticalRadius)
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Screen Radar Canvas (Switches between Mac widescreen and Phone portrait mockup)
            if isPhoneCanvas {
                phoneRadarCanvas
            } else {
                macRadarCanvas
            }
            
            // Recent Spatial Interceptions (Clicks, Taps, and Swipes)
            recentInterceptionsList
            
            // Dual-Device Keystrokes HUD (Mac Cadence + Phone Micro-Biometrics)
            dualDeviceKeystrokeHud
        }
        .padding(14)
        .background(ActionLensTheme.panelBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
    
    // MARK: - Mac Radar Canvas
    private var macRadarCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                        .stroke(ActionLensTheme.border, lineWidth: 0.8)
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
                
                // Heatmap Gaussian KDE Layer (Feature 5)
                if manager.isHeatmapEnabled {
                    ForEach(manager.clickPings.filter { $0.deviceTarget == .mac }) { ping in
                        let px = ping.normalizedX * geo.size.width
                        let py = ping.normalizedY * geo.size.height
                        RadialGradient(
                            colors: [ActionLensTheme.coralAccent.opacity(0.55), ActionLensTheme.amberAccent.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 36
                        )
                        .frame(width: 72, height: 72)
                        .position(x: px, y: py)
                        .blur(radius: 6)
                    }
                    
                    // Focus Centroid Indicator
                    let cx = manager.primaryFocusCentroid.x * geo.size.width
                    let cy = manager.primaryFocusCentroid.y * geo.size.height
                    ZStack {
                        Circle()
                            .stroke(ActionLensTheme.coralAccent, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(ActionLensTheme.coralAccent)
                            .frame(width: 6, height: 6)
                    }
                    .position(x: cx, y: cy)
                }
                
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
                
                // Mac Predictive Momentum Vector (Feature 3)
                if manager.isIntentPredictionEnabled {
                    let macPings = manager.clickPings.filter { $0.deviceTarget == .mac }
                    if macPings.count >= 2 {
                        let lastPing = macPings[macPings.count - 1]
                        let prevPing = macPings[macPings.count - 2]
                        let lx = lastPing.normalizedX * geo.size.width
                        let ly = lastPing.normalizedY * geo.size.height
                        let px = prevPing.normalizedX * geo.size.width
                        let py = prevPing.normalizedY * geo.size.height
                        let dx = lx - px
                        let dy = ly - py
                        let predX = max(10, min(geo.size.width - 10, lx + dx * 0.75))
                        let predY = max(10, min(geo.size.height - 10, ly + dy * 0.75))
                        
                        Path { p in
                            p.move(to: CGPoint(x: lx, y: ly))
                            p.addLine(to: CGPoint(x: predX, y: predY))
                        }
                        .stroke(ActionLensTheme.cyanAccent, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        
                        ZStack {
                            Circle()
                                .stroke(ActionLensTheme.cyanAccent, lineWidth: 1)
                                .frame(width: 14, height: 14)
                            Circle()
                                .fill(ActionLensTheme.cyanAccent.opacity(0.4))
                                .frame(width: 4, height: 4)
                        }
                        .position(x: predX, y: predY)
                    }
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
        let scale: CGFloat = CGFloat(manager.phoneScreenScale)
        let frameW: CGFloat = 136 * scale
        let frameH: CGFloat = 256 * scale
        
        return GeometryReader { geo in
            let offsetX = (geo.size.width - frameW) / 2
            let offsetY = (geo.size.height - frameH) / 2
            
            ZStack {
                // Military Tactical Coordinate Reticles
                Path { p in
                    p.move(to: CGPoint(x: offsetX, y: geo.size.height / 2))
                    p.addLine(to: CGPoint(x: offsetX + frameW, y: geo.size.height / 2))
                    p.move(to: CGPoint(x: geo.size.width / 2, y: offsetY))
                    p.addLine(to: CGPoint(x: geo.size.width / 2, y: offsetY + frameH))
                }
                .stroke(ActionLensTheme.cyanAccent.opacity(0.18), style: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))
                
                // Military Corner Crosshairs
                Group {
                    // Top Left Bracket
                    Path { p in
                        p.move(to: CGPoint(x: offsetX - 5, y: offsetY + 10))
                        p.addLine(to: CGPoint(x: offsetX - 5, y: offsetY - 5))
                        p.addLine(to: CGPoint(x: offsetX + 10, y: offsetY - 5))
                    }
                    .stroke(ActionLensTheme.mintAccent.opacity(0.8), lineWidth: 1.5)
                    
                    // Top Right Bracket
                    Path { p in
                        p.move(to: CGPoint(x: offsetX + frameW - 10, y: offsetY - 5))
                        p.addLine(to: CGPoint(x: offsetX + frameW + 5, y: offsetY - 5))
                        p.addLine(to: CGPoint(x: offsetX + frameW + 5, y: offsetY + 10))
                    }
                    .stroke(ActionLensTheme.mintAccent.opacity(0.8), lineWidth: 1.5)
                    
                    // Bottom Left Bracket
                    Path { p in
                        p.move(to: CGPoint(x: offsetX - 5, y: offsetY + frameH - 10))
                        p.addLine(to: CGPoint(x: offsetX - 5, y: offsetY + frameH + 5))
                        p.addLine(to: CGPoint(x: offsetX + 10, y: offsetY + frameH + 5))
                    }
                    .stroke(ActionLensTheme.mintAccent.opacity(0.8), lineWidth: 1.5)
                    
                    // Bottom Right Bracket
                    Path { p in
                        p.move(to: CGPoint(x: offsetX + frameW - 10, y: offsetY + frameH + 5))
                        p.addLine(to: CGPoint(x: offsetX + frameW + 5, y: offsetY + frameH + 5))
                        p.addLine(to: CGPoint(x: offsetX + frameW + 5, y: offsetY + frameH - 10))
                    }
                    .stroke(ActionLensTheme.mintAccent.opacity(0.8), lineWidth: 1.5)
                }
                
                // Phone Bezel Frame
                RoundedRectangle(cornerRadius: 20 * scale)
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 140 * scale, height: 260 * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20 * scale)
                            .stroke(ActionLensTheme.mintAccent.opacity(0.4), lineWidth: 1.5)
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                
                // Digital Twin Live Phone Screen Preview (Feature 2)
                if manager.isDigitalTwinEnabled, let img = manager.phoneTwinImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: frameW, height: frameH)
                        .clipShape(RoundedRectangle(cornerRadius: 18 * scale))
                        .overlay(Color.black.opacity(0.35))
                        .id(manager.twinFrameId)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                
                // Hardware 60 FPS Stream HUD Status Indicator
                if manager.isScrcpyRunning {
                    VStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ActionLensTheme.cyanAccent)
                                .frame(width: 5, height: 5)
                            Text("⚡️ 60FPS METAL ACTIVE")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundColor(ActionLensTheme.cyanAccent)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(ActionLensTheme.cyanAccent.opacity(0.5), lineWidth: 0.8)
                        )
                        .padding(.top, 10 * scale)
                        Spacer()
                    }
                    .frame(width: frameW, height: frameH)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                
                // Heatmap Gaussian KDE Layer (Feature 5)
                if manager.isHeatmapEnabled {
                    ForEach(manager.clickPings.filter { $0.deviceTarget == .phone }) { ping in
                        let px = offsetX + CGFloat(ping.normalizedX) * frameW
                        let py = offsetY + CGFloat(ping.normalizedY) * frameH
                        RadialGradient(
                            colors: [ActionLensTheme.coralAccent.opacity(0.55), ActionLensTheme.amberAccent.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 2 * scale,
                            endRadius: 24 * scale
                        )
                        .frame(width: 48 * scale, height: 48 * scale)
                        .position(x: px, y: py)
                        .blur(radius: 4)
                    }
                }
                
                // Camera Pill Notch
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 32 * scale, height: 6 * scale)
                    .position(x: geo.size.width / 2, y: (geo.size.height / 2) - (118 * scale))
                
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
                
                // Active Live Drawing Trail (real-time finger touch rendering)
                if manager.isPhoneTouching && manager.livePhoneTrail.count >= 2 {
                    Path { p in
                        let f = manager.livePhoneTrail[0]
                        p.move(to: CGPoint(x: offsetX + CGFloat(f.normalizedX) * frameW, y: offsetY + CGFloat(f.normalizedY) * frameH))
                        for pt in manager.livePhoneTrail.dropFirst() {
                            p.addLine(to: CGPoint(x: offsetX + CGFloat(pt.normalizedX) * frameW, y: offsetY + CGFloat(pt.normalizedY) * frameH))
                        }
                    }
                    .stroke(
                        ActionLensTheme.mintAccent,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: ActionLensTheme.mintAccent.opacity(0.8), radius: 6)
                    
                    if let tip = manager.livePhoneTrail.last {
                        let tipX = offsetX + CGFloat(tip.normalizedX) * frameW
                        let tipY = offsetY + CGFloat(tip.normalizedY) * frameH
                        ZStack {
                            Circle()
                                .stroke(ActionLensTheme.mintAccent.opacity(0.8), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: ActionLensTheme.mintAccent, radius: 8)
                        }
                        .position(x: tipX, y: tipY)
                    }
                }
                
                // Predictive Intent Trajectory Engine (Feature 3)
                if manager.isIntentPredictionEnabled, let intent = manager.activePredictiveIntent, manager.isPhoneTouching {
                    let origX = offsetX + CGFloat(intent.originX) * frameW
                    let origY = offsetY + CGFloat(intent.originY) * frameH
                    let targX = offsetX + CGFloat(intent.projectedTargetX) * frameW
                    let targY = offsetY + CGFloat(intent.projectedTargetY) * frameH
                    
                    // 1. Biomechanical Intention Fan / Cone
                    Path { p in
                        let angle = intent.intentionAngleDeg * .pi / 180.0
                        let halfSpread = 16.0 * .pi / 180.0
                        let len = max(sqrt(pow(targX - origX, 2) + pow(targY - origY, 2)), 30.0) * 1.15
                        let pLeft = CGPoint(x: origX + cos(angle - halfSpread) * len, y: origY + sin(angle - halfSpread) * len)
                        let pRight = CGPoint(x: origX + cos(angle + halfSpread) * len, y: origY + sin(angle + halfSpread) * len)
                        
                        p.move(to: CGPoint(x: origX, y: origY))
                        p.addLine(to: pLeft)
                        p.addLine(to: pRight)
                        p.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [ActionLensTheme.cyanAccent.opacity(0.24), ActionLensTheme.cyanAccent.opacity(0.02)],
                            startPoint: .init(x: intent.originX, y: intent.originY),
                            endPoint: .init(x: intent.projectedTargetX, y: intent.projectedTargetY)
                        )
                    )
                    
                    // 2. Extrapolated Laser Guidance Vector (Dashed Neon)
                    Path { p in
                        p.move(to: CGPoint(x: origX, y: origY))
                        p.addLine(to: CGPoint(x: targX, y: targY))
                    }
                    .stroke(
                        ActionLensTheme.cyanAccent,
                        style: StrokeStyle(lineWidth: 1.8, dash: [5, 4])
                    )
                    .shadow(color: ActionLensTheme.cyanAccent.opacity(0.8), radius: 5)
                    
                    // 3. Projected Target Reticle & Semantic HUD
                    ZStack {
                        Circle()
                            .stroke(ActionLensTheme.cyanAccent, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                        
                        Circle()
                            .stroke(ActionLensTheme.mintAccent.opacity(0.6), lineWidth: 1)
                            .frame(width: 32, height: 32)
                        
                        Rectangle()
                            .fill(ActionLensTheme.cyanAccent)
                            .frame(width: 1.5, height: 10)
                        
                        Rectangle()
                            .fill(ActionLensTheme.cyanAccent)
                            .frame(width: 10, height: 1.5)
                        
                        // HUD Target Badge
                        VStack(spacing: 2) {
                            Text("180ms LEAD • \(Int(intent.trajectoryConfidencePct))% CONF")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundColor(ActionLensTheme.cyanAccent)
                            
                            Text(intent.targetZoneLabel.uppercased())
                                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(ActionLensTheme.cyanAccent.opacity(0.6), lineWidth: 0.6)
                        )
                        .offset(y: targY > (offsetY + frameH * 0.75) ? -24 : 24)
                    }
                    .position(x: targX, y: targY)
                }
                
                // Phone Swipes (Dynamically toggled between Polyline Curve and Linear Vector styles)
                ForEach(manager.phoneSwipesList.suffix(8)) { swipe in
                    let sx = offsetX + CGFloat(swipe.normalizedStartX) * frameW
                    let sy = offsetY + CGFloat(swipe.normalizedStartY) * frameH
                    let ex = offsetX + CGFloat(swipe.normalizedEndX) * frameW
                    let ey = offsetY + CGFloat(swipe.normalizedEndY) * frameH
                    
                    if manager.swipeRenderStyle == "Polyline Curve" && swipe.pathPoints.count >= 2 {
                        // Current Style: Continuous Polyline Curves + Vertices
                        Path { p in
                            let f = swipe.pathPoints[0]
                            p.move(to: CGPoint(x: offsetX + CGFloat(f.normalizedX) * frameW, y: offsetY + CGFloat(f.normalizedY) * frameH))
                            for pt in swipe.pathPoints.dropFirst() {
                                p.addLine(to: CGPoint(x: offsetX + CGFloat(pt.normalizedX) * frameW, y: offsetY + CGFloat(pt.normalizedY) * frameH))
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [ActionLensTheme.cyanAccent, ActionLensTheme.mintAccent, ActionLensTheme.amberAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: ActionLensTheme.cyanAccent.opacity(0.6), radius: 4)
                        
                        // Start Origin Dot
                        Circle()
                            .fill(ActionLensTheme.cyanAccent)
                            .frame(width: 6, height: 6)
                            .position(x: sx, y: sy)
                        
                        // Arrowhead / Terminal Dot
                        Circle()
                            .fill(ActionLensTheme.amberAccent)
                            .frame(width: 8, height: 8)
                            .shadow(color: ActionLensTheme.amberAccent.opacity(0.6), radius: 4)
                            .position(x: ex, y: ey)
                        
                        // Detected Geometric Vertices (Apex Dips, Peak Crests, Inflections)
                        ForEach(swipe.vertices) { vertex in
                            let vx = offsetX + CGFloat(vertex.normalizedX) * frameW
                            let vy = offsetY + CGFloat(vertex.normalizedY) * frameH
                            
                            ZStack {
                                Rectangle()
                                    .stroke(ActionLensTheme.amberAccent, lineWidth: 1.5)
                                    .rotationEffect(.degrees(45))
                                    .frame(width: 9, height: 9)
                                Circle()
                                    .fill(ActionLensTheme.coralAccent)
                                    .frame(width: 4, height: 4)
                                
                                Text(vertex.vertexType.contains("Apex") ? "APEX DIP" : (vertex.vertexType.contains("Crest") ? "CREST" : "VERTEX"))
                                    .font(.system(size: 7, weight: .black, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.amberAccent)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(Color.black.opacity(0.85))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(ActionLensTheme.amberAccent.opacity(0.6), lineWidth: 0.6)
                                    )
                                    .offset(y: vertex.vertexType.contains("Apex") ? 12 : -12)
                            }
                            .position(x: vx, y: vy)
                        }
                    } else {
                        // Earlier Style: Clean Linear Dashed Vector with Terminal Arrow
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
                        
                        // Start Dot
                        Circle()
                            .fill(ActionLensTheme.cyanAccent.opacity(0.8))
                            .frame(width: 5, height: 5)
                            .position(x: sx, y: sy)
                        
                        // Arrowhead end dot
                        Circle()
                            .fill(ActionLensTheme.amberAccent)
                            .frame(width: 7, height: 7)
                            .position(x: ex, y: ey)
                    }
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
        .frame(height: 260 * CGFloat(manager.phoneScreenScale))
    }
    
    // MARK: - Recent Interceptions List
    private var recentInterceptionsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECENT SPATIAL INTERCEPTIONS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
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
                                .font(.system(size: 11))
                                .foregroundColor(record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                            
                            if let swipe = record.swipeMetadata {
                                Image(systemName: swipe.gestureShape.contains("U-Shape") ? "arrow.triangle.swap" : swipe.direction.icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ActionLensTheme.amberAccent)
                                Text(swipe.gestureShape != "Linear Swipe" ? swipe.gestureShape : swipe.direction.rawValue)
                                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.amberAccent)
                                if !swipe.vertices.isEmpty {
                                    Text("[\(swipe.vertices.count)v]")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(ActionLensTheme.mintAccent)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(ActionLensTheme.mintAccent.opacity(0.15))
                                        .cornerRadius(2)
                                }
                                Text("(\(Int(swipe.distance))px)")
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.textSecondary)
                            } else if let click = record.clickMetadata {
                                Text("(\(Int(click.x)), \(Int(click.y)))")
                                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.textPrimary)
                            }
                            
                            Text(record.appName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ActionLensTheme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(3)
                            
                            Spacer()
                            
                            Text(record.formattedTime)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textTertiary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ActionLensTheme.cardBackground)
                        .cornerRadius(ActionLensTheme.tacticalRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                                .stroke(ActionLensTheme.border, lineWidth: 0.8)
                        )
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }
    
    // MARK: - Dual-Device Keystroke Dynamics HUD (Phone & Mac Keystrokes)
    private var dualDeviceKeystrokeHud: some View {
        HStack(spacing: 8) {
            // Mac Keystrokes Pill
            HStack(spacing: 6) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 11))
                    .foregroundColor(ActionLensTheme.amberAccent)
                Text("MAC:")
                    .font(.system(size: 10.5, weight: .black, design: .monospaced))
                    .foregroundColor(ActionLensTheme.amberAccent)
                Text("\(Int(manager.currentWPM)) WPM")
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("(\(manager.currentFlowState.rawValue))")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.45))
            .cornerRadius(ActionLensTheme.tacticalRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                    .stroke(ActionLensTheme.amberAccent.opacity(0.35), lineWidth: 0.8)
            )
            
            Spacer()
            
            // Phone Keystrokes Pill
            HStack(spacing: 6) {
                Image(systemName: "iphone")
                    .font(.system(size: 11))
                    .foregroundColor(ActionLensTheme.mintAccent)
                Text("PHONE:")
                    .font(.system(size: 10.5, weight: .black, design: .monospaced))
                    .foregroundColor(ActionLensTheme.mintAccent)
                Text(String(format: "%.0fms Dwell", manager.currentSensorState.keystrokeDwellTimeMs))
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(String(format: "%.0fms Flight", manager.currentSensorState.keystrokeFlightTimeMs))
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(ActionLensTheme.cyanAccent)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.45))
            .cornerRadius(ActionLensTheme.tacticalRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                    .stroke(ActionLensTheme.mintAccent.opacity(0.35), lineWidth: 0.8)
            )
        }
    }
}
