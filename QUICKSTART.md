# PacketCloak Quick Start Guide

🚀 Get up and running with PacketCloak in 5 minutes!

## 📥 Installation

### Option 1: Automated Installation (Recommended)

```bash
cd /Users/walterh/Github-Projects/PacketCloak
./install.sh
```

### Option 2: Manual Installation

```bash
cp PacketCloak.lua ~/.local/lib/wireshark/plugins/
```

## ✅ Verify Installation

1. Open Wireshark
2. Check console output for:
   ```
   [PacketCloak] Loaded successfully!
   [PacketCloak] Current mode: OFF
   ```
3. Or go to: **Help → About Wireshark → Plugins** and look for `PacketCloak.lua`

## 📝 Quick Reference

**Keyboard Shortcuts** (configure in Edit → Preferences → Shortcuts):
- **Ctrl+Shift+C** - Toggle CLOAK_ALL mode
- **Ctrl+Shift+D** - Toggle CLOAK_DATA mode  
- **Ctrl+Shift+A** - Cycle through all modes
- **Ctrl+R** - Reload capture (required after mode change)

**Menu Access:** Tools → PacketCloak

**Modes:**
- **OFF** - Show real data
- **CLOAK_DATA** - Hide payloads only
- **CLOAK_ALL** - Hide addresses + payloads

## ⚡ Quick Usage

### Method 1: Using Preferences (Persistent)

1. Open Wireshark
2. Go to: **Edit → Preferences → Protocols → PACKETCLOAK**
3. Select your mode:
   - **OFF** - Normal view (default)
   - **CLOAK_DATA** - Hide payloads only
   - **CLOAK_ALL** - Hide everything (addresses + payloads)
4. Click **OK**
5. Press **Ctrl+R** to reload

### Method 2: Using Menu (Quick Toggle)

1. Open Wireshark
2. Go to: **Tools → PacketCloak**
3. Select:
   - **Toggle CLOAK_ALL** - Full privacy mode
   - **Toggle CLOAK_DATA** - Data-only mode
4. Press **Ctrl+R** to reload

## 🧪 Quick Test

1. Generate test traffic:
   ```bash
   ping -c 5 8.8.8.8
   ```

2. Capture this traffic in Wireshark

3. **Test CLOAK_ALL:**
   - Tools → PacketCloak → Toggle CLOAK_ALL
   - Press Ctrl+R
   - Look for `10.0.0.X` addresses instead of real IPs
   - Check Info column for `[CLOAKED]` prefix

4. **Test CLOAK_DATA:**
   - Tools → PacketCloak → Toggle CLOAK_DATA
   - Press Ctrl+R
   - IPs stay the same, but data is sanitized
   - Check Info column for `[CLOAKED]` prefix

## 📋 What Each Mode Does

| Mode | IP Addresses | MAC Addresses | Payload Data | Use Case |
|------|--------------|---------------|--------------|----------|
| **OFF** | Real | Real | Real | Normal analysis |
| **CLOAK_DATA** | Real | Real | **Cloaked** | Show network flows, hide data |
| **CLOAK_ALL** | **Cloaked** | **Cloaked** | **Cloaked** | Maximum privacy |

## 🎯 Common Scenarios

### Scenario: Screen Sharing Demo
**Problem:** Need to share screen but have sensitive customer data  
**Solution:** Enable CLOAK_ALL mode

### Scenario: Training Session
**Problem:** Teaching with real captures containing sensitive data  
**Solution:** Enable CLOAK_DATA mode (students see topology, not data)

### Scenario: Taking Screenshots
**Problem:** Creating documentation with Wireshark screenshots  
**Solution:** Enable CLOAK_ALL, take screenshots, toggle back to OFF

## ⚠️ Important Notes

✅ **What PacketCloak DOES:**
- Changes how packets are displayed in Wireshark
- Anonymizes addresses while maintaining conversation flows
- Adds `[CLOAKED]` indicators to show mode is active
- Preserves analysis capabilities (timing, protocols, etc.)

❌ **What PacketCloak DOES NOT:**
- Modify the actual PCAP file
- Affect exported packet captures
- Cloak IGMP packets (preserved for analysis)
- Work without reloading capture after mode change

## ⌨️ Keyboard Shortcuts

### Essential Wireshark Shortcuts

| Action | Shortcut | Description |
|--------|----------|-------------|
| Reload capture | **Ctrl+R** | Apply PacketCloak mode changes (required after toggling) |
| Reload Lua plugins | **Ctrl+Shift+L** | Reload PacketCloak after code changes |
| Open preferences | **Ctrl+Shift+P** | Access PacketCloak settings |
| Show console | **View → Show Console** | See PacketCloak status messages |

### Configuring PacketCloak Keyboard Shortcuts

PacketCloak menu items can be assigned custom keyboard shortcuts:

1. **Open Wireshark Preferences:**
   - Go to **Edit → Preferences → Shortcuts** (or press **Ctrl+Shift+P**)

2. **Search for PacketCloak:**
   - In the search box, type: `PacketCloak`
   - You'll see these menu items:
     - `PacketCloak/Toggle Mode (Cycle)` - Cycles: OFF → CLOAK_DATA → CLOAK_ALL → OFF
     - `PacketCloak/Toggle CLOAK_ALL` - Toggles between OFF and CLOAK_ALL
     - `PacketCloak/Toggle CLOAK_DATA` - Toggles between OFF and CLOAK_DATA

3. **Assign Shortcuts:**
   - Click on a menu item
   - Press your desired key combination
   - Click **OK** to save

### Suggested Shortcut Mappings

| Menu Item | Suggested Shortcut | Why |
|-----------|-------------------|-----|
| Toggle CLOAK_ALL | **Ctrl+Shift+C** | **C** for Cloak |
| Toggle CLOAK_DATA | **Ctrl+Shift+D** | **D** for Data |
| Toggle Mode (Cycle) | **Ctrl+Shift+A** | **A** for All modes |

**Note:** After changing modes via keyboard shortcut, press **Ctrl+R** to reload the capture and see changes.

### Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│  PACKETCLOAK QUICK REFERENCE                    │
├─────────────────────────────────────────────────┤
│  Toggle CLOAK_ALL:    Ctrl+Shift+C              │
│  Toggle CLOAK_DATA:   Ctrl+Shift+D              │
│  Cycle modes:         Ctrl+Shift+A              │
│  Apply changes:       Ctrl+R                    │
│  Open preferences:    Ctrl+Shift+P              │
└─────────────────────────────────────────────────┘
```

## 🔧 Troubleshooting

**Plugin not loading?**
```bash
# Check if file exists
ls -la ~/.local/lib/wireshark/plugins/PacketCloak.lua

# Check Wireshark console for errors
# View → Show Console
```

**Mode changes not working?**
- Press **Ctrl+R** to reload the capture
- Or restart Wireshark

**Want to permanently change mode?**
- Use Preferences method (Edit → Preferences → Protocols → PACKETCLOAK)

## 👉 Next Steps

- Read [USAGE.md](USAGE.md) for detailed documentation
- Check [README.md](README.md) for complete feature list
- Review [CHANGELOG.md](CHANGELOG.md) for version history

## 🎯 Need Help?

- Check console output: View → Show Console
- Enable debug mode by editing `PacketCloak.lua`
- Review [USAGE.md](USAGE.md) troubleshooting section

---

**Ready to go!** 🎉 Open Wireshark and start cloaking!
