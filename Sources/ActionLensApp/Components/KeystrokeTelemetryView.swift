import SwiftUI
import ActionLensCore

public struct KeystrokeTelemetryView: View {
    @ObservedObject var manager: SessionManager
    
    public init(manager: SessionManager) {
        self.manager = manager
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("KEYSTROKE INFERENCE & TELEMETRY", systemImage: "speedometer")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.amberAccent)
                
                Spacer()
                
                Text(manager.currentFlowState.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: manager.currentFlowState.badgeColorHex))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: manager.currentFlowState.badgeColorHex).opacity(0.15))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 4)
            
            // Speedometer HUD Card
            HStack(spacing: 20) {
                // Large WPM indicator
                VStack(spacing: 4) {
                    Text("\(Int(manager.currentWPM))")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundColor(ActionLensTheme.amberAccent)
                    
                    Text("CURRENT WPM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textSecondary)
                }
                .frame(width: 120)
                
                // Live Cadence Level Bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CADENCE VELOCITY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                        Spacer()
                        Text("\(Int(min(manager.currentWPM / 120.0 * 100.0, 100.0)))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.5))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [ActionLensTheme.cyanAccent, ActionLensTheme.mintAccent, ActionLensTheme.amberAccent, ActionLensTheme.coralAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(CGFloat(manager.currentWPM / 120.0), 1.0), height: 12)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("Thoughtful")
                        Spacer()
                        Text("Steady (60)")
                        Spacer()
                        Text("Deep Flow (80+)")
                    }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
                }
            }
            .padding(14)
            .background(ActionLensTheme.cardBackground)
            .cornerRadius(10)
            
            // Phone Touchscreen Keyboard Micro-Biometrics Card (Signals 1 - 4)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("PHONE TOUCH KEYSTROKE DYNAMICS", systemImage: "iphone")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.mintAccent)
                    Spacer()
                    Text("ADB EVDEV LIVE")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.mintAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ActionLensTheme.mintAccent.opacity(0.12))
                        .cornerRadius(3)
                }
                
                HStack(spacing: 10) {
                    // Signal 1: Dwell Time
                    VStack(alignment: .leading, spacing: 3) {
                        Text("KEY DWELL TIME")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                        Text(String(format: "%.1f ms", manager.currentSensorState.keystrokeDwellTimeMs))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                        Text("Typing Confidence")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                    
                    // Signal 2: Flight Time
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FLIGHT MICRO-GAP")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                        Text(String(format: "%.1f ms", manager.currentSensorState.keystrokeFlightTimeMs))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.cyanAccent)
                        Text("Cognitive Cadence")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                    
                    // Signal 3: Glass Pressure
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TOUCH FORCE")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                        Text(String(format: "%.0f%%", manager.currentSensorState.touchPressureForce * 100))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                        Text(manager.currentSensorState.touchPosture)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                }
            }
            .padding(14)
            .background(ActionLensTheme.cardBackground)
            .cornerRadius(10)
            
            // Neuro-Cognitive Psychometric Radar Card (Shannon Entropy & Stress Pulse)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("NEURO-COGNITIVE PSYCHOMETRIC RADAR", systemImage: "brain.head.profile")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.cyanAccent)
                    
                    Spacer()
                    
                    Text(manager.psychometricState.cognitiveLoadLevel.uppercased())
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(
                            manager.psychometricState.cognitiveLoadLevel.contains("Friction") ? ActionLensTheme.coralAccent :
                            (manager.psychometricState.cognitiveLoadLevel.contains("Flow") ? ActionLensTheme.mintAccent : ActionLensTheme.amberAccent)
                        )
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            (manager.psychometricState.cognitiveLoadLevel.contains("Friction") ? ActionLensTheme.coralAccent :
                            (manager.psychometricState.cognitiveLoadLevel.contains("Flow") ? ActionLensTheme.mintAccent : ActionLensTheme.amberAccent)).opacity(0.15)
                        )
                        .cornerRadius(4)
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    // Box 1: Shannon Entropy
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("SHANNON ENTROPY")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.2f bits", manager.psychometricState.shannonEntropyBits))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.cyanAccent)
                        }
                        
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.06))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ActionLensTheme.cyanAccent)
                                    .frame(width: g.size.width * min(CGFloat(manager.psychometricState.shannonEntropyBits / 2.58), 1.0))
                            }
                        }
                        .frame(height: 4)
                        
                        Text(manager.psychometricState.shannonEntropyBits < 1.45 ? "Cohesive Muscle Flow" : (manager.psychometricState.shannonEntropyBits > 2.05 ? "Cognitive Dispersion" : "Nominal Variance"))
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                    
                    // Box 2: Stress / Aggression Pulse
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("STRESS / AGGRESSION")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textSecondary)
                            Spacer()
                            Text("\(Int(manager.psychometricState.stressAggressionIndex * 100))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(manager.psychometricState.stressAggressionIndex > 0.4 ? ActionLensTheme.coralAccent : ActionLensTheme.mintAccent)
                        }
                        
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.06))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(manager.psychometricState.stressAggressionIndex > 0.4 ? ActionLensTheme.coralAccent : ActionLensTheme.mintAccent)
                                    .frame(width: g.size.width * min(CGFloat(manager.psychometricState.stressAggressionIndex), 1.0))
                            }
                        }
                        .frame(height: 4)
                        
                        Text(manager.psychometricState.stressAggressionIndex > 0.4 ? "High Strain / Rapid Backspaces" : "Calm Controlled Cadence")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                    
                    // Box 3: Rhythmic Confidence
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("RHYTHMIC CONFIDENCE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textSecondary)
                            Spacer()
                            Text("\(Int(manager.psychometricState.rhythmicConfidencePct))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.amberAccent)
                        }
                        
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.06))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ActionLensTheme.amberAccent)
                                    .frame(width: g.size.width * min(CGFloat(manager.psychometricState.rhythmicConfidencePct / 100.0), 1.0))
                            }
                        }
                        .frame(height: 4)
                        
                        Text("Cadence Stability & Predictability")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                    
                    // Box 4: Hesitation / Doubt Score
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("HESITATION / DOUBT")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textSecondary)
                            Spacer()
                            Text("\(Int(manager.psychometricState.hesitationDoubtScore * 100))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.purpleAccent)
                        }
                        
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.06))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ActionLensTheme.purpleAccent)
                                    .frame(width: g.size.width * min(CGFloat(manager.psychometricState.hesitationDoubtScore), 1.0))
                            }
                        }
                        .frame(height: 4)
                        
                        Text("Micro-Dwell & Reversal Latency")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                }
            }
            .padding(14)
            .background(ActionLensTheme.cardBackground)
            .cornerRadius(10)
            
            // Application Locus of Attention
            VStack(alignment: .leading, spacing: 10) {
                Text("APPLICATION FOCUS DISTRIBUTION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textSecondary)
                
                let totalActions = max(manager.records.count, 1)
                let sortedApps = manager.appCounts.sorted { $0.value > $1.value }.prefix(4)
                
                VStack(spacing: 8) {
                    ForEach(Array(sortedApps), id: \.key) { app, count in
                        let pct = Double(count) / Double(totalActions)
                        VStack(spacing: 3) {
                            HStack {
                                Text(app)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ActionLensTheme.textPrimary)
                                Spacer()
                                Text("\(count) ops (\(Int(pct * 100))%)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(ActionLensTheme.textSecondary)
                            }
                            
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.06))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(ActionLensTheme.purpleAccent)
                                        .frame(width: g.size.width * CGFloat(pct), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
            .padding(14)
            .background(ActionLensTheme.cardBackground)
            .cornerRadius(10)
        }
        .padding(16)
        .background(ActionLensTheme.panelBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ActionLensTheme.border, lineWidth: 1)
        )
    }
}

// Hex color extension helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
