#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP="/Applications/ActionLens.app"
BIN_DIR="$HOME/.local/bin"

echo "🔨 Compiling ActionLens release binaries with Apple Swift 6.4..."
cd "$ROOT"
swift build --disable-sandbox -c release -debug-info-format none

PRODUCTS="$(swift build --disable-sandbox -c release -debug-info-format none --show-bin-path)"
APP_BIN="$PRODUCTS/ActionLensApp"
CLI_BIN="$PRODUCTS/actionlens"

echo "📦 Packaging /Applications/ActionLens.app..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$BIN_DIR"

# Install GUI Binary
cp -f "$APP_BIN" "$APP/Contents/MacOS/ActionLens"
chmod +x "$APP/Contents/MacOS/ActionLens"

# Install Info.plist
cp -f "$ROOT/Info.plist" "$APP/Contents/Info.plist"

# Install CLI Binary
cp -f "$CLI_BIN" "$BIN_DIR/actionlens"
chmod +x "$BIN_DIR/actionlens"

# Codesign App
echo "✍️  Codesigning ActionLens.app..."
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "✅ ActionLens successfully built and installed:"
echo "   • GUI App: $APP"
echo "   • CLI Tool: $BIN_DIR/actionlens"
