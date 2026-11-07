import SwiftUI
import ActionLensCore

public struct SessionStorybookView: View {
    @ObservedObject var manager: SessionManager
    
    public init(manager: SessionManager) {
        self.manager = manager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label("AUTONOMOUS SESSION STORYBOOK", systemImage: "book.pages")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.mintAccent)
                
                Spacer()
                
                Button(action: {
                    MarkdownExporter.copyToClipboard(manager: manager)
                    showToast("Copied Dossier to Clipboard!")
                }) {
                    Label("Copy Story", systemImage: "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(ActionLensTheme.cyanAccent)
                
                Button(action: {
                    if let path = MarkdownExporter.saveToObsidian(manager: manager) {
                        showToast("Saved to Obsidian: \(URL(fileURLWithPath: path).lastPathComponent)")
                    } else {
                        showToast("Failed to save to Obsidian")
                    }
                }) {
                    Label("Export Obsidian", systemImage: "arrow.down.doc")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(ActionLensTheme.mintAccent)
            }
            .padding(.horizontal, 4)
            
            // Story Text Box
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(manager.sessionStory.isEmpty ? "Initializing narrative chronicle..." : manager.sessionStory)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .lineSpacing(6)
                        .foregroundColor(ActionLensTheme.textPrimary)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ActionLensTheme.border, lineWidth: 1)
                        )
                }
            }
            .frame(maxHeight: 220)
            
            // Toast Notification
            if let toast = manager.toastMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ActionLensTheme.mintAccent)
                    Text(toast)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ActionLensTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.85))
                .cornerRadius(6)
                .transition(.opacity)
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
    
    private func showToast(_ msg: String) {
        manager.toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            manager.toastMessage = nil
        }
    }
}
