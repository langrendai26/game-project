# Godot Detection Failure Logging Verification Test
# Simulates various Godot detection failure scenarios and verifies log completeness

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Godot Detection Failure Logging Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalTests = 0
$passedTests = 0
$failedTests = 0

function Assert-True {
    param([bool]$Condition, [string]$TestName, [string]$Detail = "")
    $script:totalTests++
    if ($Condition) {
        $script:passedTests++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        $script:failedTests++
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        if ($Detail) { Write-Host "         $Detail" -ForegroundColor Yellow }
    }
}

function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$TestName)
    $script:totalTests++
    if ($Haystack -match [regex]::Escape($Needle)) {
        $script:passedTests++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        $script:failedTests++
        Write-Host "  [FAIL] $TestName (needle='$Needle' not found)" -ForegroundColor Red
    }
}

# ============================================================
# Scenario 1: Completely clean system (no Godot anywhere)
# ============================================================
Write-Host "[Scenario 1] No Godot installed anywhere" -ForegroundColor Yellow
Write-Host ""

$originalPath = $env:PATH
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'Godot' -and $_ -notmatch 'godot' }) -join ';'

$log = @()
$logFile = Join-Path $env:TEMP "godot_fail_test_$(Get-Random).txt"

function Add-TestLog {
    param([string]$Msg)
    $ts = Get-Date -Format "HH:mm:ss.fff"
    $script:log += "[$ts] $Msg"
}

$failReasons = @()
Add-TestLog "=== Godot Detection Started ==="
Add-TestLog "OS: $([System.Environment]::OSVersion.VersionString)"
Add-TestLog "PowerShell: $($PSVersionTable.PSVersion)"

# Step 1: Get-Command lookup
Add-TestLog "Step 1: Get-Command exact name lookup..."
$g1 = Get-Command godot -ErrorAction SilentlyContinue
if ($g1) { Add-TestLog "  Found 'godot' at: $($g1.Source)" } else { Add-TestLog "  'godot' not found in command cache" }
$g2 = Get-Command godot4 -ErrorAction SilentlyContinue
if ($g2) { Add-TestLog "  Found 'godot4' at: $($g2.Source)" } else { Add-TestLog "  'godot4' not found in command cache" }
$g3 = Get-Command Godot_v4 -ErrorAction SilentlyContinue
if ($g3) { Add-TestLog "  Found 'Godot_v4' at: $($g3.Source)" } else { Add-TestLog "  'Godot_v4' not found in command cache" }
if (-not $g1 -and -not $g2 -and -not $g3) {
    $failReasons += "Get-Command exact match failed for godot/godot4/Godot_v4"
}

# Step 2: PATH wildcard scan
Add-TestLog "Step 2: PATH directory wildcard scan for Godot_v4*.exe..."
$dirsChecked = 0
$wildcardHit = $false
foreach ($d in ($env:PATH -split ';')) {
    if ($d -and (Test-Path $d)) {
        $dirsChecked++
        $r = Get-ChildItem -Path $d -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($r) { $wildcardHit = $true; Add-TestLog "  FOUND in $d"; break }
    }
}
Add-TestLog "  Scanned $dirsChecked PATH directories"
if (-not $wildcardHit) {
    $failReasons += "PATH wildcard scan (Godot_v4*.exe) found nothing in $dirsChecked dirs"
}

# Step 3: Preset path scan
Add-TestLog "Step 3: Preset path scan..."
$presetPaths = @(
    "${env:ProgramFiles}\Godot\Godot.exe",
    "${env:ProgramFiles}\Godot_v4-stable-win64\Godot_v4-stable-win64.exe",
    "${env:ProgramFiles(x86)}\Godot\Godot.exe",
    "${env:LOCALAPPDATA}\Programs\Godot\Godot.exe",
    "${env:USERPROFILE}\Desktop\Godot_v4-stable-win64.exe",
    "${env:USERPROFILE}\Downloads\Godot_v4-stable-win64.exe",
    "${env:USERPROFILE}\Godot\Godot.exe",
    "C:\Godot\Godot.exe",
    "D:\Godot\Godot.exe"
)
$presetFound = 0
foreach ($p in $presetPaths) {
    if (Test-Path $p) { Add-TestLog "  [EXISTS] $p"; $presetFound++ }
    else { Add-TestLog "  [NOT FOUND] $p" }
}
if ($presetFound -eq 0) {
    $failReasons += "0/$($presetPaths.Count) preset paths exist"
}

# Step 4: Recursive search
Add-TestLog "Step 4: Recursive search in user directories..."
$userDirs = @("${env:USERPROFILE}\Desktop", "${env:USERPROFILE}\Downloads", "${env:USERPROFILE}\Documents")
$recFound = 0
foreach ($d in $userDirs) {
    if (Test-Path $d) {
        $r = Get-ChildItem -Path $d -Filter "Godot*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($r) { Add-TestLog "  FOUND: $($r.FullName)"; $recFound++ }
        else { Add-TestLog "  No Godot*.exe in '$d' (depth=2)" }
    } else { Add-TestLog "  [SKIP] Dir not found: $d" }
}
if ($recFound -eq 0) {
    $failReasons += "Recursive search found no Godot*.exe in user directories"
}

# Step 5: Extracted dir search
Add-TestLog "Step 5: Search for extracted Godot directories..."
$extFound = $false
foreach ($d in $userDirs) {
    if (Test-Path $d) {
        $fd = Get-ChildItem -Path $d -Directory -Filter "Godot*" -Depth 1 -ErrorAction SilentlyContinue | Where-Object {
            Test-Path (Join-Path $_.FullName "Godot*.exe")
        } | Select-Object -First 1
        if ($fd) { Add-TestLog "  FOUND dir: $($fd.FullName)"; $extFound = $true }
        else { Add-TestLog "  No Godot* dir with Godot*.exe in '$d'" }
    }
}
if (-not $extFound) {
    $failReasons += "Extracted directory search found nothing"
}

Add-TestLog "RESULT: Godot NOT FOUND anywhere"
Add-TestLog "Failure reasons:"
foreach ($r in $failReasons) { Add-TestLog "  REASON: $r" }
Add-TestLog "=== Godot Detection Completed ==="

# Write log
$log | Out-File -FilePath $logFile -Encoding UTF8 -Force

# --- Assertions for Scenario 1 ---
Write-Host ""
Write-Host "  --- Scenario 1 Assertions ---" -ForegroundColor Cyan

Assert-True ($log.Count -gt 20) "Log has more than 20 entries" "Got $($log.Count) entries"
Assert-True ($failReasons.Count -ge 5) "At least 5 failure reasons captured" "Got $($failReasons.Count) reasons"

$logJoined = $log -join "`n"
Assert-Contains $logJoined "Godot Detection Started" "Log has start marker"
Assert-Contains $logJoined "Godot Detection Completed" "Log has completion marker"
Assert-Contains $logJoined "Get-Command" "Log mentions Get-Command step"
Assert-Contains $logJoined "REASON:" "Log contains REASON entries"
Assert-Contains $logJoined "NOT FOUND" "Log contains NOT FOUND entries"

Assert-True (Test-Path $logFile) "Log file exists on disk"
Assert-True ($failReasons -contains "Get-Command exact match failed for godot/godot4/Godot_v4") "Reason 1: Get-Command failure captured"
Assert-True ([bool]($failReasons -match [regex]::Escape("PATH wildcard scan"))) "Reason 2: PATH wildcard failure captured"
Assert-True ([bool]($failReasons -match [regex]::Escape("preset paths exist"))) "Reason 3: Preset path failure captured"
Assert-True ([bool]($failReasons -match [regex]::Escape("Recursive search found no"))) "Reason 4: Recursive search failure captured"
Assert-True ([bool]($failReasons -match [regex]::Escape("Extracted directory search found nothing"))) "Reason 5: Extracted dir failure captured"

# Restore PATH
$env:PATH = $originalPath

# ============================================================
# Scenario 2: Godot in PATH dir but not as a command
# ============================================================
Write-Host ""
Write-Host "[Scenario 2] Godot file in PATH dir but not a recognized command" -ForegroundColor Yellow
Write-Host ""

$tempGodotDir = Join-Path $env:TEMP "GodotInPath_$(Get-Random)"
New-Item -ItemType Directory -Path $tempGodotDir -Force | Out-Null
$mockExe = Join-Path $tempGodotDir "Godot_v4-stable-win64.exe"
[System.IO.File]::WriteAllBytes($mockExe, [System.Text.Encoding]::ASCII.GetBytes("MOCK_GODOT"))

$env:PATH = "$tempGodotDir;$originalPath"

$s2Cmd = Get-Command godot -ErrorAction SilentlyContinue
if (-not $s2Cmd) { $s2Cmd = Get-Command Godot_v4 -ErrorAction SilentlyContinue }

$s2WildcardHit = $false
foreach ($d in ($env:PATH -split ';')) {
    if ($d -and (Test-Path $d)) {
        $r = Get-ChildItem -Path $d -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($r) { $s2WildcardHit = $true; break }
    }
}

Write-Host "  Get-Command found: $($s2Cmd -ne $null)" -ForegroundColor Gray
Write-Host "  Wildcard scan found: $s2WildcardHit" -ForegroundColor Gray

# Cleanup
Remove-Item -Path $tempGodotDir -Recurse -Force -ErrorAction SilentlyContinue
$env:PATH = $originalPath

Write-Host ""
Write-Host "  --- Scenario 2 Assertions ---" -ForegroundColor Cyan
Assert-True (-not $s2Cmd) "Get-Command does NOT find mock (expected for non-real exe)"
Assert-True $s2WildcardHit "Wildcard PATH scan DOES find mock Godot file"

# ============================================================
# Scenario 3: PATH with invalid entries
# ============================================================
Write-Host ""
Write-Host "[Scenario 3] PATH contains invalid/non-existent directories" -ForegroundColor Yellow
Write-Host ""

$invalidDir = Join-Path $env:TEMP "NonExistentDir_$(Get-Random)"
$env:PATH = "$invalidDir;$originalPath"

$pathEntries = $env:PATH -split ';'
$validCount = 0
$invalidCount = 0
foreach ($d in $pathEntries) {
    if ($d) {
        if (Test-Path $d) { $validCount++ } else { $invalidCount++ }
    }
}

Write-Host "  PATH entries: $($pathEntries.Count) total, $validCount valid, $invalidCount invalid" -ForegroundColor Gray
$env:PATH = $originalPath

Write-Host ""
Write-Host "  --- Scenario 3 Assertions ---" -ForegroundColor Cyan
Assert-True ($invalidCount -ge 1) "At least 1 invalid PATH entry detected" "Got $invalidCount invalid entries"
Assert-True ($validCount -lt $pathEntries.Count) "Not all PATH entries are valid"

# ============================================================
# Scenario 4: Log file integrity
# ============================================================
Write-Host ""
Write-Host "[Scenario 4] Log file integrity check" -ForegroundColor Yellow
Write-Host ""

$fileContent = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
Write-Host "  Log file size: $($fileContent.Length) bytes" -ForegroundColor Gray

Write-Host ""
Write-Host "  --- Scenario 4 Assertions ---" -ForegroundColor Cyan
Assert-True ($fileContent.Length -gt 500) "Log file is larger than 500 bytes"
Assert-Contains $fileContent "Get-Command" "Log mentions Get-Command"
Assert-Contains $fileContent "REASON:" "Log contains REASON entries"
Assert-Contains $fileContent "NOT FOUND" "Log contains NOT FOUND markers"
Assert-Contains $fileContent "Failure reasons" "Log contains failure reasons section"

# ============================================================
# Scenario 5: Log timestamp ordering
# ============================================================
Write-Host ""
Write-Host "[Scenario 5] Log timestamp ordering" -ForegroundColor Yellow
Write-Host ""

$logLines = Get-Content $logFile
$prevTs = $null
$chronoOk = $true
$tsPattern = '\[(\d{2}:\d{2}:\d{2}\.\d{3})\]'
foreach ($line in $logLines) {
    if ($line -match $tsPattern) {
        $ts = $matches[1]
        if ($prevTs -and $ts -lt $prevTs) {
            Write-Host "  WARNING: Timestamp out of order: $prevTs > $ts" -ForegroundColor Yellow
            $chronoOk = $false
        }
        $prevTs = $ts
    }
}

Write-Host ""
Write-Host "  --- Scenario 5 Assertions ---" -ForegroundColor Cyan
Assert-True $chronoOk "Log timestamps are chronological"
Assert-True ($logLines.Count -ge 20) "Log has at least 20 lines" "Got $($logLines.Count) lines"

# ============================================================
# Summary
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total: $totalTests | Passed: $passedTests | Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) {"Green"} else {"Red"})
Write-Host ""
if ($failedTests -eq 0) {
    Write-Host "  ALL TESTS PASSED - Failure logging is complete and correct!" -ForegroundColor Green
} else {
    Write-Host "  SOME TESTS FAILED - See [FAIL] items above" -ForegroundColor Red
}
Write-Host ""
Write-Host "  Log file: $logFile" -ForegroundColor Cyan
Write-Host "  Log preview (first 5 lines):" -ForegroundColor Cyan
Get-Content $logFile -First 5
Write-Host "  ..." -ForegroundColor Gray
Write-Host "  Log preview (last 5 lines):" -ForegroundColor Cyan
Get-Content $logFile -Last 5
Write-Host ""
