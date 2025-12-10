# PacketCloak macOS Installer - Quickstart

1. Ensure Wireshark is installed (e.g., `brew install --cask wireshark`).
2. Run the installer from repo root:
   ```bash
   ./installers/macos/install.sh
   ```
3. Reload Lua plugins in Wireshark (Cmd+Shift+L) or restart Wireshark.
4. Verify: Help → About Wireshark → Plugins → `PacketCloak.lua`.
5. Toggle cloaking: Tools → PacketCloak (assign shortcuts in Preferences → Shortcuts).
