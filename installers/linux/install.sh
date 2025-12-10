#!/bin/bash
#
# PacketCloak Installer for Linux
# Author: Walter Hofstetter
# License: GPL-2.0
# Repository: https://github.com/netwho/PacketCloak
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGIN_FILE="PacketCloak.lua"
PLUGIN_PATH="$PROJECT_ROOT/$PLUGIN_FILE"

# Linux Wireshark plugin directories (in order of preference)
# Note: .local/lib/wireshark/plugins is preferred for consistency across platforms
PLUGIN_DIRS=(
    "$HOME/.local/lib/wireshark/plugins"
    "$HOME/.config/wireshark/plugins"
    "/usr/lib/x86_64-linux-gnu/wireshark/plugins"
    "/usr/lib/wireshark/plugins"
)

echo "╔═══════════════════════════════════════════════╗"
echo "║   PacketCloak Installer for Linux v0.2.1      ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "Author: Walter Hofstetter"
echo "License: GPL-2.0"
echo ""

# Check if Wireshark is installed
if ! command -v wireshark &> /dev/null; then
    echo "⚠️  Warning: Wireshark does not appear to be installed."
    echo ""
    echo "Please install Wireshark first:"
    echo "  Debian/Ubuntu: sudo apt install wireshark"
    echo "  Fedora/RHEL:   sudo dnf install wireshark"
    echo "  Arch:          sudo pacman -S wireshark-qt"
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Check if plugin file exists
if [ ! -f "$PLUGIN_PATH" ]; then
    echo "❌ Error: $PLUGIN_FILE not found at $PLUGIN_PATH"
    exit 1
fi

# Find the first existing or create the preferred plugin directory
WIRESHARK_PLUGIN_DIR=""
for dir in "${PLUGIN_DIRS[@]}"; do
    if [ -d "$dir" ] || [ "$dir" = "${PLUGIN_DIRS[0]}" ]; then
        WIRESHARK_PLUGIN_DIR="$dir"
        break
    fi
done

echo "Target directory: $WIRESHARK_PLUGIN_DIR"
echo ""

# Check if we need sudo for system directories
NEED_SUDO=false
if [[ "$WIRESHARK_PLUGIN_DIR" == /usr/* ]]; then
    NEED_SUDO=true
    echo "⚠️  System directory requires elevated privileges"
fi

# Create plugin directory if it doesn't exist
if [ ! -d "$WIRESHARK_PLUGIN_DIR" ]; then
    echo "Creating plugin directory: $WIRESHARK_PLUGIN_DIR"
    if [ "$NEED_SUDO" = true ]; then
        sudo mkdir -p "$WIRESHARK_PLUGIN_DIR"
    else
        mkdir -p "$WIRESHARK_PLUGIN_DIR"
    fi
    
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to create plugin directory"
        exit 1
    fi
fi

# Check if plugin already exists
if [ -f "$WIRESHARK_PLUGIN_DIR/$PLUGIN_FILE" ]; then
    echo "⚠️  Warning: $PLUGIN_FILE already exists in plugin directory"
    read -p "Overwrite existing plugin? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Copy plugin to Wireshark directory
echo "Installing $PLUGIN_FILE to $WIRESHARK_PLUGIN_DIR"
if [ "$NEED_SUDO" = true ]; then
    sudo cp "$PLUGIN_PATH" "$WIRESHARK_PLUGIN_DIR/"
    sudo chmod 644 "$WIRESHARK_PLUGIN_DIR/$PLUGIN_FILE"
else
    cp "$PLUGIN_PATH" "$WIRESHARK_PLUGIN_DIR/"
    chmod 644 "$WIRESHARK_PLUGIN_DIR/$PLUGIN_FILE"
fi

# Verify installation
if [ -f "$WIRESHARK_PLUGIN_DIR/$PLUGIN_FILE" ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Launch Wireshark"
    echo "2. Reload Lua plugins: Ctrl+Shift+L"
    echo "3. Verify: Help → About Wireshark → Plugins (look for PacketCloak)"
    echo "4. Configure: Edit → Preferences → Protocols → PACKETCLOAK"
    echo "5. Toggle modes: Tools → PacketCloak menu"
    echo ""
    
    # Check if user is in wireshark group (for capture permissions)
    if groups | grep -q wireshark; then
        echo "✓ You are in the 'wireshark' group (capture permissions OK)"
    else
        echo "⚠️  Note: To capture packets without sudo, add yourself to wireshark group:"
        echo "   sudo usermod -aG wireshark $USER"
        echo "   Then log out and back in"
    fi
    echo ""
    
    echo "📖 Documentation:"
    echo "   README.md - Feature overview"
    echo "   QUICKSTART.md - 5-minute guide"
    echo "   USAGE.md - Comprehensive documentation"
    echo ""
    echo "🔗 Repository: https://github.com/netwho/PacketCloak"
else
    echo ""
    echo "❌ Installation failed!"
    echo "Please check permissions and try again"
    exit 1
fi
