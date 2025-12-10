# PacketCloak Installer for Windows
# Author: Walter Hofstetter
# License: GPL-2.0
# Repository: https://github.com/netwho/PacketCloak

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$PluginFile = "PacketCloak.lua"
$PluginPath = Join-Path $ProjectRoot $PluginFile

# Windows Wireshark plugin directories (in order of preference)
$PluginDirs = @(
    "$env:APPDATA\Wireshark\plugins",
    "$env:USERPROFILE\AppData\Roaming\Wireshark\plugins",
    "C:\Program Files\Wireshark\plugins"
)

Write-Host "╔═══════════════════════════════════════════════╗"
Write-Host "║  PacketCloak Installer for Windows v0.2.0     ║"
Write-Host "╚═══════════════════════════════════════════════╝"
Write-Host ""
Write-Host "Author: Walter Hofstetter"
Write-Host "License: GPL-2.0"
Write-Host ""

# Check if Wireshark is installed
$WiresharkInstalled = $false
$WiresharkPaths = @(
    "C:\Program Files\Wireshark\Wireshark.exe",
    "C:\Program Files (x86)\Wireshark\Wireshark.exe"
)

foreach ($path in $WiresharkPaths) {
    if (Test-Path $path) {
        $WiresharkInstalled = $true
        break
    }
}

if (-not $WiresharkInstalled) {
    Write-Host "⚠️  Warning: Wireshark does not appear to be installed." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install Wireshark first:"
    Write-Host "  Download from: https://www.wireshark.org/download.html"
    Write-Host "  or use: winget install WiresharkFoundation.Wireshark"
    Write-Host ""
    $response = Read-Host "Continue anyway? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Installation cancelled"
        exit 0
    }
}

# Check if plugin file exists
if (-not (Test-Path $PluginPath)) {
    Write-Host "❌ Error: $PluginFile not found at $PluginPath" -ForegroundColor Red
    exit 1
}

# Find the first existing or create the preferred plugin directory
$WiresharkPluginDir = $null
foreach ($dir in $PluginDirs) {
    if ((Test-Path $dir) -or ($dir -eq $PluginDirs[0])) {
        $WiresharkPluginDir = $dir
        break
    }
}

Write-Host "Target directory: $WiresharkPluginDir"
Write-Host ""

# Create plugin directory if it doesn't exist
if (-not (Test-Path $WiresharkPluginDir)) {
    Write-Host "Creating plugin directory: $WiresharkPluginDir"
    try {
        New-Item -ItemType Directory -Path $WiresharkPluginDir -Force | Out-Null
    } catch {
        Write-Host "❌ Error: Failed to create plugin directory" -ForegroundColor Red
        Write-Host "You may need to run PowerShell as Administrator"
        exit 1
    }
}

# Check if plugin already exists
$ExistingPlugin = Join-Path $WiresharkPluginDir $PluginFile
if (Test-Path $ExistingPlugin) {
    Write-Host "⚠️  Warning: $PluginFile already exists in plugin directory" -ForegroundColor Yellow
    $response = Read-Host "Overwrite existing plugin? (y/n)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Installation cancelled"
        exit 0
    }
}

# Copy plugin to Wireshark directory
Write-Host "Installing $PluginFile to $WiresharkPluginDir"
try {
    Copy-Item $PluginPath $WiresharkPluginDir -Force
} catch {
    Write-Host "❌ Error: Failed to copy plugin file" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# Verify installation
if (Test-Path $ExistingPlugin) {
    Write-Host ""
    Write-Host "✅ Installation successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:"
    Write-Host "1. Launch Wireshark"
    Write-Host "2. Reload Lua plugins: Ctrl+Shift+L"
    Write-Host "3. Verify: Help → About Wireshark → Plugins (look for PacketCloak)"
    Write-Host "4. Configure: Edit → Preferences → Protocols → PACKETCLOAK"
    Write-Host "5. Toggle modes: Tools → PacketCloak menu"
    Write-Host ""
    Write-Host "📖 Documentation:"
    Write-Host "   README.md - Feature overview"
    Write-Host "   QUICKSTART.md - 5-minute guide"
    Write-Host "   USAGE.md - Comprehensive documentation"
    Write-Host ""
    Write-Host "🔗 Repository: https://github.com/netwho/PacketCloak"
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    Write-Host ""
    Write-Host "❌ Installation failed!" -ForegroundColor Red
    Write-Host "Please check permissions and try again"
    exit 1
}
