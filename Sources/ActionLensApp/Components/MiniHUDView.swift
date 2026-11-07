import SwiftUI
import ActionLensCore

public struct MiniHUDView: View {
    @ObservedObject var manager: SessionManager
    var onExpand: () -> Void
    
    public init(manager: SessionManager, onExpand: @escaping () -> Void) {
        self.manager = manager
        self.onExpand = onExpand
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Pulsing Status Dot
            Circle()
                .fill(manager.isRecording ? ActionLensTheme.mintAccent : ActionLensTheme.coralAccent)
                .frame(width: 8, height: 8)
                .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(manager.currentApp.uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(ActionLensTheme.cyanAccent)
                    
                    if manager.currentWPM > 5 {
                        Text("\(Int(manager.currentWPM)) WPM")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(ActionLensTheme.amberAccent.opacity(0.15))
                            .cornerRadius(3)
                    }
                    
                    Spacer()
                    
                    Text("\(manager.totalClicks) Clicks")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textTertiary)
                }
                
                // Latest narrative sentence
                let latest = manager.records.last?.narrativeEnglish ?? "ActionLens active — awaiting user inputs..."
                Text(latest)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ActionLensTheme.textPrimary)
                    .lineLimit(2)
            }
            
            // Expand Button
            Button(action: onExpand) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ActionLensTheme.textSecondary)
                    .padding(6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Restore Full Dashboard")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ActionLensTheme.border, lineWidth: 1)
        )
    }
}

// Visual Effect View for Native macOS Liquid Translucency
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
