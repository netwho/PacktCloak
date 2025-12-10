# PacketCloak Installer for macOS

## Installation

### Option 1: Run the installer script (Recommended)

```bash
cd installers/macos
chmod +x install.sh
./install.sh
```

### Option 2: Manual installation

1. Copy `PacketCloak.lua` to your Wireshark plugins directory:
   ```bash
   cp ../../PacketCloak.lua ~/.local/lib/wireshark/plugins/
   ```

2. Restart Wireshark or reload Lua plugins (Cmd+Shift+L)

## Plugin Directories

The installer will try these directories in order:
1. `~/.local/lib/wireshark/plugins` (Preferred - user directory)
2. `~/Library/Application Support/Wireshark/plugins` (macOS user directory)
3. `/Applications/Wireshark.app/Contents/PlugIns/wireshark` (System-wide)

## Requirements

- macOS 10.13 (High Sierra) or later
- Wireshark 3.0 or later
- Bash shell

## Installing Wireshark

If you don't have Wireshark installed:

```bash
# Using Homebrew
brew install --cask wireshark

# Or download from
# https://www.wireshark.org/download.html
```

## Verification

After installation:
1. Open Wireshark
2. Go to: **Help → About Wireshark → Plugins**
3. Look for `PacketCloak.lua` with version 0.2.0

## Troubleshooting

### Permission denied
```bash
chmod +x install.sh
```

### Plugin not loading
1. Check Wireshark console: **View → Show Console**
2. Reload Lua plugins: **Cmd+Shift+L**
3. Verify file exists: `ls -la ~/.local/lib/wireshark/plugins/PacketCloak.lua`

## Author

Walter Hofstetter  
Repository: https://github.com/netwho/PacketCloak  
License: GPL-2.0
