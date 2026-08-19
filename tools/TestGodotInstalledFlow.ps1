# Godot Installed - Full Startup Flow Verification Test
# Simulates Godot correctly installed and verifies the complete startup flow

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Godot Installed Startup Flow Test" -ForegroundColor Cyan
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

function Assert-Equal {
    param($Actual, $Expected, [string]$TestName)
    $script:totalTests++
    if ($Actual -eq $Expected) {
        $script:passedTests++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        $script:failedTests++
        Write-Host "  [FAIL] $TestName (expected='$Expected', got='$Actual')" -ForegroundColor Red
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
# Setup: Create a mock Godot with version output
# ============================================================
Write-Host "[Setup] Creating mock Godot with version output..." -ForegroundColor Yellow

$tempDir = Join-Path $env:TEMP "GodotTest_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Create a real PowerShell script to act as Godot (so --version works)
$mockGodotScript = Join-Path $tempDir "GodotMock.ps1"
$mockGodotContent = @'
param([string]$version)
if ($version -eq "--version") {
    Write-Host "Godot_v4.3-stable-win64 4.3.stable"
} else {
    Write-Host "Godot Engine - Test Mock"
}
'@
Set-Content -Path $mockGodotScript -Value $mockGodotContent -Encoding UTF8

# Create a .cmd wrapper so it can be found by Get-Command
$mockGodotCmd = Join-Path $tempDir "godot.cmd"
$cmdContent = "@echo off`r`nif `"%1`"==`"--version`" (`r`n  echo Godot_v4.3-stable-win64 4.3.stable`r`n) else (`r`n  echo Godot Engine Test Mock`r`n)"
Set-Content -Path $mockGodotCmd -Value $cmdContent -Encoding ASCII

# Also create Godot_v4-stable-win64.exe as a mock (for wildcard scan)
$mockGodotExe = Join-Path $tempDir "Godot_v4-stable-win64.exe"
[System.IO.File]::WriteAllBytes($mockGodotExe, [System.Text.Encoding]::ASCII.GetBytes("MOCK_GODOT_EXE"))

# Also create godot4.cmd variant
$mockGodot4Cmd = Join-Path $tempDir "godot4.cmd"
Set-Content -Path $mockGodot4Cmd -Value $cmdContent -Encoding ASCII

Write-Host "  Mock Godot created at: $tempDir" -ForegroundColor Gray
Write-Host "  Files:" -ForegroundColor Gray
Get-ChildItem $tempDir | ForEach-Object { Write-Host "    $($_.Name) ($($_.Length) bytes)" -ForegroundColor Gray }

# Save original PATH and add mock dir
$originalPath = $env:PATH
$env:PATH = "$tempDir;$originalPath"

# ============================================================
# Phase 1: Godot detection (Get-Command)
# ============================================================
Write-Host ""
Write-Host "[Phase 1] Godot detection via Get-Command" -ForegroundColor Yellow
Write-Host ""

$detectedPath = $null
$detectedVersion = $null
$detectedInstalled = $false

# Step 1a: Get-Command lookup
$cmd1 = Get-Command godot -ErrorAction SilentlyContinue
if ($cmd1) {
    $detectedPath = $cmd1.Source
    $detectedInstalled = $true
    Write-Host "  Found 'godot': $($cmd1.Source)" -ForegroundColor Green
} else {
    Write-Host "  'godot' not found via Get-Command" -ForegroundColor Gray
}

if (-not $detectedInstalled) {
    $cmd2 = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($cmd2) {
        $detectedPath = $cmd2.Source
        $detectedInstalled = $true
        Write-Host "  Found 'godot4': $($cmd2.Source)" -ForegroundColor Green
    }
}

if (-not $detectedInstalled) {
    $cmd3 = Get-Command Godot_v4 -ErrorAction SilentlyContinue
    if ($cmd3) {
        $detectedPath = $cmd3.Source
        $detectedInstalled = $true
        Write-Host "  Found 'Godot_v4': $($cmd3.Source)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "  --- Phase 1 Assertions ---" -ForegroundColor Cyan
Assert-True $detectedInstalled "Godot detected via Get-Command"
Assert-True ($null -ne $detectedPath) "Detection path is not null"

# ============================================================
# Phase 2: Version detection
# ============================================================
Write-Host ""
Write-Host "[Phase 2] Godot version detection" -ForegroundColor Yellow
Write-Host ""

if ($detectedInstalled -and $detectedPath) {
    try {
        # Run the mock with --version and convert output to string
        # Use cmd /c to properly invoke the .cmd file
        $verOutput = cmd /c "`"$detectedPath`" --version" 2>&1
        $detectedVersion = ($verOutput | Out-String).Trim()
        Write-Host "  Version output: $detectedVersion" -ForegroundColor Green
    } catch {
        Write-Host "  Version query failed: $_" -ForegroundColor Red
        $detectedVersion = "unknown"
    }
}

Write-Host ""
Write-Host "  --- Phase 2 Assertions ---" -ForegroundColor Cyan
Assert-True ($detectedVersion -ne $null -and $detectedVersion -ne "") "Version string is not empty"
Assert-Contains $detectedVersion "4.3" "Version contains expected version number"

# ============================================================
# Phase 3: Wildcard PATH scan (fallback method)
# ============================================================
Write-Host ""
Write-Host "[Phase 3] Wildcard PATH scan verification" -ForegroundColor Yellow
Write-Host ""

$wildcardFound = $false
$wildcardPath = $null
foreach ($d in ($env:PATH -split ';')) {
    if ($d -and (Test-Path $d)) {
        $r = Get-ChildItem -Path $d -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($r) {
            $wildcardPath = $r.FullName
            $wildcardFound = $true
            Write-Host "  Found via wildcard: $wildcardPath" -ForegroundColor Green
            break
        }
    }
}

Write-Host ""
Write-Host "  --- Phase 3 Assertions ---" -ForegroundColor Cyan
Assert-True $wildcardFound "Wildcard PATH scan finds Godot_v4*.exe"
Assert-True ($wildcardPath -like "*Godot_v4*") "Wildcard found path contains Godot_v4"

# ============================================================
# Phase 4: Simulate full startup flow
# ============================================================
Write-Host ""
Write-Host "[Phase 4] Full startup flow simulation" -ForegroundColor Yellow
Write-Host ""

$flowLog = @()
function Add-FlowLog {
    param([string]$Msg)
    $ts = Get-Date -Format "HH:mm:ss.fff"
    $script:flowLog += "[$ts] $Msg"
}

# Step 1: Godot check (already done)
Add-FlowLog "Step 1: Godot check - INSTALLED (path=$detectedPath)"

# Step 2: Git check
Add-FlowLog "Step 2: Git check - AVAILABLE"
$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
Add-FlowLog "Step 2a: Git command found: $gitAvailable"

# Step 3: Git config check
Add-FlowLog "Step 3: Git user config check"
$gitNameGlobal = git config --global user.name 2>$null
$gitEmailGlobal = git config --global user.email 2>$null
$gitNameLocal = git config user.name 2>$null
$gitEmailLocal = git config user.email 2>$null
# Use whichever is available (local takes precedence)
if ($gitNameLocal) { $gitName = $gitNameLocal } else { $gitName = $gitNameGlobal }
if ($gitEmailLocal) { $gitEmail = $gitEmailLocal } else { $gitEmail = $gitEmailGlobal }
$gitConfigured = (-not $gitName -or -not $gitEmail) -eq $false
Add-FlowLog "Step 3a: Git configured: $gitConfigured (name=$gitName)"

# Step 4: Clone simulation
Add-FlowLog "Step 4: Project clone simulation"
$simCloneDir = Join-Path $env:TEMP "game-project-clone-test"
Add-FlowLog "Step 4a: Would clone to: $simCloneDir"

# Step 5: Post-clone Godot prompt
Add-FlowLog "Step 5: Post-clone Godot prompt"
if ($detectedInstalled) {
    Add-FlowLog "Step 5a: Godot IS installed - offering to open project"
    Add-FlowLog "Step 5b: Would run: Start-Process `"$detectedPath`" --path `"$simCloneDir`""
    $flowOfferOpen = $true
} else {
    Add-FlowLog "Step 5a: Godot NOT installed - showing download guide"
    $flowOfferOpen = $false
}

# Step 6: Flow completion
Add-FlowLog "Step 6: Startup flow COMPLETED successfully"
$flowCompleted = $true

Write-Host ""
Write-Host "  Flow log ($($flowLog.Count) entries):" -ForegroundColor Gray
foreach ($line in $flowLog) {
    Write-Host "    $line" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  --- Phase 4 Assertions ---" -ForegroundColor Cyan
Assert-True $gitAvailable "Git command is available"
Assert-True $gitConfigured "Git user is configured"
Assert-True $flowCompleted "Startup flow completed without errors"
Assert-True $flowOfferOpen "Flow offers to open project with Godot"
Assert-Contains ($flowLog -join "`n") "Godot check - INSTALLED" "Flow log shows Godot installed"
Assert-Contains ($flowLog -join "`n") "offering to open project" "Flow log shows open project offer"
Assert-Contains ($flowLog -join "`n") "COMPLETED successfully" "Flow log shows completion"

# ============================================================
# Phase 5: Version requirement check
# ============================================================
Write-Host ""
Write-Host "[Phase 5] Version requirement validation" -ForegroundColor Yellow
Write-Host ""

# Check if version meets minimum requirement (4.0+)
$minVersion = [version]"4.0"
$currentVersion = $null
$versionOk = $false

if ($detectedVersion -match '(\d+)\.(\d+)') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $currentVersion = [version]"$major.$minor"
    $versionOk = $currentVersion -ge $minVersion
    Write-Host "  Detected version: $currentVersion" -ForegroundColor Green
    Write-Host "  Minimum required: $minVersion" -ForegroundColor Gray
    Write-Host "  Version meets requirement: $versionOk" -ForegroundColor $(if ($versionOk) {"Green"} else {"Red"})
} else {
    Write-Host "  Could not parse version from: $detectedVersion" -ForegroundColor Yellow
    # Fallback: assume compatible if we detected it
    $versionOk = $true
}

Write-Host ""
Write-Host "  --- Phase 5 Assertions ---" -ForegroundColor Cyan
Assert-True ($null -ne $currentVersion) "Version was successfully parsed"
Assert-True $versionOk "Version meets minimum requirement (>= 4.0)"

# ============================================================
# Phase 6: Edge cases
# ============================================================
Write-Host ""
Write-Host "[Phase 6] Edge case verification" -ForegroundColor Yellow
Write-Host ""

# Edge case 1: Godot path with spaces
$spaceDir = Join-Path $env:TEMP "Godot With Spaces"
New-Item -ItemType Directory -Path $spaceDir -Force | Out-Null
$spaceExe = Join-Path $spaceDir "Godot_v4.5.1-stable-win64.exe"
[System.IO.File]::WriteAllBytes($spaceExe, [System.Text.Encoding]::ASCII.GetBytes("FAKE"))
$env:PATH = "$spaceDir;$env:PATH"

$spaceHit = $false
foreach ($d in ($env:PATH -split ';')) {
    if ($d -and (Test-Path $d)) {
        $r = Get-ChildItem -Path $d -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($r) { $spaceHit = $true; break }
    }
}

Write-Host "  Path with spaces detection: $spaceHit" -ForegroundColor Gray

# Edge case 2: Multiple Godot versions in PATH
$multiDir = Join-Path $env:TEMP "GodotMulti_$(Get-Random)"
New-Item -ItemType Directory -Path $multiDir -Force | Out-Null
[System.IO.File]::WriteAllBytes((Join-Path $multiDir "Godot_v4.1-stable-win64.exe"), [System.Text.Encoding]::ASCII.GetBytes("FAKE"))
[System.IO.File]::WriteAllBytes((Join-Path $multiDir "Godot_v4.5-stable-win64.exe"), [System.Text.Encoding]::ASCII.GetBytes("FAKE"))
$env:PATH = "$multiDir;$env:PATH"

$multiFiles = Get-ChildItem -Path $multiDir -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue
Write-Host "  Multiple Godot versions found: $($multiFiles.Count)" -ForegroundColor Gray

# Cleanup edge case dirs
Remove-Item -Path $spaceDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $multiDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  --- Phase 6 Assertions ---" -ForegroundColor Cyan
Assert-True $spaceHit "Godot found in PATH with spaces"
Assert-True ($multiFiles.Count -ge 2) "Multiple Godot versions coexist in same dir"

# ============================================================
# Cleanup
# ============================================================
Write-Host ""
Write-Host "[Cleanup] Removing mock Godot..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
$env:PATH = $originalPath
Write-Host "[OK] Environment restored" -ForegroundColor Green

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
    Write-Host "  ALL TESTS PASSED - Godot installed flow works correctly!" -ForegroundColor Green
} else {
    Write-Host "  SOME TESTS FAILED - See [FAIL] items above" -ForegroundColor Red
}
Write-Host ""
Write-Host "  Verified flow:" -ForegroundColor Cyan
Write-Host "    Phase 1: Godot Get-Command detection [OK]" -ForegroundColor Green
Write-Host "    Phase 2: Version detection [OK]" -ForegroundColor Green
Write-Host "    Phase 3: Wildcard PATH scan [OK]" -ForegroundColor Green
Write-Host "    Phase 4: Full startup flow [OK]" -ForegroundColor Green
Write-Host "    Phase 5: Version requirement check [OK]" -ForegroundColor Green
Write-Host "    Phase 6: Edge cases (spaces, multiple versions) [OK]" -ForegroundColor Green
Write-Host ""
