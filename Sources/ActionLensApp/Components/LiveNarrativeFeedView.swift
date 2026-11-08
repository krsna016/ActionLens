import SwiftUI
import ActionLensCore

public struct LiveNarrativeFeedView: View {
    @ObservedObject var manager: SessionManager
    
    public init(manager: SessionManager) {
        self.manager = manager
    }
    
    public var filteredRecords: [ActionRecord] {
        manager.records.reversed().filter { record in
            // 1. Device Filter (Mac / Phone / Unified)
            if manager.activeDeviceView == "Mac" && record.deviceTarget != .mac {
                return false
            }
            if manager.activeDeviceView == "Phone" && record.deviceTarget != .phone {
                return false
            }
            
            // 2. Event Type Filter
            let matchesFilter: Bool
            switch manager.selectedFilter {
            case "Clicks & Taps":
                matchesFilter = (record.type == .leftClick || record.type == .rightClick || record.type == .doubleClick || record.type == .phoneTap)
            case "Swipes Only":
                matchesFilter = (record.type == .phoneSwipe)
            case "Typing Bursts":
                matchesFilter = (record.type == .keystrokeBurst)
            case "Shortcuts":
                matchesFilter = (record.type == .shortcut || record.type == .keyAction || record.type == .phoneKey)
            case "App Switches":
                matchesFilter = (record.type == .appSwitch)
            default:
                matchesFilter = true
            }
            
            if !matchesFilter { return false }
            
            // 3. Search Query
            if manager.searchText.isEmpty { return true }
            return record.narrativeEnglish.localizedCaseInsensitiveContains(manager.searchText) ||
                   record.appName.localizedCaseInsensitiveContains(manager.searchText)
        }
    }
    
    let filterOptions = ["All Events", "Clicks & Taps", "Swipes Only", "Typing Bursts", "Shortcuts", "App Switches"]
    
    public var body: some View {
        VStack(spacing: 8) {
            // Tactical Filter Bar & Mode Controls
            HStack(spacing: 8) {
                // Search Field
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(ActionLensTheme.textTertiary)
                    TextField(
                        "Search telemetry stream...",
                        text: Binding(
                            get: { manager.searchText },
                            set: { manager.searchText = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 13.5, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textPrimary)
                    
                    if !manager.searchText.isEmpty {
                        Button(action: { manager.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(ActionLensTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6.5)
                .background(Color.black.opacity(0.45))
                .cornerRadius(ActionLensTheme.tacticalRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                        .stroke(ActionLensTheme.border, lineWidth: 0.8)
                )
                
                // Tactical / Narrative View Switcher
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        manager.feedDisplayMode = (manager.feedDisplayMode == "Tactical" ? "Narrative" : "Tactical")
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: manager.feedDisplayMode == "Tactical" ? "list.bullet.rectangle" : "text.quote")
                            .font(.system(size: 12))
                        Text(manager.feedDisplayMode == "Tactical" ? "TACTICAL" : "NARRATIVE")
                            .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(ActionLensTheme.cyanAccent)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6.5)
                    .background(ActionLensTheme.cyanAccent.opacity(0.12))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(ActionLensTheme.cyanAccent.opacity(0.5), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Toggle between High-Density C4ISR Telemetry and Natural English Narrative")
                
                // Filter Picker
                Picker(
                    "",
                    selection: Binding(
                        get: { manager.selectedFilter },
                        set: { manager.selectedFilter = $0 }
                    )
                ) {
                    ForEach(filterOptions, id: \.self) { filter in
                        Text(filter.uppercased()).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                .frame(width: 150)
            }
            .padding(.horizontal, 4)
            
            // List of Narrative Cards
            ScrollView {
                LazyVStack(spacing: 6) {
                    if filteredRecords.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 28))
                                .foregroundColor(ActionLensTheme.textTertiary)
                            Text("NO TELEMETRY RECORDED FOR [\(manager.activeDeviceView.uppercased())]")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textSecondary)
                            Text("Interact with your Mac or ADB-connected phone to see live telemetry stream.")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textTertiary)
                        }
                        .padding(40)
                    } else {
                        ForEach(filteredRecords) { record in
                            NarrativeCardView(record: record, displayMode: manager.feedDisplayMode)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(ActionLensTheme.panelBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
}

// Individual Story Card
struct NarrativeCardView: View {
    let record: ActionRecord
    let displayMode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Device Tag + Time + App + Type Tag
            HStack(spacing: 8) {
                // Device Icon
                Image(systemName: record.deviceTarget.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                
                Text(record.deviceTarget.rawValue.uppercased())
                    .font(.system(size: 12.5, weight: .black, design: .monospaced))
                    .foregroundColor(record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent).opacity(0.15))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                
                Text(record.formattedTime)
                    .font(.system(size: 13.5, weight: .medium, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
                
                Text(record.appName)
                    .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                
                Spacer()
                
                Text(record.type.rawValue.uppercased())
                    .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                    .foregroundColor(colorForType(record.type))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(colorForType(record.type).opacity(0.15))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
            }
            
            // Content Body: Switched between High-Density Tactical and Narrative Prose
            if displayMode == "Tactical" {
                HStack(spacing: 10) {
                    if let click = record.clickMetadata {
                        Text("TARGET: [\(click.uiRole.isEmpty ? "Glass Surface" : click.uiRole)]")
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.cyanAccent)
                        
                        if !click.uiTitle.isEmpty {
                            Text("\"\(click.uiTitle)\"")
                                .font(.system(size: 13.5, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textSecondary)
                                .lineLimit(1)
                        }
                    } else if let swipe = record.swipeMetadata {
                        Text("VEC: \(swipe.direction.rawValue.uppercased()) [\(Int(swipe.distance))px @ \(Int(swipe.velocity))px/s]")
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                    } else if let burst = record.burstMetadata {
                        Text("BURST: \(burst.charCount) CHARS @ \(Int(burst.wpm)) WPM [\(burst.flowState.rawValue)]")
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                    } else {
                        Text(record.narrativeEnglish)
                            .font(.system(size: 14.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            } else {
                Text(record.narrativeEnglish)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(ActionLensTheme.textPrimary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Technical Footer Pills & Micro-Biometrics
            if let swipe = record.swipeMetadata {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Label(swipe.direction.rawValue, systemImage: swipe.direction.icon)
                            .font(.system(size: 13.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                        
                        Text("Dist: \(Int(swipe.distance))px")
                            .font(.system(size: 13.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                        
                        Text("Vel: \(Int(swipe.velocity))px/s")
                            .font(.system(size: 13.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                    }
                    let bio = swipe.biometrics
                    HStack(spacing: 8) {
                        Label("Force: \(Int(bio.pressure * 100))%", systemImage: "gauge.with.dots.needle.bottom.50percent")
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.coralAccent)
                        
                        Label("Arc: \(String(format: "%.1f°", bio.curvatureArcDeg))", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                        
                        Label("Jitter: \(String(format: "%.1fpx", bio.jitterPx))", systemImage: "waveform.path.badge.plus")
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                        
                        if bio.isHesitationReversal {
                            Label("Reversal", systemImage: "arrow.uturn.backward")
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundColor(ActionLensTheme.coralAccent)
                        }
                    }
                }
                .padding(.top, 2)
            } else if let click = record.clickMetadata {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Label("(\(Int(click.x)), \(Int(click.y)))", systemImage: "crosshair")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                        
                        if !click.uiRole.isEmpty {
                            Label(click.uiRole, systemImage: "square.dashed")
                                .font(.system(size: 13.5, design: .monospaced))
                                .foregroundColor(ActionLensTheme.textSecondary)
                        }
                    }
                    if let bio = click.touchBiometrics {
                        HStack(spacing: 8) {
                            Label("Force: \(Int(bio.pressure * 100))%", systemImage: "hand.tap")
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundColor(ActionLensTheme.mintAccent)
                            
                            Label("Area: \(String(format: "%.1f", bio.surfaceAreaMm2))mm²", systemImage: "circle.circle")
                                .font(.system(size: 12.5, design: .monospaced))
                                .foregroundColor(ActionLensTheme.cyanAccent)
                            
                            Text("[\(bio.postureHeuristic)]")
                                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                .foregroundColor(ActionLensTheme.purpleAccent)
                        }
                    }
                }
                .padding(.top, 2)
            } else if let burst = record.burstMetadata {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Label("\(burst.charCount) chars", systemImage: "character.cursor.ibeam")
                            .font(.system(size: 13.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                        
                        Label("\(Int(burst.wpm)) WPM", systemImage: "gauge.with.needle")
                            .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                        
                        Text("[\(burst.flowState.rawValue)]")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                    }
                    let bio = burst.biometrics
                    HStack(spacing: 8) {
                        Label("Dwell: \(Int(bio.dwellTimeMs))ms", systemImage: "timer")
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.cyanAccent)
                        
                        Label("Flight: \(Int(bio.flightTimeMs))ms", systemImage: "arrow.right.to.line.compact")
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                        
                        Label("Conf: \(Int(bio.confidenceScore * 100))%", systemImage: "brain.head.profile")
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                    }
                }
                .padding(.top, 2)
            } else if let combo = record.shortcutCombo {
                HStack(spacing: 10) {
                    Label("Key Combo: [\(combo)]", systemImage: "command")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.purpleAccent)
                }
                .padding(.top, 2)
            }
        }
        .padding(11)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
    
    private func colorForType(_ type: ActionType) -> Color {
        switch type {
        case .leftClick, .doubleClick: return ActionLensTheme.cyanAccent
        case .rightClick, .drag: return ActionLensTheme.mintAccent
        case .keystrokeBurst: return ActionLensTheme.amberAccent
        case .shortcut, .keyAction: return ActionLensTheme.purpleAccent
        case .appSwitch: return ActionLensTheme.coralAccent
        case .phoneTap: return ActionLensTheme.mintAccent
        case .phoneSwipe: return ActionLensTheme.amberAccent
        case .phoneKey: return ActionLensTheme.purpleAccent
        case .sensorTelemetry: return ActionLensTheme.cyanAccent
        }
    }
}
