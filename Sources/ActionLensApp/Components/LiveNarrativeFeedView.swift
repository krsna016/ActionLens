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
        VStack(spacing: 12) {
            // Filter Bar & Search
            HStack(spacing: 10) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ActionLensTheme.textTertiary)
                    TextField(
                        "Search narrative stream by keyword...",
                        text: Binding(
                            get: { manager.searchText },
                            set: { manager.searchText = $0 }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(ActionLensTheme.textPrimary)
                    
                    if !manager.searchText.isEmpty {
                        Button(action: { manager.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ActionLensTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ActionLensTheme.border, lineWidth: 1)
                )
                
                // Filter Picker
                Picker(
                    "",
                    selection: Binding(
                        get: { manager.selectedFilter },
                        set: { manager.selectedFilter = $0 }
                    )
                ) {
                    ForEach(filterOptions, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
            }
            .padding(.horizontal, 4)
            
            // List of Narrative Cards
            ScrollView {
                LazyVStack(spacing: 10) {
                    if filteredRecords.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 32))
                                .foregroundColor(ActionLensTheme.textTertiary)
                            Text("No interactions recorded for current view (\(manager.activeDeviceView))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(ActionLensTheme.textSecondary)
                            Text("Interact with your Mac or ADB-connected phone to see the live English chronicle.")
                                .font(.system(size: 11))
                                .foregroundColor(ActionLensTheme.textTertiary)
                        }
                        .padding(40)
                    } else {
                        ForEach(filteredRecords) { record in
                            NarrativeCardView(record: record)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
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

// Individual Story Card
struct NarrativeCardView: View {
    let record: ActionRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Device Tag + Time + App + Type Tag
            HStack(spacing: 8) {
                // Device Icon
                Image(systemName: record.deviceTarget.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                
                Text(record.deviceTarget.rawValue.uppercased())
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background((record.deviceTarget == .phone ? ActionLensTheme.mintAccent : ActionLensTheme.cyanAccent).opacity(0.15))
                    .cornerRadius(3)
                
                Text(record.formattedTime)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
                
                Text(record.appName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ActionLensTheme.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(record.type.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(colorForType(record.type))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorForType(record.type).opacity(0.15))
                    .cornerRadius(4)
            }
            
            // The English Narrative Prose
            Text(record.narrativeEnglish)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(ActionLensTheme.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            
            // Technical Footer Pills
            if let swipe = record.swipeMetadata {
                HStack(spacing: 8) {
                    Label(swipe.direction.rawValue, systemImage: swipe.direction.icon)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.amberAccent)
                    
                    Text("Distance: \(Int(swipe.distance))px")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textSecondary)
                    
                    Text("Velocity: \(Int(swipe.velocity))px/s")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textTertiary)
                }
                .padding(.top, 2)
            } else if let click = record.clickMetadata {
                HStack(spacing: 8) {
                    Label("(\(Int(click.x)), \(Int(click.y)))", systemImage: "crosshair")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ActionLensTheme.mintAccent)
                    
                    if !click.uiRole.isEmpty {
                        Label(click.uiRole, systemImage: "square.dashed")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textSecondary)
                    }
                    
                    if !click.uiTitle.isEmpty {
                        Text("\"\(click.uiTitle)\"")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(ActionLensTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 2)
            } else if let burst = record.burstMetadata {
                HStack(spacing: 8) {
                    Label("\(burst.charCount) characters", systemImage: "character.cursor.ibeam")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ActionLensTheme.amberAccent)
                    
                    Label("\(Int(burst.wpm)) WPM", systemImage: "gauge.with.needle")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ActionLensTheme.mintAccent)
                    
                    Text(burst.flowState.rawValue)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textSecondary)
                }
                .padding(.top, 2)
            } else if let combo = record.shortcutCombo {
                HStack(spacing: 6) {
                    Label("Key Combo: [\(combo)]", systemImage: "command")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ActionLensTheme.purpleAccent)
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ActionLensTheme.border.opacity(0.8), lineWidth: 0.8)
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
        }
    }
}
