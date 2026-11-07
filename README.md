# 🔭 ActionLens — Cross-Platform Interaction Telemetry & Semantic Narrative Engine

An ultra-responsive native macOS application and CLI tool that performs live spatial tracking across both your **Mac** and your **ADB-connected Android phone** — measuring clicks, taps, directional swipes, keystroke cadence, and synthesizing an ongoing chronicle of your workflow in **articulate, natural English prose**.

---

## 🌟 Key Capabilities

### 1. Dual-Device Architecture & Instant Device Switching
- **Segmented Device Switcher**: Seamlessly switch between **[💻 Mac Display]**, **[📱 Phone Display]**, and **[⚡ Unified Dual]** with a single click.
- **Mac Telemetry**: Captures mouse clicks (left/right/double/drag), cursor coordinates $(X, Y)$, frontmost macOS applications, and deep UI elements via Apple Accessibility (`AXUIElementCopyElementAtPosition`).
- **Android ADB Telemetry**: Connects directly to your ADB-attached phone (`100.98.113.116:5555`, Redmi Note 13 Pro 5G `garnet_in`), captures physical touchscreen evdev coordinates, and dynamically tracks foreground apps (`dumpsys window`).

### 2. Touch Taps & Directional Swipes on Phone
- **Tap & Long-Press Interception**: Resolves screen pixel coordinates $(X, Y)$ on the phone display ($1220 \times 2712$), identifying whether you tapped or long-pressed within an active Android application (YouTube, WhatsApp, Telegram, Chrome, Settings).
- **Directional Swipes & Gestures**:
  - Automatically calculates vector displacement $(\Delta X, \Delta Y)$, swipe distance, and velocity ($px/s$).
  - **Swipe Up**: Scans feeds and lists downward with velocity and pixel distance.
  - **Swipe Down**: Pull-to-refresh or scrolling upward.
  - **Swipe Left / Right**: View transitions, forward browsing, or back gestures.

### 3. Mac Keystroke Inference & Flow States
- **Typing Bursts & Speedometer**: Real-time WPM calculation with inter-key latency tracking.
- **Flow State Classification**: `Thoughtful Cadence` (<40 WPM), `Steady Composition` (40–75 WPM), `Deep Flow State` (75–100 WPM), and `Rapid Sprint` (100+ WPM).
- **Shortcut Decoder**: Translates hotkeys (`Cmd+C`, `Cmd+V`, `Cmd+Z`, `Cmd+S`, `Cmd+Space`, `Cmd+Tab`) into descriptive actions.
- **Privacy Guardian**: Automatically detects password fields (`AXSecureTextField`) and masks sensitive credentials.

### 4. Natural English Narrative Engine
- Formulates fluent sentences in real-time describing your actions across both devices:
  - *"On your Phone (garnet), you swiped up (640 px at ~1420 px/s) to scroll down your feed in YouTube."*
  - *"On your Phone, you tapped at (540, 1120) inside WhatsApp."*
  - *"You clicked the primary 'Submit' button in Google Chrome [Antigravity Chat] at (1240, 890)."*
  - *"In Visual Studio Code, you entered an energetic 48-character typing sprint at 88 WPM."*
- **Autonomous Session Storybook**: Writes continuous multi-paragraph executive summaries comparing your time and interactions across Mac and Android.

### 5. Multi-Device GUI & Radar Visualizer
- **Dual Display Radar**:
  - **Mac Mode**: Displays a widescreen monitor grid showing mouse clicks as glowing cyan ripples.
  - **Phone Mode**: Transforms into a sleek vertical phone frame with bezel and notch, plotting taps and drawing **glowing animated directional swipe vectors with arrows**!
  - **Unified Mode**: Tracks both devices concurrently in real time.
- **Mini Floating HUD**: Shrinks the dashboard into a compact translucent pill that stays pinned to the desktop.
- **1-Click Markdown Export**: Copies or writes directly into Obsidian Vault (`~/Documents/DOCUMENTS/ObsidianVault/ActionLens/`).

---

## 🚀 Usage & Commands

### Launch Native macOS GUI
```bash
# Launch GUI directly (defaults to Unified Dual Mode)
actionlens

# Or via macOS open command
open /Applications/ActionLens.app
```

### Stream Live Telemetry to Terminal
```bash
# Stream Unified Mac + Phone interactions
actionlens live

# Stream strictly Phone taps & swipes
actionlens live --phone

# Stream strictly Mac clicks & typing
actionlens live --mac
```

### Verify System & ADB Diagnostics
```bash
actionlens status
```

---

## 🛠 Project Structure

```
~/Developer/personal/ActionLens/
├── Package.swift                  # Swift 6.4 Package Manifest (macOS 14+)
├── Info.plist                     # App metadata & Accessibility permissions
├── Sources/
│   ├── ActionLensCore/            # Core Telemetry Engine
│   │   ├── Models.swift           # ActionRecord, SwipeMetadata, DeviceTarget
│   │   ├── MouseTracker.swift     # macOS global & local mouse hooks
│   │   ├── AccessibilityInspector.swift  # AXUIElement introspection
│   │   ├── KeystrokeInferenceEngine.swift # WPM & keystroke burst analysis
│   │   ├── PhoneTracker.swift     # ADB kernel evdev touch/swipe stream
│   │   ├── NarrativeEngine.swift  # English narrative generator
│   │   ├── SessionManager.swift   # ObservableObject multi-device orchestrator
│   │   └── MarkdownExporter.swift # Markdown dossier & ObsidianVault exporter
│   ├── ActionLensApp/             # SwiftUI Native GUI
│   │   ├── ActionLensApp.swift    # App entry point
│   │   ├── Theme.swift            # Obsidian dark glass styling
│   │   ├── MainView.swift         # Master split dashboard & device switcher
│   │   └── Components/
│   │       ├── LiveNarrativeFeedView.swift   # Live English story cards
│   │       ├── ClickRadarView.swift          # Mac & Phone radar canvases
│   │       ├── KeystrokeTelemetryView.swift  # WPM speedometer & analytics
│   │       ├── SessionStorybookView.swift    # Executive session story & export
│   │       └── MiniHUDView.swift             # Floating translucent widget
│   └── ActionLensCLI/             # Command-Line Utility
│       └── main.swift             # CLI runner (`actionlens gui|live|status`)
└── scripts/
    └── package_app.sh             # Release compilation, packaging & signing
```

---

## 📄 License
Copyright © 2026 OpenFrontier Labs. Built for Principal Systems Engineer Anurag Pareek (@krsna016).
