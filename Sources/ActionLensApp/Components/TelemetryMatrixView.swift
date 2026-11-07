import SwiftUI
import ActionLensCore

public struct TelemetryMatrixView: View {
    @ObservedObject var manager: SessionManager
    
    private let groupTitles = [
        "Biometrics (1-13)",
        "Sensors (14-25)",
        "Silicon (26-32)",
        "RF / Radio (33-40)",
        "Ad Graphs (41-45)"
    ]
    
    public init(manager: SessionManager) {
        self.manager = manager
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Group Sub-Navigation Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<groupTitles.count, id: \.self) { index in
                        Button(action: { manager.telemetryMatrixGroup = index }) {
                            Text(groupTitles[index])
                                .font(.system(size: 10, weight: manager.telemetryMatrixGroup == index ? .bold : .medium, design: .monospaced))
                                .foregroundColor(manager.telemetryMatrixGroup == index ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(manager.telemetryMatrixGroup == index ? ActionLensTheme.cyanAccent.opacity(0.18) : ActionLensTheme.cardBackground)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(manager.telemetryMatrixGroup == index ? ActionLensTheme.cyanAccent.opacity(0.6) : ActionLensTheme.border.opacity(0.5), lineWidth: 0.6)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            
            // Live Status Banner
            HStack(spacing: 8) {
                Circle()
                    .fill(ActionLensTheme.mintAccent)
                    .frame(width: 6, height: 6)
                
                Text("45 VECTORS LIVE • REFRESH RATE: 4ms / EVDEV")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.mintAccent)
                
                Spacer()
                
                Text(manager.activeDeviceView == "Phone" ? "ADB: \(manager.phoneModel)" : "HOST: macOS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ActionLensTheme.cardBackground.opacity(0.6))
            .cornerRadius(6)
            
            // Content Card List
            ScrollView {
                VStack(spacing: 8) {
                    let state = manager.currentSensorState
                    
                    switch manager.telemetryMatrixGroup {
                    case 0:
                        biometricsGroupView(state: state)
                    case 1:
                        sensorsGroupView(state: state)
                    case 2:
                        siliconGroupView(state: state)
                    case 3:
                        radioGroupView(state: state)
                    case 4:
                        adGraphsGroupView(state: state)
                    default:
                        biometricsGroupView(state: state)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Group 1: Micro-Biometric & Interaction Dynamics (1-13)
    @ViewBuilder
    private func biometricsGroupView(state: HardwareSensorState) -> some View {
        telemetryCard(id: "01", name: "Keystroke Dwell Time", value: String(format: "%.1f ms", state.keystrokeDwellTimeMs), sub: "Key contact duration (confidence index)", color: ActionLensTheme.cyanAccent, icon: "timer")
        telemetryCard(id: "02", name: "Keystroke Flight Time", value: String(format: "%.1f ms", state.keystrokeFlightTimeMs), sub: "Inter-key micro-latency (neuro-motor health)", color: ActionLensTheme.amberAccent, icon: "arrow.right.to.line.compact")
        telemetryCard(id: "03", name: "Touch Force / Pressure", value: String(format: "%.0f%% (%0.2f)", state.touchPressureForce * 100, state.touchPressureForce), sub: "ABS_MT_PRESSURE physical glass strain", color: ActionLensTheme.mintAccent, icon: "hand.tap.fill")
        telemetryCard(id: "04", name: "Contact Surface Area", value: String(format: "%.1f mm²", state.touchContactAreaMm2), sub: "Posture: \(state.touchPosture)", color: ActionLensTheme.purpleAccent, icon: "circle.circle")
        telemetryCard(id: "05", name: "Swipe Velocity Vector", value: state.swipeVelocityVector, sub: "Linear acceleration & flick trajectory", color: ActionLensTheme.coralAccent, icon: "arrow.up.right.circle")
        telemetryCard(id: "06", name: "Curvature Arc & Jitter", value: String(format: "%.1f° arc | %.1fpx tremor", state.swipeCurvatureArcDeg, state.swipeJitterPx), sub: "Thumb joint anatomical arc signature", color: ActionLensTheme.cyanAccent, icon: "arrow.triangle.turn.up.right.diamond")
        telemetryCard(id: "07", name: "Micro-Dwell Latency", value: String(format: "%.0f ms", state.microDwellLatencyMs), sub: "Subconscious feed hesitation & latent focus", color: ActionLensTheme.amberAccent, icon: "eye.fill")
        telemetryCard(id: "08", name: "Scroll Turbulence", value: "\(state.scrollTurbulenceReversals) reversals", sub: "Directional hesitation back-flips", color: ActionLensTheme.coralAccent, icon: "arrow.uturn.backward")
        telemetryCard(id: "09", name: "Video Rewatch Loop", value: String(format: "%.2fx", state.videoRewatchLoopFactor), sub: "Obsessive dopamine retention multiplier", color: ActionLensTheme.mintAccent, icon: "repeat")
        telemetryCard(id: "10", name: "Audio Volume Step", value: "\(state.audioVolumeStep) / 15", sub: "Active acoustic attention adjustments", color: ActionLensTheme.purpleAccent, icon: "speaker.wave.3.fill")
        telemetryCard(id: "11", name: "Voice Pitch & Formants", value: String(format: "%.1f Hz", state.voicePitchFormantsF0), sub: state.voiceFormantsF1F2, color: ActionLensTheme.cyanAccent, icon: "waveform")
        telemetryCard(id: "12", name: "Speech Cadence & Pause", value: String(format: "%.0f WPM", state.speechCadenceWpm), sub: String(format: "Hesitation pause: %.0f ms", state.speechPauseHesitationMs), color: ActionLensTheme.amberAccent, icon: "quote.bubble.fill")
        telemetryCard(id: "13", name: "Pupil Dilation & Mesh", value: String(format: "%.2f mm", state.pupillaryDilationMm), sub: "Mesh Hash: \(state.facialLandmarkMeshHash) (468 pts)", color: ActionLensTheme.mintAccent, icon: "face.smiling.inverse")
    }
    
    // MARK: - Group 2: Zero-Permission Physical Sensors & Hardware State (14-25)
    @ViewBuilder
    private func sensorsGroupView(state: HardwareSensorState) -> some View {
        telemetryCard(id: "14", name: "3-Axis Accelerometer", value: String(format: "X:%.2f Y:%.2f Z:%.2f", state.accelX, state.accelY, state.accelZ), sub: "Micro-vibrations & physical kinematics (m/s²)", color: ActionLensTheme.mintAccent, icon: "gyroscope")
        telemetryCard(id: "15", name: "Gyroscopic Rotation", value: String(format: "X:%.2f Y:%.2f Z:%.2f", state.gyroX, state.gyroY, state.gyroZ), sub: "3D angular rotation rate (rad/s)", color: ActionLensTheme.cyanAccent, icon: "rotate.3d")
        telemetryCard(id: "16", name: "Magnetometer Heading", value: String(format: "%.1f° Compass", state.compassHeadingDeg), sub: "Directional facing & aisle topology", color: ActionLensTheme.amberAccent, icon: "safari")
        telemetryCard(id: "17", name: "Step Frequency & Gait", value: "\(state.stepFrequencySpm) SPM", sub: String(format: "Cadence Regularity: %.0f%%", state.gaitCadenceRegularity * 100), color: ActionLensTheme.purpleAccent, icon: "figure.walk")
        telemetryCard(id: "18", name: "Transit Heuristic", value: state.transitModeHeuristic, sub: "Sensor noise vibration frequency classification", color: ActionLensTheme.coralAccent, icon: "tram.fill")
        telemetryCard(id: "19", name: "Battery SoC (Float)", value: String(format: "%.4f (%.1f%%)", state.batteryPercentFloat / 100.0, state.batteryPercentFloat), sub: "High-precision microsecond tracking ID", color: ActionLensTheme.mintAccent, icon: "battery.100.bolt")
        telemetryCard(id: "20", name: "Discharge & Thermal Slope", value: "\(state.batteryDischargeRateMa) mA", sub: String(format: "Slope: %+.2f °C/min (Temp: %.1f°C)", state.thermalSlopeCPerMin, state.batteryTempC), color: ActionLensTheme.amberAccent, icon: "thermometer.sun.fill")
        telemetryCard(id: "21", name: "Barometric Pressure", value: String(format: "%.1f hPa", state.barometricPressureHpa), sub: String(format: "Calculated floor altitude: %.1f m", state.barometricAltitudeM), color: ActionLensTheme.cyanAccent, icon: "gauge")
        telemetryCard(id: "22", name: "Ambient Illuminance", value: String(format: "%.0f Lux", state.ambientIlluminanceLux), sub: state.ambientIlluminanceLux < 50 ? "Dark Room Ambient" : "Daylight / Lit Office", color: ActionLensTheme.purpleAccent, icon: "sun.max.fill")
        telemetryCard(id: "23", name: "Proximity Sensor", value: state.proximityDistanceCm < 2.0 ? "Covered / Near Ear" : "Clear (Open Field)", sub: String(format: "Distance: %.1f cm", state.proximityDistanceCm), color: ActionLensTheme.coralAccent, icon: "sensor.tag.radiowaves.forward.fill")
        telemetryCard(id: "24", name: "Acoustic Decibel Spectrum", value: String(format: "%.1f dBA", state.acousticDecibelDba), sub: "Classification: \(state.acousticAura)", color: ActionLensTheme.mintAccent, icon: "waveform.badge.mic")
        telemetryCard(id: "25", name: "CPU Thermal Throttle", value: state.cpuThrottleState, sub: String(format: "Frequency drift: %+.1f MHz", state.coreFrequencyDriftMhz), color: ActionLensTheme.amberAccent, icon: "cpu")
    }
    
    // MARK: - Group 3: Silicon Architecture & Browser Fingerprints (26-32)
    @ViewBuilder
    private func siliconGroupView(state: HardwareSensorState) -> some View {
        telemetryCard(id: "26", name: "Canvas Pixel Render Hash", value: state.canvasPixelRenderHash, sub: "GPU sub-pixel cryptographic signature", color: ActionLensTheme.cyanAccent, icon: "paintpalette.fill")
        telemetryCard(id: "27", name: "WebGL Shader Precision", value: state.webglShaderPrecision, sub: state.webglRendererVendor, color: ActionLensTheme.mintAccent, icon: "checkerboard.shield")
        telemetryCard(id: "28", name: "AudioContext Oscillator", value: state.audioOscillatorResponseHash, sub: "DAC hardware processing frequency curve", color: ActionLensTheme.amberAccent, icon: "headphones")
        telemetryCard(id: "29", name: "System Fonts Registry", value: "\(state.installedSystemFontsCount) installed fonts", sub: state.fontsRegistryEntropy, color: ActionLensTheme.purpleAccent, icon: "textformat")
        telemetryCard(id: "30", name: "Display Geometry Blueprint", value: state.displayGeometryBlueprint, sub: "Physical vs CSS bit-depth geometry", color: ActionLensTheme.coralAccent, icon: "display")
        telemetryCard(id: "31", name: "Hardware Concurrency", value: "\(state.hardwareConcurrencyCores) Logical Cores", sub: "Processor core architecture tier", color: ActionLensTheme.cyanAccent, icon: "memorychip")
        telemetryCard(id: "32", name: "Device Memory Cap", value: String(format: "%.1f GB RAM", state.deviceMemoryCapGb), sub: "Browser allocation ceiling capacity", color: ActionLensTheme.mintAccent, icon: "internaldrive.fill")
    }
    
    // MARK: - Group 4: Radio-Frequency, Baseband & Spatial Topology (33-40)
    @ViewBuilder
    private func radioGroupView(state: HardwareSensorState) -> some View {
        telemetryCard(id: "33", name: "Ambient Wi-Fi BSSID", value: state.ambientWifiBssid, sub: "5-10m indoor spatial position key", color: ActionLensTheme.cyanAccent, icon: "wifi")
        telemetryCard(id: "34", name: "Wi-Fi RSSI Strength", value: "\(state.wifiRssiDbm) dBm", sub: "Indoor RF triangulation vector", color: ActionLensTheme.mintAccent, icon: "antenna.radiowaves.left.and.right")
        telemetryCard(id: "35", name: "BLE Proximity Beacons", value: state.bleBeaconUuid, sub: state.bleBeaconMajorMinor, color: ActionLensTheme.purpleAccent, icon: "dot.radiowaves.left.and.right")
        telemetryCard(id: "36", name: "Cellular CGI / TAC", value: state.cellularCgiTac, sub: "Cellular grid mapping without GPS", color: ActionLensTheme.amberAccent, icon: "cellularbars")
        telemetryCard(id: "37", name: "Cellular Timing Advance", value: "\(state.cellularTimingAdvance) TA rings", sub: "Radial distance offset delay from cell tower", color: ActionLensTheme.coralAccent, icon: "circle.circle.dashed")
        telemetryCard(id: "38", name: "Gateway MAC & Subnet", value: state.localGatewayMac, sub: "Subnet: \(state.localSubnetRange)", color: ActionLensTheme.cyanAccent, icon: "network")
        telemetryCard(id: "39", name: "WebRTC STUN Leak IP", value: state.webrtcStunTurnLeakIp, sub: "Internal RFC 1918 private IP reveal", color: ActionLensTheme.mintAccent, icon: "link.badge.plus")
        telemetryCard(id: "40", name: "Ultrasonic Beacon Chirp", value: state.ultrasonicAudioBeaconChirp, sub: "18-20kHz cross-device acoustic linking", color: ActionLensTheme.purpleAccent, icon: "waveform.path.badge.minus")
    }
    
    // MARK: - Group 5: Memory Buffer, DOM Injection & Cross-Platform Ad Graphs (41-45)
    @ViewBuilder
    private func adGraphsGroupView(state: HardwareSensorState) -> some View {
        telemetryCard(id: "41", name: "Clipboard Buffer Ingestion", value: state.clipboardBufferStatus, sub: "Cross-application clipboard monitoring", color: ActionLensTheme.coralAccent, icon: "doc.on.clipboard.fill")
        telemetryCard(id: "42", name: "WebView DOM Injection", value: state.inAppWebviewDomState, sub: "Form autofill & key event listener hooks", color: ActionLensTheme.amberAccent, icon: "chevron.left.forwardslash.chevron.right")
        telemetryCard(id: "43", name: "Application Inventory", value: "\(state.installed3rdPartyAppsCount) 3rd-Party Packages", sub: "Tags: \(state.installedAppCategories.joined(separator: ", "))", color: ActionLensTheme.cyanAccent, icon: "square.grid.2x2.fill")
        telemetryCard(id: "44", name: "Universal Ad ID (GAID)", value: state.universalAdIdGaidOpenRtb, sub: "Cross-app OpenRTB primary key join token", color: ActionLensTheme.mintAccent, icon: "person.badge.shield.checkmark.fill")
        telemetryCard(id: "45", name: "Lookalike Proximity Graph", value: String(format: "Co-location Index: %.0f%%", state.crossDeviceLookalikeProximity * 100), sub: "Relational cross-device purchase graph", color: ActionLensTheme.purpleAccent, icon: "point.3.connected.trianglepath.dotted")
    }
    
    // Sleek Modular HUD Card
    private func telemetryCard(id: String, name: String, value: String, sub: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(id)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.15))
                    .cornerRadius(3)
                
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ActionLensTheme.textPrimary)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
            
            Text(sub)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(ActionLensTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ActionLensTheme.border.opacity(0.6), lineWidth: 0.6)
        )
    }
}
