# PacketCloak Installer for Linux

## Installation

### Option 1: Run the installer script (Recommended)

```bash
cd installers/linux
chmod +x install.sh
./install.sh
```

The script will automatically detect if `sudo` is needed for system directories.

### Option 2: Manual installation

1. Copy `PacketCloak.lua` to your Wireshark plugins directory:
   ```bash
   mkdir -p ~/.local/lib/wireshark/plugins
   cp ../../PacketCloak.lua ~/.local/lib/wireshark/plugins/
   ```

2. Restart Wireshark or reload Lua plugins (Ctrl+Shift+L)

## Plugin Directories

The installer will try these directories in order:
1. `~/.local/lib/wireshark/plugins` (Preferred - user directory)
2. `~/.config/wireshark/plugins` (Alternative user directory)
3. `/usr/lib/x86_64-linux-gnu/wireshark/plugins` (System-wide - Debian/Ubuntu)
4. `/usr/lib/wireshark/plugins` (System-wide - Other distros)

## Requirements

- Linux kernel 3.10 or later
- Wireshark 3.0 or later
- Bash shell

## Installing Wireshark

### Debian/Ubuntu
```bash
sudo apt update
sudo apt install wireshark
```

### Fedora/RHEL/CentOS
```bash
sudo dnf install wireshark
# or
sudo yum install wireshark
```

### Arch Linux
```bash
sudo pacman -S wireshark-qt
```

### Capturing without sudo

To capture packets without root privileges:

```bash
# Add yourself to the wireshark group
sudo usermod -aG wireshark $USER

# Log out and back in for changes to take effect
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
2. Reload Lua plugins: **Ctrl+Shift+L**
3. Verify file exists: `ls -la ~/.local/lib/wireshark/plugins/PacketCloak.lua`

### System directory installation failed
If installing to `/usr/lib/*` fails, the script will automatically use `sudo`.

## Author

Walter Hofstetter  
Repository: https://github.com/netwho/PacketCloak  
License: GPL-2.0
