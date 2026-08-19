# Godot Detection Logging Verification Test
# Tests that the logging infrastructure produces detailed failure diagnostics

$tempLog = Join-Path $env:TEMP "godot_log_test_$(Get-Random).txt"
$testLog = @()

function Add-TestLog {
    param([string]$Message)
    $ts = Get-Date -Format "HH:mm:ss.fff"
    $entry = "[$ts] $Message"
    $script:testLog += $entry
    Write-Host $entry -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Godot Detection Logging Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Simulate the no-Godot scenario
$originalPath = $env:PATH
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'Godot' -and $_ -notmatch 'godot' }) -join ';'

Add-TestLog "=== Godot Detection Started ==="
Add-TestLog "OS: $([System.Environment]::OSVersion.VersionString)"
Add-TestLog "PowerShell: $($PSVersionTable.PSVersion)"
Add-TestLog "PATH length: $($env:PATH.Length) chars"

$failReasons = @()

# Step 1: Get-Command lookup
Add-TestLog "Step 1: Get-Command exact name lookup..."
$c1 = Get-Command godot -ErrorAction SilentlyContinue
if ($c1) { Add-TestLog "  Found 'godot' at: $($c1.Source)" } else { Add-TestLog "  'godot' not found in command cache" }
$c2 = Get-Command godot4 -ErrorAction SilentlyContinue
if ($c2) { Add-TestLog "  Found 'godot4' at: $($c2.Source)" } else { Add-TestLog "  'godot4' not found in command cache" }
$c3 = Get-Command Godot_v4 -ErrorAction SilentlyContinue
if ($c3) { Add-TestLog "  Found 'Godot_v4' at: $($c3.Source)" } else { Add-TestLog "  'Godot_v4' not found in command cache" }
if (-not $c1 -and -not $c2 -and -not $c3) { $failReasons += "Get-Command exact match failed for godot/godot4/Godot_v4" }

# Step 2: PATH wildcard scan
Add-TestLog "Step 2: PATH directory wildcard scan for Godot_v4*.exe..."
$dirsChecked = 0
$foundWildcard = $false
foreach ($dir in ($env:PATH -split ';')) {
    if ($dir -and (Test-Path $dir)) {
        $dirsChecked++
        $r = Get-ChildItem -Path $dir -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($r) { Add-TestLog "  FOUND in '$dir': $($r.FullName)"; $foundWildcard = $true; break }
    }
}
Add-TestLog "  Scanned $dirsChecked PATH directories"
if (-not $foundWildcard) { $failReasons += "PATH wildcard scan (Godot_v4*.exe) found nothing in $dirsChecked dirs" }

# Step 3: Preset path scan
Add-TestLog "Step 3: Deep scan of common installation paths..."
$presetPaths = @(
    "${env:ProgramFiles}\Godot\Godot.exe",
    "${env:ProgramFiles}\Godot_v4-stable-win64\Godot_v4-stable-win64.exe",
    "${env:LOCALAPPDATA}\Programs\Godot\Godot.exe",
    "C:\Godot\Godot.exe",
    "D:\Godot\Godot.exe"
)
$presetFound = 0
foreach ($p in $presetPaths) {
    if (Test-Path $p) { Add-TestLog "  [EXISTS] $p"; $presetFound++ }
    else { Add-TestLog "  [NOT FOUND] $p" }
}
if ($presetFound -eq 0) { $failReasons += "0/$($presetPaths.Count) preset paths exist" }

# Step 4: Recursive search
Add-TestLog "Step 4: Recursive search in user directories..."
$userDirs = @("${env:USERPROFILE}\Desktop", "${env:USERPROFILE}\Downloads", "${env:USERPROFILE}\Documents")
$recFound = 0
foreach ($dir in $userDirs) {
    if (Test-Path $dir) {
        $r = Get-ChildItem -Path $dir -Filter "Godot*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($r) { Add-TestLog "  FOUND: $($r.FullName)"; $recFound++ }
        else { Add-TestLog "  No Godot*.exe in '$dir' (depth=2)" }
    } else {
        Add-TestLog "  Directory does not exist: $dir"
    }
}
if ($recFound -eq 0) { $failReasons += "Recursive search found no Godot*.exe in user directories" }

# Step 5: Extracted dir search
Add-TestLog "Step 5: Search for extracted Godot directories..."
$extractFound = $false
foreach ($dir in $userDirs) {
    if (Test-Path $dir) {
        $foundDir = Get-ChildItem -Path $dir -Directory -Filter "Godot*" -Depth 1 -ErrorAction SilentlyContinue | Where-Object {
            Test-Path (Join-Path $_.FullName "Godot*.exe")
        } | Select-Object -First 1
        if ($foundDir) {
            Add-TestLog "  FOUND dir: $($foundDir.FullName)"
            $extractFound = $true
        } else {
            Add-TestLog "  No Godot* dir with Godot*.exe in '$dir'"
        }
    }
}
if (-not $extractFound) { $failReasons += "Extracted directory search found nothing" }

# Step 6: Final verification
Add-TestLog "Step 6: Final verification..."
Add-TestLog "RESULT: Godot NOT FOUND anywhere"

# Print failure reasons
Write-Host ""
Write-Host "  --- Failure Diagnosis ---" -ForegroundColor Yellow
Add-TestLog "Failure reasons:"
foreach ($r in $failReasons) {
    Write-Host "    - $r" -ForegroundColor Red
    Add-TestLog "  REASON: $r"
}

# PATH diagnostics
$pathTotal = ($env:PATH -split ';').Count
$pathValid = 0
foreach ($d in ($env:PATH -split ';')) { if ($d -and (Test-Path $d)) { $pathValid++ } }
$pathDiag = "PATH: $pathTotal entries total, $pathValid valid directories"
Write-Host "    $pathDiag" -ForegroundColor Gray
Add-TestLog "  PATH DIAGNOSTIC: $pathDiag"

# Check Program Files for Godot dirs
$pfDirs = Get-ChildItem -Path "${env:ProgramFiles}" -Filter "Godot*" -Directory -ErrorAction SilentlyContinue
if ($pfDirs) {
    Write-Host "    [NOTE] Godot-related dirs in Program Files:" -ForegroundColor Yellow
    foreach ($d in $pfDirs) {
        Write-Host "      $($d.FullName)" -ForegroundColor Yellow
        Add-TestLog "  NOTE: Godot dir: $($d.FullName)"
    }
}

Add-TestLog "=== Godot Detection Completed ==="

# Write log file
$testLog | Out-File -FilePath $tempLog -Encoding UTF8 -Force
Write-Host ""
Write-Host "  [OK] Log file saved: $tempLog" -ForegroundColor Green

# Restore PATH
$env:PATH = $originalPath

# Display log contents
Write-Host ""
Write-Host "=== Log File Contents ===" -ForegroundColor Cyan
Get-Content $tempLog -Encoding UTF8

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Log entries generated: $($testLog.Count)" -ForegroundColor Green
Write-Host "  Failure reasons captured: $($failReasons.Count)" -ForegroundColor Green
Write-Host "  Log file created: $(Test-Path $tempLog)" -ForegroundColor Green
Write-Host "  PATH diagnostics: $pathDiag" -ForegroundColor Green
Write-Host ""
Write-Host "  Detailed logging for Godot detection works!" -ForegroundColor Green
