# PacketCloak Usage Guide

This guide provides detailed instructions on how to use PacketCloak effectively.

## 📚 Table of Contents

- [Getting Started](#getting-started)
- [Cloaking Modes](#cloaking-modes)
- [Toggling Modes](#toggling-modes)
- [Use Cases](#use-cases)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## 🚀 Getting Started

### Installation Verification

After installing PacketCloak, verify it's loaded:

1. Open Wireshark
2. Go to **Help → About Wireshark → Plugins** tab
3. Look for `PacketCloak.lua` in the list
4. Check Wireshark's console output for:
   ```
   [PacketCloak] Loaded successfully!
   [PacketCloak] Current mode: OFF
   ```

### First Run

1. Open Wireshark
2. Load a packet capture file or start a live capture
3. The dissector runs automatically in OFF mode (showing real data)

## 📋 Cloaking Modes

### Mode 1: OFF (Default)

**What it does:**
- Shows all real packet data
- No anonymization applied
- Normal Wireshark operation

**When to use:**
- Regular analysis when privacy isn't a concern
- When you need to see actual addresses and data

**Indicator:**
- No `[CLOAKED]` prefix in Info column
- No PacketCloak subtree in packet details

### Mode 2: CLOAK_DATA

**What it does:**
- Anonymizes payload data only
- IP addresses remain visible
- MAC addresses remain visible
- Useful for hiding sensitive application data while maintaining network topology visibility

**What gets cloaked:**
- TCP payloads → Replaced with `0x5341` pattern ("SA")
- UDP payloads → Replaced with `0x5341` pattern
- ICMP payloads → Replaced with `0x5341` pattern
- Raw data layers → Replaced with `0x5341` pattern

**What stays visible:**
- IP addresses (both source and destination)
- MAC addresses
- Port numbers
- Protocol headers
- Packet structure

**When to use:**
- Demo scenarios where you want to show network flows
- When teaching network analysis but hiding actual data
- Reviewing captures with sensitive application data
- Sharing screen during presentations

**Indicator:**
- `[CLOAKED]` prefix appears in Info column
- PacketCloak subtree shows "Cloaking Mode: CLOAK_DATA"

### Mode 3: CLOAK_ALL

**What it does:**
- Anonymizes BOTH addresses AND payload data
- Maximum privacy protection
- Maintains conversation flows and device identity through consistent mapping

**What gets cloaked:**
- IPv4 addresses → Mapped to 10.0.0.0/8 range (e.g., 192.168.1.100 → 10.0.0.1)
- IPv6 addresses → Mapped to fd00::/8 range (e.g., 2001:db8::1 → fd00::1)
- MAC addresses → Mapped to 02:00:00:00:00:XX range
- TCP/UDP/ICMP payloads → Replaced with `0x5341` pattern
- ARP addresses → Anonymized

**What stays visible:**
- Port numbers
- Protocol types
- Packet timing
- Packet sizes
- TCP flags and sequence numbers
- Protocol-specific headers

**Mapping behavior:**
- Same original IP → Same anonymized IP (conversation flow preserved)
- Same original MAC → Same anonymized MAC (device identity preserved)
- Mappings reset when mode changes or Wireshark restarts

**When to use:**
- Maximum privacy scenarios
- Sharing captures with third parties
- Demo to customers/public without exposing any real infrastructure
- Training environments with real captures

**Indicator:**
- `[CLOAKED]` prefix in Info column
- PacketCloak subtree shows:
  - "Cloaking Mode: CLOAK_ALL"
  - "Cloaked Source IP: 10.0.0.X"
  - "Cloaked Destination IP: 10.0.0.Y"
  - "Cloaked Source MAC: 02:00:00:00:00:XX"
  - "Cloaked Destination MAC: 02:00:00:00:00:YY"

## 🔄 Toggling Modes

### Method 1: Via Preferences (Persistent)

1. Go to **Edit → Preferences**
2. Expand **Protocols** section
3. Find and select **PACKETCLOAK**
4. Choose "Default Mode" from dropdown:
   - OFF
   - CLOAK_DATA
   - CLOAK_ALL
5. Click **OK**
6. Reload capture (Ctrl+R) or refilter packets

**Note:** This setting persists across Wireshark sessions.

### Method 2: Via Menu (Session Only)

1. Go to **Tools → PacketCloak**
2. Select:
   - **Toggle CLOAK_ALL** - Switches between OFF and CLOAK_ALL
   - **Toggle CLOAK_DATA** - Switches between OFF and CLOAK_DATA
3. Reload capture (Ctrl+R) to apply changes

**Note:** These changes last only for the current Wireshark session.

### Method 3: Edit Lua Script (Advanced)

For quick testing or custom configurations:

1. Open `PacketCloak.lua` in a text editor
2. Find line: `local current_mode = MODE_OFF`
3. Change to desired mode:
   ```lua
   local current_mode = MODE_CLOAK_DATA  -- or MODE_CLOAK_ALL
   ```
4. Save and reload Lua plugins in Wireshark (Ctrl+Shift+L)

## 🎯 Use Cases

### Use Case 1: Live Demo with Customer Data

**Scenario:** You need to demonstrate network troubleshooting on a live call, but the capture contains customer IP addresses and sensitive data.

**Solution:**
1. Set mode to CLOAK_ALL
2. Reload capture
3. Share your screen - all addresses and data are anonymized
4. Analysis capabilities remain intact (protocol headers, timing, etc.)

### Use Case 2: Training Session

**Scenario:** Teaching network analysis to students using real-world captures with sensitive information.

**Solution:**
1. Set mode to CLOAK_DATA
2. Students can see network topology and flows
3. Actual payload data is hidden
4. Students learn analysis techniques without exposure to sensitive data

### Use Case 3: Screenshot for Documentation

**Scenario:** Creating documentation that includes Wireshark screenshots, but you can't expose real infrastructure.

**Solution:**
1. Set mode to CLOAK_ALL
2. Take screenshots
3. Toggle back to OFF for continued analysis
4. Documentation is safe to share publicly

### Use Case 4: Third-Party Analysis

**Scenario:** You need help analyzing a capture but can't share actual addresses or data.

**Solution:**
1. Enable CLOAK_ALL mode
2. Export the capture (File → Export Packet Dissections → As Plain Text)
3. Share the exported text file
4. Analysis can proceed without exposing sensitive information

## 🧪 Testing

### Basic Functionality Test

1. **Prepare test capture:**
   ```bash
   # Generate some test traffic
   ping -c 5 8.8.8.8
   # Use Wireshark to capture this traffic
   ```

2. **Test OFF mode:**
   - Set mode to OFF
   - Verify you see real IP addresses (e.g., 8.8.8.8)
   - Verify no `[CLOAKED]` indicators

3. **Test CLOAK_DATA mode:**
   - Set mode to CLOAK_DATA
   - Verify IP addresses are still visible
   - Verify `[CLOAKED]` appears in Info column
   - Verify payload data shows sanitization pattern

4. **Test CLOAK_ALL mode:**
   - Set mode to CLOAK_ALL
   - Verify IP addresses are anonymized (10.0.0.X format)
   - Verify MAC addresses are anonymized (02:00:00:00:00:XX)
   - Verify `[CLOAKED]` appears in Info column
   - Verify PacketCloak subtree shows cloaked addresses

### Conversation Flow Test

Test that anonymization maintains conversation flows:

1. Capture HTTP traffic with multiple packets
2. Enable CLOAK_ALL mode
3. Verify:
   - Same original IP → Same cloaked IP across packets
   - TCP 3-way handshake shows consistent IPs
   - Conversations are still followable

### Performance Test

Test with large captures:

1. Load a large PCAP file (10,000+ packets)
2. Enable CLOAK_ALL mode
3. Monitor:
   - Wireshark responsiveness
   - Time to reload capture
   - Memory usage

## 🐛 Troubleshooting

### Issue: Plugin Not Loading

**Symptoms:**
- No PacketCloak messages in console
- No PACKETCLOAK in preferences

**Solutions:**
1. Verify plugin file location:
   ```bash
   ls -la ~/.local/lib/wireshark/plugins/PacketCloak.lua
   ```
2. Check file permissions (should be readable)
3. Reload Lua plugins: Ctrl+Shift+L
4. Check for Lua errors: View → Show Console

### Issue: Mode Changes Not Applying

**Symptoms:**
- Changed mode but still seeing old behavior

**Solutions:**
1. Reload the capture: Ctrl+R
2. Or refilter packets: Ctrl+Shift+R
3. Restart Wireshark if issues persist

### Issue: Some Addresses Not Cloaked

**Symptoms:**
- Some IP addresses show as real even in CLOAK_ALL

**Possible causes:**
- Special addresses (0.0.0.0, 255.255.255.255) are intentionally skipped
- Some protocol layers might not be fully handled

**Workaround:**
- Report specific protocols that aren't being cloaked as issues

### Issue: Performance Degradation

**Symptoms:**
- Wireshark becomes slow with cloaking enabled

**Solutions:**
1. Try CLOAK_DATA instead of CLOAK_ALL (less processing)
2. Apply display filters to reduce packet count
3. Use smaller capture files
4. Disable PacketCloak when not needed

### Issue: Exported Packets Not Cloaked

**Symptoms:**
- Exported PCAP contains real data

**Expected behavior:**
- PacketCloak only affects the display, not the underlying data
- To create a cloaked PCAP file, use [PacketSanitizer](https://github.com/walterh/PacketSanitizer)

## 💡 Advanced Tips

### Custom Anonymization Ranges

Edit `PacketCloak.lua` to customize:

```lua
local BASE_IP = "192.168.100.0"  -- Change base IP range
local BASE_MAC_PREFIX = "aa:bb:cc:dd:ee"  -- Change base MAC prefix
```

### Exclude Specific Protocols

Add protocol checks to skip cloaking:

```lua
if pinfo.cols.protocol == "DNS" then
    return  -- Don't cloak DNS packets
end
```

### Debug Mode

Enable additional logging by adding print statements:

```lua
print(string.format("[DEBUG] Cloaking IP: %s -> %s", src_ip, cloaked_src))
```

## ⌨️ Keyboard Shortcuts Reference

| Action | Shortcut | Description |
|--------|----------|-------------|
| Reload Lua plugins | Ctrl+Shift+L | Reload all Lua scripts |
| Reload capture | Ctrl+R | Reapply dissectors to all packets |
| Refilter packets | Ctrl+Shift+R | Reapply display filter |
| Preferences | Ctrl+Shift+P | Open preferences dialog |

## 🔗 See Also

- [README.md](README.md) - Project overview
- [PacketSanitizer](https://github.com/walterh/PacketSanitizer) - Create sanitized PCAP files
- [Wireshark Lua API](https://www.wireshark.org/docs/wsdg_html_chunked/wsluarm.html) - Official Lua documentation
