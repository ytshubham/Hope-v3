# ============================================================
# Hope Installer Script — Auto-setup via PowerShell
# Hosted on your Ubuntu server, fetched by a one-liner command
# ============================================================
# CHANGE THIS to your actual server URL:
$BaseUrl = "https://YOUR-SERVER-DOMAIN.com/hope"
# ============================================================

$ErrorActionPreference = "Stop"
$InstallDir = "$env:LOCALAPPDATA\Hope"
$Version = "1.0.0"

# --- Banner ---
function Show-Banner {
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                           ║" -ForegroundColor Cyan
    Write-Host "  ║        ██╗  ██╗ ██████╗ ██████╗ ███████╗  ║" -ForegroundColor Cyan
    Write-Host "  ║        ██║  ██║██╔═══██╗██╔══██╗██╔════╝  ║" -ForegroundColor Cyan
    Write-Host "  ║        ███████║██║   ██║██████╔╝█████╗    ║" -ForegroundColor Cyan
    Write-Host "  ║        ██╔══██║██║   ██║██╔═══╝ ██╔══╝    ║" -ForegroundColor Cyan
    Write-Host "  ║        ██║  ██║╚██████╔╝██║     ███████╗  ║" -ForegroundColor Cyan
    Write-Host "  ║        ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝  ║" -ForegroundColor Cyan
    Write-Host "  ║                                           ║" -ForegroundColor Cyan
    Write-Host "  ║          Free Edition Installer           ║" -ForegroundColor Yellow
    Write-Host "  ║              Version $Version                ║" -ForegroundColor DarkGray
    Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# --- Check if already installed ---
function Check-Existing {
    if (Test-Path "$InstallDir\hope.exe") {
        Write-Host "  [!] Hope is already installed at $InstallDir" -ForegroundColor Yellow
        $choice = Read-Host "  Reinstall/Update? (y/n)"
        if ($choice -ne 'y' -and $choice -ne 'Y') {
            Write-Host "  Cancelled." -ForegroundColor Red
            exit 0
        }
    }
}

# --- Download a file with progress ---
function Download-File {
    param([string]$Url, [string]$OutFile, [string]$DisplayName)

    Write-Host "  [↓] Downloading $DisplayName..." -ForegroundColor Gray -NoNewline
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "HopeInstaller/$Version")
        $webClient.DownloadFile($Url, $OutFile)
        Write-Host " Done" -ForegroundColor Green
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        throw "Failed to download $DisplayName from $Url`n$($_.Exception.Message)"
    }
}

# --- Create Desktop Shortcut ---
function Create-Shortcut {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Hope.lnk"

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "$InstallDir\hope.exe"
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.Description = "Hope - AI Assistant (Free Edition)"
    $shortcut.Save()

    Write-Host "  [✓] Desktop shortcut created" -ForegroundColor Green
}

# --- Add to PATH (optional, user-level) ---
function Add-ToPath {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallDir", "User")
        Write-Host "  [✓] Added to PATH (new terminals only)" -ForegroundColor Green
    }
    else {
        Write-Host "  [✓] Already in PATH" -ForegroundColor Green
    }
}

# --- Create uninstaller script ---
function Create-Uninstaller {
    $uninstallScript = @'
# Hope Uninstaller
$InstallDir = "$env:LOCALAPPDATA\Hope"
Write-Host "Uninstalling Hope..." -ForegroundColor Yellow
$shortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Hope.lnk"
if (Test-Path $shortcut) { Remove-Item $shortcut -Force }
$path = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = ($path -split ";" | Where-Object { $_ -ne $InstallDir }) -join ";"
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
Write-Host "Hope has been uninstalled." -ForegroundColor Green
'@
    Set-Content -Path "$InstallDir\uninstall.ps1" -Value $uninstallScript
}

# ============================================================
# MAIN
# ============================================================

Show-Banner
Check-Existing

$files = @(
    @{ Name = "hope.exe";             Display = "Hope Application" },
    @{ Name = "MinHook.x64.dll";      Display = "MinHook Library" },
    @{ Name = "Dll1.dll";             Display = "Support Library" },
    @{ Name = "WebView2Loader.dll";   Display = "WebView2 Loader" }
)

Write-Host "  [+] Installing to $InstallDir" -ForegroundColor Cyan
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host ""
Write-Host "  Downloading files..." -ForegroundColor White
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
foreach ($file in $files) {
    $url = "$BaseUrl/$($file.Name)"
    $outPath = Join-Path $InstallDir $file.Name
    Download-File -Url $url -OutFile $outPath -DisplayName $file.Display
}

Write-Host ""
Write-Host "  Setting up..." -ForegroundColor White
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Create-Shortcut
Add-ToPath
Create-Uninstaller

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                           ║" -ForegroundColor Green
Write-Host "  ║     ✅  Hope installed successfully!      ║" -ForegroundColor Green
Write-Host "  ║                                           ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  📁 Installed to: $InstallDir" -ForegroundColor White
Write-Host "  🖥️  Desktop shortcut: Hope.lnk" -ForegroundColor White
Write-Host "  🗑️  To uninstall: powershell $InstallDir\uninstall.ps1" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Launching Hope..." -ForegroundColor Yellow
Write-Host ""

Start-Process "$InstallDir\hope.exe"
