# PacketCloak Installer for Windows

## Installation

### Option 1: Run the installer script (Recommended)

1. Open PowerShell (right-click → "Run as Administrator" if needed)
2. Navigate to the installer directory:
   ```powershell
   cd installers\windows
   ```
3. Run the installer:
   ```powershell
   .\install.ps1
   ```

**Note:** If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Option 2: Run the batch file

Double-click `install.bat` in Windows Explorer.

### Option 3: Manual installation

1. Copy `PacketCloak.lua` to your Wireshark plugins directory:
   ```
   %APPDATA%\Wireshark\plugins\
   ```
   
   Full path example:
   ```
   C:\Users\YourUsername\AppData\Roaming\Wireshark\plugins\
   ```

2. Restart Wireshark or reload Lua plugins (Ctrl+Shift+L)

## Plugin Directories

The installer will try these directories in order:
1. `%APPDATA%\Wireshark\plugins` (Preferred - user directory)
2. `%USERPROFILE%\AppData\Roaming\Wireshark\plugins` (Alternative user directory)
3. `C:\Program Files\Wireshark\plugins` (System-wide - requires admin)

## Requirements

- Windows 10 or later (Windows 7/8 may work)
- Wireshark 3.0 or later
- PowerShell 5.1 or later

## Installing Wireshark

If you don't have Wireshark installed:

### Option 1: Download installer
Visit: https://www.wireshark.org/download.html

### Option 2: Using winget
```powershell
winget install WiresharkFoundation.Wireshark
```

### Option 3: Using Chocolatey
```powershell
choco install wireshark
```

## Verification

After installation:
1. Open Wireshark
2. Go to: **Help → About Wireshark → Plugins**
3. Look for `PacketCloak.lua` with version 0.2.0

## Troubleshooting

### PowerShell execution policy error

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Permission denied

Run PowerShell as Administrator:
1. Right-click PowerShell icon
2. Select "Run as Administrator"
3. Run the installer again

### Plugin not loading

1. Check Wireshark console: **View → Show Console**
2. Reload Lua plugins: **Ctrl+Shift+L**
3. Verify file exists in File Explorer:
   - Navigate to `%APPDATA%\Wireshark\plugins\`
   - Look for `PacketCloak.lua`

### Wireshark not detected

The installer will warn if Wireshark is not found but will continue anyway. You can install Wireshark after running the installer.

## Author

Walter Hofstetter  
Repository: https://github.com/netwho/PacketCloak  
License: GPL-2.0
