# PacketCloak Code Analysis

## Current Implementation Analysis

### What Works
1. ✅ IPv4 shim dissector modifies packet bytes (for IPv4 addresses)
2. ✅ MAC address column modification (`pinfo.cols.dl_src`, `pinfo.cols.dl_dst`)
3. ✅ Info column prefix (`[CLOAKED]`)
4. ✅ PacketCloak subtree added to detail window
5. ✅ Stateful IP/MAC mapping maintained
6. ✅ Menu integration for mode toggling

### What Doesn't Work (Issues)

#### 1. Summary Window (Packet List) - IP Addresses
**Problem**: IP addresses in the summary window don't show cloaked values consistently.

**Root Cause**: 
- The IPv4 shim modifies packet bytes, which should make the IP dissector show cloaked IPs
- However, `pinfo.cols.src` and `pinfo.cols.dst` are not explicitly set in the post-dissector
- The shim approach works, but we need to ensure column values are updated

**Solution**: Set `pinfo.cols.src` and `pinfo.cols.dst` in the post-dissector when in CLOAK_ALL mode.

#### 2. Detail Window - Protocol Fields Not Cloaked
**Problem**: The detail window shows real IP/MAC addresses in protocol fields (e.g., "Internet Protocol Version 4, Src: 192.168.1.100").

**Root Cause**:
- The IPv4 shim modifies bytes, but the IP dissector has already run and populated the tree
- We're adding a PacketCloak subtree but not modifying the actual protocol fields
- Wireshark Lua dissectors can't modify fields that have already been added to the tree by other dissectors

**Solution**: 
- Use a pre-dissector or shim approach (already done for IPv4)
- For protocols that show addresses in detail, we need to intercept before they're displayed
- Alternative: Use field extractors to override field display values

#### 3. Payload Cloaking - Detail Window
**Problem**: Payload data in detail window (e.g., HTTP, SMTP, Telnet) shows real data, not cloaked.

**Root Cause**:
- Payload fields are added by protocol dissectors (HTTP, SMTP, etc.)
- Post-dissector runs after all dissectors, so we can't modify their fields
- The hex dump shows raw bytes, which can't be modified

**Solution**:
- Note: Hex dump cannot be cloaked (Wireshark limitation - shows raw packet bytes)
- For detail window: We can't modify fields added by other dissectors, but we can:
  - Add warnings/notes in our subtree
  - Use field extractors if available in Wireshark version
  - Document this limitation clearly

#### 4. Keyboard Shortcuts
**Problem**: Keyboard shortcuts mentioned but not actually implemented.

**Root Cause**:
- Wireshark Lua API doesn't directly support keyboard shortcut registration
- Menu items exist but require manual Wireshark configuration to map to shortcuts

**Solution**:
- Improve menu integration
- Add clear documentation on how to configure shortcuts
- Consider using Wireshark's tap system for real-time updates

## Technical Constraints

### Wireshark Lua API Limitations

1. **Hex Dump**: Cannot be modified - shows raw packet bytes from file
   - This is a fundamental Wireshark limitation
   - Solution: Document limitation, suggest hiding hex window

2. **Field Modification**: Cannot modify fields added by other dissectors
   - Fields are added to tree during dissection
   - Post-dissector runs after all dissectors
   - Solution: Use pre-dissector/shim approach (already done for IPv4)

3. **Column Updates**: Can modify `pinfo.cols.*` but timing matters
   - Must be done before columns are rendered
   - Post-dissector should work, but may need to be earlier

4. **Keyboard Shortcuts**: Not directly supported in Lua API
   - Must use menu items + Wireshark preferences
   - Or use external scripts/automation

## Proposed Fixes

### Fix 1: Ensure Summary Window Shows Cloaked IPs
- Set `pinfo.cols.src` and `pinfo.cols.dst` in post-dissector
- Ensure IPv4 shim properly propagates cloaked addresses

### Fix 2: Improve Detail Window Cloaking
- For IP addresses: Already handled by shim (should work)
- For MAC addresses: Need to ensure they're cloaked in Ethernet layer
- Add clearer indicators in detail window

### Fix 3: Payload Cloaking
- Document hex dump limitation clearly
- Add better visual indicators for cloaked payloads
- Consider adding warnings in detail window

### Fix 4: Keyboard Shortcuts
- Improve menu integration
- Add documentation for shortcut configuration
- Consider adding a toggle function that can be called via menu

## Implementation Priority

1. **High Priority**: Fix summary window IP address display
2. **High Priority**: Improve detail window address cloaking
3. **Medium Priority**: Better payload cloaking indicators
4. **Medium Priority**: Keyboard shortcut documentation/improvements
5. **Low Priority**: Hex dump limitation documentation


