//
//  CognitiveTwinView.swift
//  ActionLensApp
//
//  Autonomous Algorithmic User Digital Model & Cognitive Replica Console.
//  Renders Neuro-Motor Invariance (D_M²), Prefrontal State Machine,
//  and Persona Graph / CoreML Tensor Weight Exporters.
//

import SwiftUI
import ActionLensCore

public struct CognitiveTwinView: View {
    @ObservedObject var manager: SessionManager
    
    public init(manager: SessionManager) {
        self.manager = manager
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Section Header Bar
                HStack {
                    Label("COGNITIVE DIGITAL TWIN // OPERATOR REPLICA", systemImage: "brain.head.profile")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(ActionLensTheme.cyanAccent)
                    
                    Spacer()
                    
                    let conf = manager.activeCognitiveTwin?.identityConfidencePct ?? 99.4
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ActionLensTheme.mintAccent)
                            .frame(width: 6, height: 6)
                        Text(String(format: "INVARIANCE: %.1f%%", conf))
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(ActionLensTheme.mintAccent.opacity(0.12))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(ActionLensTheme.mintAccent.opacity(0.4), lineWidth: 0.8)
                    )
                }
                .padding(.horizontal, 2)
                
                // Card 1: Neuro-Motor Biometric Invariance (Mahalanobis Distance D_M²)
                neuroMotorInvarianceCard
                
                // Card 2: Prefrontal Cognitive State Machine & Shannon Entropy
                prefrontalWorkloadCard
                
                // Card 3: Circadian Dopamine Depletion & Fatigue Cycle
                circadianDopamineCard
                
                // Card 4: Autonomous Persona Graph Exporter & Auto-Simulation
                personaGraphExporterCard
            }
            .padding(12)
        }
        .background(ActionLensTheme.panelBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
    
    // MARK: - Neuro-Motor Invariance Card
    private var neuroMotorInvarianceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("NEURO-MOTOR BIOMETRIC INVARIANCE", systemImage: "waveform.path.ecg")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.amberAccent)
                
                Spacer()
                
                let dSq = manager.activeCognitiveTwin?.mahalanobisDistanceSq ?? 1.42
                Text(String(format: "D_M²: %.2f [χ²(3) < 14.16]", dSq))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.cyanAccent)
            }
            
            HStack(spacing: 8) {
                biometricCell(
                    title: "DWELL CENTROID",
                    value: String(format: "%.1f ms", manager.activeCognitiveTwin?.neuroMotorFingerprint.first ?? 68.4),
                    sub: "σ = 12.1ms • Contact",
                    color: ActionLensTheme.mintAccent
                )
                biometricCell(
                    title: "FLIGHT MICRO-GAP",
                    value: String(format: "%.1f ms", manager.activeCognitiveTwin?.neuroMotorFingerprint.dropFirst(2).first ?? 94.2),
                    sub: "σ = 16.5ms • Cadence",
                    color: ActionLensTheme.cyanAccent
                )
                biometricCell(
                    title: "SURFACE FORCE",
                    value: String(format: "%.0f%%", (manager.activeCognitiveTwin?.neuroMotorFingerprint.dropFirst(4).first ?? 0.54) * 100),
                    sub: "σ = 0.08 • Evdev",
                    color: ActionLensTheme.amberAccent
                )
            }
            
            // Invariance Gauge Bar
            let conf = manager.activeCognitiveTwin?.identityConfidencePct ?? 99.4
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("OPERATOR ZERO-KNOWLEDGE CERTAINTY")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(ActionLensTheme.textTertiary)
                    Spacer()
                    Text(String(format: "%.1f%%", conf))
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(ActionLensTheme.mintAccent)
                }
                
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.06))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [ActionLensTheme.cyanAccent, ActionLensTheme.mintAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: g.size.width * CGFloat(conf / 100.0))
                    }
                }
                .frame(height: 4)
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
    
    // MARK: - Prefrontal Workload Card
    private var prefrontalWorkloadCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("PREFRONTAL COGNITIVE WORKLOAD & ENTROPY", systemImage: "brain")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.cyanAccent)
                
                Spacer()
                
                let state = manager.activeCognitiveTwin?.prefrontalFlowState ?? "Deep Flow (Synchronized)"
                Text(state.uppercased())
                    .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    .foregroundColor(state.contains("Saturation") ? ActionLensTheme.coralAccent : ActionLensTheme.mintAccent)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background((state.contains("Saturation") ? ActionLensTheme.coralAccent : ActionLensTheme.mintAccent).opacity(0.12))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
            }
            
            HStack(spacing: 8) {
                let load = manager.activeCognitiveTwin?.cognitiveWorkloadScore ?? 28.4
                biometricCell(
                    title: "WORKLOAD INDEX",
                    value: String(format: "%.1f / 100", load),
                    sub: load < 35 ? "Optimal Flow" : "Cognitive Drag",
                    color: load < 35 ? ActionLensTheme.mintAccent : ActionLensTheme.amberAccent
                )
                
                let entropy = manager.psychometricState.shannonEntropyBits
                biometricCell(
                    title: "SHANNON ENTROPY",
                    value: String(format: "%.2f bits", entropy),
                    sub: "H(T) Inter-Actuation",
                    color: ActionLensTheme.cyanAccent
                )
                
                let paralysis = manager.activeCognitiveTwin?.decisionParalysisRiskPct ?? 8.5
                biometricCell(
                    title: "PARALYSIS RISK",
                    value: String(format: "%.1f%%", paralysis),
                    sub: "Hesitation Dispersion",
                    color: paralysis > 40 ? ActionLensTheme.coralAccent : ActionLensTheme.mintAccent
                )
            }
        }
        .padding(10)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
    
    // MARK: - Circadian Dopamine Card
    private var circadianDopamineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("CIRCADIAN DOPAMINE & KINETIC FATIGUE", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.purpleAccent)
                
                Spacer()
                
                let latency = manager.activeCognitiveTwin?.predictedActionLatencyMs ?? 192.0
                Text(String(format: "PRED LATENCY: %.0fms", latency))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.purpleAccent)
            }
            
            let dopamine = manager.activeCognitiveTwin?.circadianDopamineIndex ?? 92.0
            HStack(spacing: 8) {
                biometricCell(
                    title: "DOPAMINE PHASE",
                    value: String(format: "%.0f%%", dopamine),
                    sub: dopamine > 80 ? "Morning Alertness" : "Fatigue Window",
                    color: ActionLensTheme.purpleAccent
                )
                
                biometricCell(
                    title: "MOTOR VELOCITY",
                    value: "\(Int(manager.currentWPM)) WPM",
                    sub: "Typing Execution Rate",
                    color: ActionLensTheme.amberAccent
                )
                
                biometricCell(
                    title: "SENSORS INGESTED",
                    value: "\(manager.activeCognitiveTwin?.totalVectorsProcessed ?? 52)",
                    sub: "Continuous Stream",
                    color: ActionLensTheme.cyanAccent
                )
            }
        }
        .padding(10)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
    
    // MARK: - Persona Graph Exporter & Auto-Simulation Card
    private var personaGraphExporterCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("AUTONOMOUS PERSONA GRAPH & SIMULATION", systemImage: "cpu")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.mintAccent)
                Spacer()
                Text("C4ISR v2.4")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(ActionLensTheme.textTertiary)
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                // Auto-Simulation Toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        manager.toggleAutoSimulation()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text(manager.isAutoSimulationEnabled ? "AUTO-SIM: ACTIVE" : "AUTO-SIM: OFF")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(manager.isAutoSimulationEnabled ? ActionLensTheme.cyanAccent : ActionLensTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5.5)
                    .background(manager.isAutoSimulationEnabled ? ActionLensTheme.cyanAccent.opacity(0.18) : Color.white.opacity(0.04))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(manager.isAutoSimulationEnabled ? ActionLensTheme.cyanAccent.opacity(0.7) : ActionLensTheme.border, lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Simulate autonomous user actuations based on predictive intention vectors")
                
                // Export JSON Button
                Button(action: {
                    _ = manager.triggerExportPersonaGraph()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 10))
                        Text("EXPORT GRAPH (.JSON)")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(ActionLensTheme.amberAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5.5)
                    .background(ActionLensTheme.amberAccent.opacity(0.12))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(ActionLensTheme.amberAccent.opacity(0.6), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Export complete Persona Graph JSON tensor model")
                
                // Export CoreML Weights Button
                Button(action: {
                    _ = manager.triggerExportCoreMLWeights()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))
                        Text("EXPORT COREML")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(ActionLensTheme.purpleAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5.5)
                    .background(ActionLensTheme.purpleAccent.opacity(0.12))
                    .cornerRadius(ActionLensTheme.tacticalRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                            .stroke(ActionLensTheme.purpleAccent.opacity(0.6), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Export CoreML Neural Weights for Apple Neural Engine execution")
            }
            
            // Simulated Actuation HUD (if auto-simulation active)
            if manager.isAutoSimulationEnabled, let sim = manager.latestSimulatedActuation {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("LATEST PREDICTIVE AUTO-SIMULATION EVENT")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.cyanAccent)
                        Spacer()
                        Text(String(format: "LEAD: %.0fms", sim.leadTimeMs))
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(ActionLensTheme.amberAccent)
                    }
                    
                    HStack(spacing: 8) {
                        Text(String(format: "TARGET: (%.3f, %.3f)", sim.targetX, sim.targetY))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white)
                        Text(String(format: "FORCE: %.0f%%", sim.simulatedForce * 100))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(ActionLensTheme.mintAccent)
                        Text(String(format: "ARC: %.1f°", sim.simulatedArcDeg))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(ActionLensTheme.cyanAccent)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(ActionLensTheme.tacticalRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                        .stroke(ActionLensTheme.cyanAccent.opacity(0.4), lineWidth: 0.8)
                )
            }
        }
        .padding(10)
        .background(ActionLensTheme.cardBackground)
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border, lineWidth: 0.8)
        )
    }
    
    private func biometricCell(title: String, value: String, sub: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(ActionLensTheme.textTertiary)
            Text(value)
                .font(.system(size: 12.5, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(sub)
                .font(.system(size: 7.5, design: .monospaced))
                .foregroundColor(ActionLensTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(Color.white.opacity(0.025))
        .cornerRadius(ActionLensTheme.tacticalRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ActionLensTheme.tacticalRadius)
                .stroke(ActionLensTheme.border.opacity(0.6), lineWidth: 0.6)
        )
    }
}
