# PacketCloak

[![Version](https://img.shields.io/badge/version-0.2.16-blue.svg)](CHANGELOG.md)
[![Status](https://img.shields.io/badge/status-stable-green.svg)](CHANGELOG.md)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](LICENSE)
[![Wireshark](https://img.shields.io/badge/Wireshark-3.0%2B-1679A7.svg)](https://www.wireshark.org/)
[![Lua](https://img.shields.io/badge/Lua-5.1%2B-000080.svg)](https://www.lua.org/)
[![macOS](https://img.shields.io/badge/macOS-10.14%2B-000000.svg?logo=apple)](install.sh)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%20|%20Fedora%20|%20Arch-FCC624.svg?logo=linux&logoColor=black)](install.sh)
[![Windows](https://img.shields.io/badge/Windows-10%2B-0078D6.svg?logo=windows)](install.sh)

A Wireshark plugin for real-time anonymization and cloaking of sensitive packet data directly in the Wireshark GUI.

> **💡 Key Feature**: Cloak sensitive data in real-time without modifying the original PCAP file. Perfect for screen sharing, demos, training, and presentations.

## ✨ Features

- 🔒 **Three Cloaking Modes** - OFF, CLOAK_DATA (payloads only), CLOAK_ALL (addresses + payloads)
- 🎯 **Real-time Anonymization** - Toggle cloaking on/off instantly with keyboard shortcuts
- 🔄 **Conversation Flow Preservation** - Same IPs map to same anonymized IPs across packets
- 🌐 **IPv4 & IPv6 Support** - Full support for both IP versions
- 💻 **MAC Address Cloaking** - Anonymizes MAC addresses while maintaining device identity
- 🎨 **Visual Indicators** - Clear [CLOAKED] markers in Info column
- ⚡ **Fast Performance** - Post-dissector architecture for efficiency
- 📁 **PCAP Preservation** - Original capture files remain unchanged
- ⌨️ **Keyboard Shortcuts** - Quick mode toggling (configurable)
- 🚀 **Wireshark Integrated** - Pure Lua implementation running directly from Wireshark

## 📸 Screenshots

### PacketCloak Menu

Access the plugin from the Wireshark menu:
```
Tools → PacketCloak → Toggle CLOAK_ALL
```

*Note: Add screenshots showing before/after cloaking modes*

## 🚀 Quick Start

### Installation

**Platform-specific installation:**

**macOS/Linux:**
```bash
git clone https://github.com/yourusername/PacketCloak.git
cd PacketCloak
./install.sh
```

**Manual installation:**
```bash
# macOS/Linux
cp PacketCloak.lua ~/.local/lib/wireshark/plugins/

# Windows
copy PacketCloak.lua %APPDATA%\Wireshark\plugins\
```

### Usage

1. **Load a capture file** in Wireshark or start live capture
2. **Configure shortcuts** (optional): Edit → Preferences → Shortcuts, search for `PacketCloak`
3. **Toggle mode**: Tools → PacketCloak → Toggle CLOAK_ALL (or use keyboard shortcut)
4. **Reload capture**: Press **Ctrl+R** (Cmd+R on macOS) to apply changes
5. **Verify cloaking**: Look for `[CLOAKED]` prefix in Info column

See [QUICKSTART.md](QUICKSTART.md) for detailed guide.

## 📋 Cloaking Modes

### Mode 1: OFF (Default)
Normal Wireshark operation with no anonymization.

**Best for:** Regular analysis when privacy isn't a concern

### Mode 2: CLOAK_DATA
Anonymizes payload data only; IP and MAC addresses remain visible.

**What gets cloaked:**
- TCP, UDP, ICMP payloads
- Raw packet data

**What stays visible:**
- IP addresses (source and destination)
- MAC addresses
- Port numbers and protocol headers

**Best for:** Hiding sensitive application data while showing network topology

### Mode 3: CLOAK_ALL
Anonymizes both addresses AND payload data for maximum privacy.

**What gets cloaked:**
- IPv4 addresses → Mapped to 10.0.0.0/8 range
- IPv6 addresses → Mapped to fd00::/8 range
- MAC addresses → Mapped to 02:00:00:00:00:XX range
- TCP/UDP/ICMP payloads
- ARP addresses

**What stays visible:**
- Port numbers
- Protocol types
- Packet timing and sizes
- TCP flags and sequence numbers

**Best for:** Maximum privacy during demos, training, or sharing captures

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute getting started guide
- **[USAGE.md](USAGE.md)** - Comprehensive usage guide with examples
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Architecture and technical details
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

## 🛠️ Requirements

### Required
- Wireshark 3.0 or later (includes Lua 5.1+)

### Supported Platforms
- **macOS**: 10.14+
- **Linux**: Ubuntu, Fedora, Arch, Debian
- **Windows**: 10+

## 💡 Example Workflows

**Live Demo with Sensitive Data:**
```bash
# Scenario: Presenting Wireshark capture on a video call
# Solution: Enable CLOAK_ALL mode before sharing screen
Tools → PacketCloak → Toggle CLOAK_ALL
Ctrl+R (reload)
```

**Training Session:**
```bash
# Scenario: Teaching network analysis with real captures
# Solution: Enable CLOAK_DATA to show topology, hide data
Tools → PacketCloak → Toggle CLOAK_DATA
Ctrl+R (reload)
```

**Screenshot for Documentation:**
```bash
# Scenario: Creating public documentation
# Solution: Toggle CLOAK_ALL, take screenshot, toggle back
Tools → PacketCloak → Toggle CLOAK_ALL
Ctrl+R (reload)
[Take screenshots]
Tools → PacketCloak → Toggle CLOAK_ALL (to disable)
```

## ⚙️ Technical Details

- **Language**: Pure Lua 5.1/5.2
- **Lines of Code**: ~350
- **Implementation**: Post-dissector pattern
- **State Management**: Global mappings for IP/MAC anonymization
- **Performance**: Efficient packet processing with minimal overhead
- **Compatibility**: Works with all Wireshark dissectors

## 🎯 Use Cases

- **Screen Sharing & Demos** - Present captures without exposing sensitive data
- **Training & Education** - Teach network analysis with real-world captures safely
- **Documentation** - Create screenshots and guides without revealing infrastructure
- **Third-Party Analysis** - Share captures with consultants while protecting privacy
- **Security Reviews** - Analyze traffic patterns without exposing actual addresses

## 🐛 Troubleshooting

### Plugin Not Loading?

**Check installation:**
```bash
ls -la ~/.local/lib/wireshark/plugins/PacketCloak.lua
```

**Verify in Wireshark:**
1. Help → About Wireshark → Plugins
2. Look for "PacketCloak.lua" in the list

**Reload plugins:**
- Press **Ctrl+Shift+L** (Cmd+Shift+L on macOS)

### Mode Changes Not Working?

**Solution:** Press **Ctrl+R** (Cmd+R on macOS) to reload the capture after changing modes.

### Performance Issues?

**For large captures:**
1. Apply display filters first to reduce packet count
2. Use CLOAK_DATA instead of CLOAK_ALL (less processing)
3. Close other applications to free memory

## 🔧 Configuration

Customize anonymization by editing `PacketCloak.lua`:

```lua
local SANITIZED_PATTERN = 0x5341  -- "SA" for Sanitized
local BASE_IP = "10.0.0.0"        -- Base IP for anonymization
local BASE_MAC_PREFIX = "02:00:00:00:00"  -- Base MAC prefix
```

## ⚠️ Limitations

- Cloaking is display-only; exported PCAPs retain original data
- Mode changes require capture reload (Ctrl+R) to apply
- Performance may be affected on very large captures (>100K packets)
- Some protocol-specific fields may not be fully cloaked
- IGMP packets are preserved for analysis purposes

## 📝 License

GNU General Public License v2 - see [LICENSE](LICENSE) file for details.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

## ❤️ Acknowledgments

- Wireshark development team for excellent Lua API
- Inspired by [PacketSanitizer](https://github.com/walterh/PacketSanitizer) project
- Network analysis community for feedback and suggestions

## 💬 Support & Contact

- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/PacketCloak/issues)
- 📚 **Documentation**: See docs in this repository
- ✨ **Contributing**: Contributions welcome! Please open issues or pull requests

## 🔗 Related Projects

- **[PacketSanitizer](https://github.com/walterh/PacketSanitizer)** - Python/Scapy tool for creating sanitized PCAP files (permanent anonymization)

---

**Built with ❤️ for the network analysis community**
