# Changelog

All notable changes to PacketCloak will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.16] - 2025-12-10

### Changed
- Updated documentation to match PacketReporter style with badges and emoji sections
- Enhanced README.md with comprehensive feature list and visual hierarchy
- Improved QUICKSTART.md with emoji section headers
- Updated USAGE.md with better organization and emoji headers
- Synced VERSION file with Lua implementation version

### Documentation
- Added badge section with version, status, license, and platform information
- Added visual indicators and emojis throughout documentation
- Improved quick start section with clearer installation instructions
- Enhanced troubleshooting section with better formatting
- Added example workflows section

## [0.2.0] - 2025-12-08

### Added
- Initial release of PacketCloak Wireshark dissector
- Three cloaking modes: OFF, CLOAK_DATA, CLOAK_ALL
- Real-time anonymization of IP addresses (IPv4 and IPv6)
- Real-time anonymization of MAC addresses
- Payload data sanitization with 0x5341 pattern
- Stateful address mapping to maintain conversation flows
- Post-dissector implementation for compatibility with all protocols
- Wireshark preferences integration for mode selection
- Menu integration for toggling modes (Tools → PacketCloak)
- IGMP packet preservation (no cloaking applied)
- Visual indicators in Info column ([CLOAKED] prefix)
- PacketCloak subtree in packet details showing cloaked values
- Comprehensive documentation (README, USAGE, CHANGELOG)
- Installation script for macOS/Linux
- GPL-2.0 License

### Features
- **Mode: OFF** - Normal Wireshark operation, no cloaking
- **Mode: CLOAK_DATA** - Anonymize payloads only, keep addresses visible
- **Mode: CLOAK_ALL** - Anonymize both payloads and addresses
- Consistent address mapping across packet capture
- IPv4 anonymization to 10.0.0.0/8 range
- IPv6 anonymization to fd00::/8 range
- MAC anonymization to 02:00:00:00:00:XX range
- Preservation of protocol headers and analysis capabilities

### Known Limitations
- Cloaking is display-only; exported PCAPs retain original data
- Keyboard shortcuts require manual Wireshark configuration
- Some performance impact on very large captures (>100K packets)
- Custom dissectors may bypass cloaking in some edge cases
- Mode changes require capture reload (Ctrl+R) to apply

### Compatibility
- Wireshark 3.0+
- Lua 5.1/5.2 (bundled with Wireshark)
- Tested on macOS, Linux, Windows

## [Unreleased]

### Planned Features
- Direct keyboard shortcut registration
- Real-time mode toggling without reload
- Export functionality for cloaked PCAPs
- Configuration file for persistent settings
- Additional cloaking patterns
- Per-protocol cloaking rules
- Whitelist/blacklist for specific addresses
- Performance optimizations for large captures

---

[0.2.0]: https://github.com/yourusername/PacketCloak/releases/tag/v0.2.0
