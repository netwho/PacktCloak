# PacketCloak Project Summary

## Project Overview

**PacketCloak** is a Wireshark Lua dissector that provides real-time anonymization and cloaking of sensitive packet data directly in the Wireshark GUI, without modifying the underlying PCAP files.

**Version:** 0.2.0  
**Created:** December 8, 2025  
**License:** GPL-2.0
**Language:** Lua 5.1/5.2  
**Platform:** Wireshark 3.0+ (macOS, Linux, Windows)

## Project Origin

This project was created as a transformation of the Python/Scapy-based **PacketSanitizer** tool into a native Lua Wireshark dissector. The goal was to provide real-time cloaking capabilities within Wireshark rather than creating sanitized PCAP files.

### Key Difference from PacketSanitizer:
- **PacketSanitizer**: Reads input PCAP → Creates sanitized output PCAP
- **PacketCloak**: Displays cloaked data in Wireshark GUI → Original PCAP unchanged

## Core Features

### 1. Three Cloaking Modes

#### Mode: OFF (Default)
- Normal Wireshark operation
- No anonymization applied
- All data visible as-is

#### Mode: CLOAK_DATA
- Anonymizes payload data only
- IP/MAC addresses remain visible
- Use case: Hide sensitive application data while showing network topology

#### Mode: CLOAK_ALL
- Anonymizes both addresses AND payloads
- Maximum privacy protection
- Use case: Complete anonymization for demos, training, or sharing

### 2. Address Anonymization

**IPv4:**
- Maps real IPs to 10.0.0.0/8 range
- Maintains conversation flows (same IP → same anonymized IP)

**IPv6:**
- Maps real IPs to fd00::/8 range (unique local addresses)
- Maintains conversation flows

**MAC Addresses:**
- Maps to 02:00:00:00:00:XX range (locally administered)
- Maintains device identity across packets

### 3. Payload Sanitization

- TCP, UDP, ICMP payloads replaced with 0x5341 pattern ("SA" = Sanitized)
- Original payload length preserved
- Protocol headers remain intact for analysis

### 4. Smart Protocol Handling

- IGMP packets preserved (not cloaked) for protocol analysis
- Post-dissector architecture works with all protocols
- Preserves packet timing, sizes, and structure

### 5. User Interface

**Visual Indicators:**
- `[CLOAKED]` prefix in Info column
- PacketCloak subtree in packet details
- Shows cloaked values for verification

**Control Methods:**
1. Preferences: Edit → Preferences → Protocols → PACKETCLOAK (persistent)
2. Menu: Tools → PacketCloak (session-only toggles)
3. Direct editing of Lua script (advanced)

## Project Structure

```
PacketCloak/
├── PacketCloak.lua       # Main dissector (11KB, 349 lines)
├── README.md             # Project overview and features
├── QUICKSTART.md         # 5-minute getting started guide
├── USAGE.md              # Detailed usage documentation
├── CHANGELOG.md          # Version history
├── PROJECT_SUMMARY.md    # This file
├── LICENSE               # GPL-2.0 License
├── VERSION               # Version number (0.2.0)
├── install.sh            # Installation script (macOS/Linux)
└── .gitignore            # Git ignore rules
```

## Technical Architecture

### Implementation Approach

**Post-Dissector Pattern:**
- Runs after all standard Wireshark dissectors
- Intercepts display values before rendering
- Modifies `pinfo.cols` (column information)
- Adds subtree to packet details

**State Management:**
- Global dictionaries for IP/MAC mappings
- Counter-based sequential anonymization
- Mappings reset on mode change or restart

**Lua API Usage:**
- `Proto()` - Protocol definition
- `ProtoField.*` - Field definitions
- `register_postdissector()` - Registration
- `register_menu()` - Menu integration
- `Pref.enum()` - Preferences

### Code Organization

1. **Configuration** (lines 19-30)
   - Constants and mode definitions

2. **State Management** (lines 33-48)
   - Global variables and mappings

3. **Anonymization Functions** (lines 51-138)
   - IPv4/IPv6/MAC anonymizers
   - Payload sanitizer

4. **Mode Toggle Functions** (lines 141-175)
   - Toggle handlers
   - Mapping reset logic

5. **Protocol Detection** (lines 178-187)
   - IGMP detection

6. **Main Dissector** (lines 190-291)
   - Core cloaking logic
   - Address and payload handling

7. **Registration** (lines 294-347)
   - Post-dissector registration
   - Menu integration
   - Preferences setup

## Use Cases

### 1. Screen Sharing & Demos
**Problem:** Sensitive data visible during presentations  
**Solution:** CLOAK_ALL mode anonymizes everything

### 2. Training & Education
**Problem:** Teaching with real captures containing sensitive info  
**Solution:** CLOAK_DATA mode hides data while showing network flows

### 3. Documentation & Screenshots
**Problem:** Screenshots expose real infrastructure  
**Solution:** Enable cloaking, capture screenshots, toggle back

### 4. Third-Party Analysis
**Problem:** Need help but can't share actual data  
**Solution:** Export cloaked dissections as text

## Installation & Usage

### Quick Install
```bash
cd /Users/walterh/Github-Projects/PacketCloak
./install.sh
```

### Quick Test
```bash
# Generate test traffic
ping -c 5 8.8.8.8

# In Wireshark:
# 1. Capture the traffic
# 2. Tools → PacketCloak → Toggle CLOAK_ALL
# 3. Press Ctrl+R to reload
# 4. See 10.0.0.X addresses instead of real IPs
```

## Limitations & Constraints

### By Design:
1. **Display-only** - Exported PCAPs contain original data
2. **Reload required** - Mode changes need Ctrl+R to apply
3. **IGMP preserved** - Not cloaked for analysis purposes

### Technical:
1. Performance impact on very large captures (>100K packets)
2. Some custom dissectors may bypass cloaking
3. Keyboard shortcuts require manual Wireshark configuration
4. Column modifications have limitations in Lua API

### Future Considerations:
- Real-time toggling without reload
- Export functionality for cloaked PCAPs
- Per-protocol cloaking rules
- Performance optimizations

## Comparison: PacketCloak vs PacketSanitizer

| Feature | PacketCloak | PacketSanitizer |
|---------|-------------|-----------------|
| **Implementation** | Lua (Wireshark) | Python (Scapy) |
| **Purpose** | Display cloaking | File sanitization |
| **Output** | Visual only | New PCAP file |
| **Mode Toggle** | Real-time (reload) | N/A |
| **Performance** | Fast (in-memory) | Slower (file I/O) |
| **Use Case** | Demos, screen share | Sharing captures |
| **Original Data** | Preserved | Modified |
| **Dependencies** | Wireshark only | Python, Scapy |

## Development Notes

### Transformation from Python to Lua

**Python/Scapy Concepts → Lua/Wireshark Equivalents:**
- `rdpcap()/wrpcap()` → Not needed (Wireshark handles file I/O)
- `Ether()/IP()/TCP()` layers → `pinfo` packet info structure
- Packet reconstruction → Column/field modification
- File output → Display modification
- Iteration over packets → Per-packet dissector callback

**Key Challenges Addressed:**
1. **No direct payload modification** - Lua dissectors can't modify packet bytes
   - Solution: Indicate cloaking via subtree and columns
2. **State persistence** - Mappings need to survive across packets
   - Solution: Global Lua tables for IP/MAC mappings
3. **User interaction** - Python script has CLI, Lua needs GUI integration
   - Solution: Preferences + menu integration

## Testing Strategy

### Basic Tests:
- OFF mode: Verify normal operation
- CLOAK_DATA mode: Verify payloads cloaked, addresses visible
- CLOAK_ALL mode: Verify everything cloaked

### Advanced Tests:
- Conversation flow preservation
- Performance with large captures
- Protocol coverage (TCP, UDP, ICMP, ARP, IPv6)
- IGMP preservation
- Mode toggle functionality

### Integration Tests:
- Installation script
- Preferences persistence
- Menu integration
- Multiple Wireshark versions

## Future Roadmap

### Version 1.1 (Planned):
- Direct keyboard shortcut support
- Real-time mode toggle (no reload)
- Performance optimizations
- Enhanced protocol coverage

### Version 1.2 (Planned):
- Export cloaked PCAPs
- Configuration file support
- Per-protocol cloaking rules
- Whitelist/blacklist for addresses

### Version 2.0 (Ideas):
- GUI control panel
- Custom cloaking patterns
- Advanced filtering rules
- Multi-language support

## Documentation

### For Users:
- **QUICKSTART.md** - 5-minute setup and first use
- **README.md** - Feature overview and installation
- **USAGE.md** - Comprehensive usage guide with examples

### For Developers:
- **PacketCloak.lua** - Well-commented source code
- **CHANGELOG.md** - Version history and changes
- **PROJECT_SUMMARY.md** - This document (architecture and design)

## Contributing

### Areas for Contribution:
1. Performance optimization for large captures
2. Additional protocol support
3. Enhanced payload cloaking strategies
4. Cross-platform testing
5. Documentation improvements
6. Bug fixes and edge cases

### Code Style:
- Lua 5.1/5.2 compatible
- Descriptive function names
- Inline comments for complex logic
- Consistent indentation (4 spaces)

## License

GPL-2.0 License - See LICENSE file for full text.

Free for use, modification, and distribution under GPL-2.0 terms.

## Acknowledgments

- Inspired by **PacketSanitizer** (Python/Scapy implementation)
- Built with Wireshark's powerful Lua API
- Designed for network analysts, educators, and security professionals

---

**Project Status:** ✅ Production Ready (v0.2.0)
**Maintenance:** Active  
**Support:** Community-driven

For questions, issues, or contributions, please open a GitHub issue or pull request.
