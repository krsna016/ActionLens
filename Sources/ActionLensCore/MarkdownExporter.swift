import Foundation
import Cocoa

public class MarkdownExporter {
    public static func generateMarkdown(manager: SessionManager) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = formatter.string(from: manager.sessionStartTime)
        
        var md = """
        # 🔭 ActionLens — Interaction Chronicle Dossier
        **Session Date:** \(dateStr)  
        **Total Clicks:** \(manager.totalClicks)  
        **Total Keystrokes:** \(manager.totalKeystrokes)  
        **Current Focus:** \(manager.currentApp)  

        ---

        ## 📖 Natural English Executive Narrative
        \(manager.sessionStory)

        ---

        ## 📊 Application Engagement Breakdown
        | Application | Total Actions | Engagement Share |
        | :--- | :---: | :---: |
        """
        
        let total = max(manager.records.count, 1)
        let sorted = manager.appCounts.sorted { $0.value > $1.value }
        for (app, count) in sorted {
            let pct = (Double(count) / Double(total)) * 100.0
            md += "\n| **\(app)** | \(count) | \(String(format: "%.1f", pct))% |"
        }
        
        md += """
        

        ---

        ## ⏱ Live Interaction Chronicle (Chronological Stream)
        """
        
        for record in manager.records.reversed().prefix(100) {
            let time = record.formattedTime
            let icon = record.type.icon
            md += "\n- **[\(time)]** `\(record.appName)` \(icon) — \(record.narrativeEnglish)"
            if let click = record.clickMetadata {
                md += "\n  - *Target:* `\(click.uiRole)` \"\(click.uiTitle)\" at coordinates `(\(Int(click.x)), \(Int(click.y)))`"
            } else if let burst = record.burstMetadata {
                md += "\n  - *Cadence:* \(burst.charCount) chars @ \(Int(burst.wpm)) WPM (\(burst.flowState.rawValue))"
            }
        }
        
        return md
    }
    
    public static func saveToObsidian(manager: SessionManager) -> String? {
        let md = generateMarkdown(manager: manager)
        let vaultPath = NSString(string: "~/Documents/DOCUMENTS/ObsidianVault/ActionLens").expandingTildeInPath
        let fm = FileManager.default
        try? fm.createDirectory(atPath: vaultPath, withIntermediateDirectories: true)
        
        let fileDateFormatter = DateFormatter()
        fileDateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "ActionLens_Chronicle_\(fileDateFormatter.string(from: Date())).md"
        let fullPath = "\(vaultPath)/\(filename)"
        
        do {
            try md.write(toFile: fullPath, atomically: true, encoding: .utf8)
            return fullPath
        } catch {
            return nil
        }
    }
    
    public static func copyToClipboard(manager: SessionManager) {
        let md = generateMarkdown(manager: manager)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(md, forType: .string)
    }
}
