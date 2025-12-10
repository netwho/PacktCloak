# PacketCloak Windows Installer - Quickstart

1. Install Wireshark (64-bit) from https://www.wireshark.org/
2. From a PowerShell prompt at repo root run:
   ```powershell
   .\installers\windows\install.ps1
   ```
   or use `install.bat` from Command Prompt.
3. Restart Wireshark or reload Lua plugins (if available).
4. Verify: Help → About Wireshark → Plugins → `PacketCloak.lua`.
5. Assign shortcuts: Edit → Preferences → Shortcuts → search `PacketCloak`.
