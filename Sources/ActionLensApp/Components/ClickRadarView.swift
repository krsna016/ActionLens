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
            
            // Swipe Style Switcher (Switch between Earlier Linear Vector and Current Polyline Curve)
            if isPhoneCanvas {
                HStack(spacing: 6) {
                    Text("SWIPE STYLE:")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textTertiary)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.swipeRenderStyle = "Polyline Curve"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                            Text("Curve & Vertex (Current)")
                        }
                        .font(.system(size: 9, weight: manager.swipeRenderStyle == "Polyline Curve" ? .bold : .medium, design: .monospaced))
                        .foregroundColor(manager.swipeRenderStyle == "Polyline Curve" ? ActionLensTheme.amberAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(manager.swipeRenderStyle == "Polyline Curve" ? ActionLensTheme.amberAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            manager.swipeRenderStyle = "Linear Vector"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                            Text("Linear Vector (Earlier)")
                        }
                        .font(.system(size: 9, weight: manager.swipeRenderStyle == "Linear Vector" ? .bold : .medium, design: .monospaced))
                        .foregroundColor(manager.swipeRenderStyle == "Linear Vector" ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(manager.swipeRenderStyle == "Linear Vector" ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
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
                                Image(systemName: swipe.gestureShape.contains("U-Shape") ? "arrow.triangle.swap" : swipe.direction.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(ActionLensTheme.amberAccent)
                                Text(swipe.gestureShape != "Linear Swipe" ? swipe.gestureShape : swipe.direction.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.amberAccent)
                                if !swipe.vertices.isEmpty {
                                    Text("[\(swipe.vertices.count)v]")
                                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(ActionLensTheme.mintAccent)
                                        .padding(.horizontal, 3)
                                        .padding(.vertical, 0.5)
                                        .background(ActionLensTheme.mintAccent.opacity(0.15))
                                        .cornerRadius(2)
                                }
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
