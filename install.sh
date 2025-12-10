#!/bin/bash
#
# PacketCloak Installer for macOS/Linux
# Installs the PacketCloak Lua dissector to Wireshark's plugin directory
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_FILE="PacketCloak.lua"
PLUGIN_PATH="$SCRIPT_DIR/$PLUGIN_FILE"

# Detect OS
OS="$(uname -s)"

# Determine Wireshark plugin directory
case "$OS" in
    Darwin)
        # macOS - Prefer .local directory for consistency
        WIRESHARK_PLUGIN_DIR="$HOME/.local/lib/wireshark/plugins"
        ;;
    Linux)
        # Linux
        WIRESHARK_PLUGIN_DIR="$HOME/.local/lib/wireshark/plugins"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        # Windows
        WIRESHARK_PLUGIN_DIR="$APPDATA/Wireshark/plugins"
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

echo "╔══════════════════════════════════════════╗"
echo "║     PacketCloak Installer v0.2.1         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "OS detected: $OS"
echo "Plugin directory: $WIRESHARK_PLUGIN_DIR"
echo ""

# Check if plugin file exists
if [ ! -f "$PLUGIN_PATH" ]; then
    echo "Error: $PLUGIN_FILE not found in $SCRIPT_DIR"
    exit 1
fi

# Create plugin directory if it doesn't exist
if [ ! -d "$WIRESHARK_PLUGIN_DIR" ]; then
    echo "Creating plugin directory: $WIRESHARK_PLUGIN_DIR"
    mkdir -p "$WIRESHARK_PLUGIN_DIR"
fi

# Check if plugin already exists
if [ -f "$WIRESHARK_PLUGIN_DIR/$PLUGIN_FILE" ]; then
    echo "Warning: $PLUGIN_FILE already exists in plugin directory"
    read -p "Overwrite existing plugin? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Copy plugin to Wireshark directory
echo "Installing $PLUGIN_FILE to $WIRESHARK_PLUGIN_DIR"
cp "$PLUGIN_PATH" "$WIRESHARK_PLUGIN_DIR/"

# Verify installation
if [ -f "$WIRESHARK_PLUGIN_DIR/$PLUGIN_FILE" ]; then
    echo ""
    echo "✓ Installation successful!"
    echo ""
    echo "Next steps:"
    echo "1. Restart Wireshark or reload Lua plugins (Ctrl+Shift+L)"
    echo "2. Go to Edit → Preferences → Protocols → PACKETCLOAK"
    echo "3. Set your default cloaking mode"
    echo "4. Use Tools → PacketCloak menu to toggle modes"
    echo ""
    echo "For more information, see README.md"
else
    echo ""
    echo "✗ Installation failed!"
    echo "Please check permissions and try again"
    exit 1
fi
