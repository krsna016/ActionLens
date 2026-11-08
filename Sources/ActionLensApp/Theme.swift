import SwiftUI

public struct ActionLensTheme {
    // Military C4ISR Tactical Stealth Base Colors
    public static let background = Color(red: 7/255, green: 9/255, blue: 13/255)
    public static let panelBackground = Color(red: 12/255, green: 15/255, blue: 22/255, opacity: 0.96)
    public static let cardBackground = Color(red: 16/255, green: 20/255, blue: 29/255, opacity: 0.98)
    public static let cardBackgroundHover = Color(red: 22/255, green: 28/255, blue: 40/255)
    public static let border = Color(red: 30/255, green: 38/255, blue: 52/255)
    public static let borderAccent = Color(red: 0/255, green: 229/255, blue: 255/255, opacity: 0.35)
    
    // High-Precision Military Avionics / Sensor Palette
    public static let cyanAccent = Color(red: 0/255, green: 229/255, blue: 255/255)       // Telemetry / C4ISR
    public static let mintAccent = Color(red: 0/255, green: 255/255, blue: 136/255)       // Radar Phosphor / Intercept
    public static let amberAccent = Color(red: 255/255, green: 184/255, blue: 0/255)      // Avionics Warning / Trajectory
    public static let coralAccent = Color(red: 255/255, green: 59/255, blue: 92/255)       // Threat / Dead-Zone / Friction
    public static let purpleAccent = Color(red: 168/255, green: 85/255, blue: 247/255)    // Crypto / Focus / Intent
    
    // Standard Monospaced Typography Colors
    public static let textPrimary = Color(white: 0.96)
    public static let textSecondary = Color(white: 0.68)
    public static let textTertiary = Color(white: 0.42)
    
    // Strict Military Geometry Standard
    public static let tacticalRadius: CGFloat = 4.0
    public static let tacticalBorderWidth: CGFloat = 0.8
}
