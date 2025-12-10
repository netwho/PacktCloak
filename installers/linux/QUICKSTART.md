# PacketCloak Linux Installer - Quickstart

1. Ensure Wireshark is installed (`sudo apt install wireshark` or equivalent).
2. From repo root, run:
   ```bash
   ./installers/linux/install.sh
   ```
3. Reload Lua plugins in Wireshark (Ctrl+Shift+L) or restart Wireshark.
4. Verify: Help → About Wireshark → Plugins → `PacketCloak.lua`.
5. Assign shortcuts: Edit → Preferences → Shortcuts → search `PacketCloak`.
