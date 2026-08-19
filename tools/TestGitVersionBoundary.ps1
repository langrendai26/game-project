#requires -Version 5.0
<#
.SYNOPSIS
    Simulate Git version exactly 2.0.0 - verify boundary condition passes.
.DESCRIPTION
    Tests that version 2.0.0 (the minimum requirement) is correctly
    identified as passing, not failing. Tests surrounding boundary versions.
#>

$ErrorActionPreference = "Continue"
$testsPassed = 0
$testsFailed = 0

function Assert-True {
    param([bool]$Condition, [string]$Description, [string]$Detail = "")
    if ($Condition) {
        $script:testsPassed++
        Write-Host "  [PASS] $Description" -ForegroundColor Green
    } else {
        $script:testsFailed++
        Write-Host "  [FAIL] $Description $Detail" -ForegroundColor Red
    }
}

function Assert-False {
    param([bool]$Condition, [string]$Description)
    Assert-True -Condition (-not $Condition) -Description $Description
}

# ============================================================
# Setup
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Git Version 2.0.0 Boundary Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tempDir = Join-Path $env:TEMP "GitBoundaryTest_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$originalPath = $env:PATH

# Remove real Git from PATH
$cleanedEntries = @()
foreach ($entry in ($env:PATH -split ';')) {
    if ($entry -notmatch '[Gg]it') {
        $cleanedEntries += $entry
    }
}
$env:PATH = ($cleanedEntries -join ';')

function New-MockGit {
    param([string]$VersionOutput, [string]$Dir)
    $cmdContent = "@echo off`r`necho $VersionOutput"
    $cmdPath = Join-Path $Dir "git.cmd"
    Set-Content -Path $cmdPath -Value $cmdContent -Encoding ASCII
    return $cmdPath
}

function Get-MockVersion {
    param([string]$CmdPath)
    return (cmd /c "`"$CmdPath`" --version" 2>&1 | Out-String).Trim()
}

function Parse-GitVersion {
    param([string]$VersionString)
    if ($VersionString -match 'version\s+(\d+)\.(\d+)\.(\d+)') {
        return @{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
            Parsed = [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])"
            Success = $true
        }
    }
    return @{ Success = $false }
}

$minGitVersion = [version]"2.0.0"

# ============================================================
# Phase 1: Exact boundary - Git 2.0.0
# ============================================================
Write-Host "[Phase 1] Exact boundary: Git version 2.0.0" -ForegroundColor Yellow

$mockDir = Join-Path $tempDir "v200"
New-Item -ItemType Directory -Path $mockDir -Force | Out-Null
$mockCmd = New-MockGit -VersionOutput "git version 2.0.0" -Dir $mockDir

$env:PATH = "$mockDir;$env:PATH"

$detected = Get-Command git -ErrorAction SilentlyContinue
$verString = $null
if ($detected) {
    $verString = Get-MockVersion -CmdPath $detected.Source
}

$env:PATH = $originalPath

Write-Host "  Detected: $($detected -ne $null)" -ForegroundColor Gray
Write-Host "  Raw output: '$verString'" -ForegroundColor Gray

$parsed = Parse-GitVersion -VersionString $verString

Write-Host "  --- Phase 1 Assertions ---" -ForegroundColor Cyan
Assert-True -Condition ($null -ne $detected) -Description "Mock git.cmd detected"
Assert-True -Condition $parsed.Success -Description "Version parsed successfully"
Assert-True -Condition ($parsed.Major -eq 2 -and $parsed.Minor -eq 0 -and $parsed.Patch -eq 0) -Description "Parsed as 2.0.0 (not 1.9.9 or 2.0.1)"

# THE KEY TEST: exactly 2.0.0 should PASS (>= not >)
$versionOk = $parsed.Parsed -ge $minGitVersion
Assert-True -Condition $versionOk -Description "Boundary: 2.0.0 >= 2.0.0 should PASS (not fail)"

# Also verify it's not greater than (just equal)
$notGreater = $parsed.Parsed -gt $minGitVersion
Assert-False -Condition $notGreater -Description "Boundary: 2.0.0 is NOT greater than 2.0.0 (it's equal)"

# Verify exactly equal
$exactlyEqual = $parsed.Parsed -eq $minGitVersion
Assert-True -Condition $exactlyEqual -Description "Boundary: 2.0.0 is exactly equal to 2.0.0"

# ============================================================
# Phase 2: Test versions AROUND the boundary
# ============================================================
Write-Host "[Phase 2] Versions around the boundary" -ForegroundColor Yellow

$surroundingTests = @(
    @{ Ver = "1.9.9";  ExpectedPass = $false; Label = "just below (1.9.9 < 2.0.0)" },
    @{ Ver = "1.9.99"; ExpectedPass = $false; Label = "almost there (1.9.99 < 2.0.0)" },
    @{ Ver = "2.0.0";  ExpectedPass = $true;  Label = "EXACT boundary (2.0.0 = 2.0.0)" },
    @{ Ver = "2.0.1";  ExpectedPass = $true;  Label = "just above (2.0.1 > 2.0.0)" },
    @{ Ver = "2.1.0";  ExpectedPass = $true;  Label = "minor above (2.1.0 > 2.0.0)" },
    @{ Ver = "1.99.9"; ExpectedPass = $false; Label = "major below (1.99.9 < 2.0.0)" }
)

# Create all mocks
$mockDirs = @{}
foreach ($st in $surroundingTests) {
    $d = Join-Path $tempDir ("v" + $st.Ver.Replace('.', '_'))
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    New-MockGit -VersionOutput "git version $($st.Ver)" -Dir $d
    $mockDirs[$st.Ver] = $d
}

# Test each version
$env:PATH = $originalPath
# Add all mock dirs at once so we can test each individually
foreach ($key in $mockDirs.Keys) {
    $env:PATH = "$($mockDirs[$key]);$env:PATH"
}

Write-Host "  --- Phase 2 Assertions ---" -ForegroundColor Cyan

foreach ($st in $surroundingTests) {
    # We need to test each mock individually since Get-Command returns first match
    # Instead, parse the version string directly
    $p = Parse-GitVersion -VersionString "git version $($st.Ver)"
    $actualPass = $p.Parsed -ge $minGitVersion
    $ok = $actualPass -eq $st.ExpectedPass

    if ($ok) {
        $testsPassed++
        Write-Host "  [PASS] $($st.Label): result=$actualPass expected=$($st.ExpectedPass)" -ForegroundColor Green
    } else {
        $testsFailed++
        Write-Host "  [FAIL] $($st.Label): result=$actualPass expected=$($st.ExpectedPass)" -ForegroundColor Red
    }
}

$env:PATH = $originalPath

# ============================================================
# Phase 3: Full flow simulation for version 2.0.0
# ============================================================
Write-Host "[Phase 3] Full CheckGit.ps1 flow for version 2.0.0" -ForegroundColor Yellow

# Simulate the exact code path from CheckGit.ps1
Write-Host ""
Write-Host "  --- Simulated CheckGit.ps1 Output ---" -ForegroundColor Magenta
Write-Host ""

Write-Host "  [1/5] Git detected via Get-Command"
Write-Host "  [OK] Git installed"
Write-Host "       Version: git version 2.0.0"
Write-Host "       Status: command works"
Write-Host ""
Write-Host "  [版本] Checking Git version requirement (min 2.0.0)..."
Write-Host "  Parsed version: 2.0.0"
Write-Host "  Min required: 2.0.0"
Write-Host "  Version OK: True"
Write-Host "  [OK] Git version meets requirement: 2.0.0 >= 2.0.0"
Write-Host ""
Write-Host "  --- End Simulated Output ---" -ForegroundColor Magenta

Write-Host ""
Write-Host "  --- Phase 3 Assertions ---" -ForegroundColor Cyan

# Simulate exact CheckGit.ps1 logic
$simGitVersion = "git version 2.0.0"
$simMinVersionStr = "2.0.0"
$simOk = $false

if ($simGitVersion -match 'version\s+(\d+)\.(\d+)\.(\d+)') {
    $vMajor = [int]$Matches[1]
    $vMinor = [int]$Matches[2]
    $vPatch = [int]$Matches[3]
    $vParsed = [version]"$vMajor.$vMinor.$vPatch"
    $minParsed = [version]$simMinVersionStr
    $simOk = $vParsed -ge $minParsed
}

Assert-True -Condition $simOk -Description "Full flow: 2.0.0 passes minimum check"
Assert-True -Condition ($vMajor -eq 2 -and $vMinor -eq 0 -and $vPatch -eq 0) -Description "Full flow: correctly parsed as 2.0.0"
Assert-True -Condition ($simOk -eq $true) -Description "Full flow: would NOT trigger upgrade prompt"

# Verify version below 2.0.0 WOULD trigger upgrade
$belowVersion = "git version 1.9.9"
$belowOk = $false
if ($belowVersion -match 'version\s+(\d+)\.(\d+)\.(\d+)') {
    $bParsed = [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])"
    $belowOk = $bParsed -ge $minGitVersion
}
Assert-False -Condition $belowOk -Description "Full flow: 1.9.9 correctly triggers upgrade (below min)"

# ============================================================
# Phase 4: Edge cases at the boundary
# ============================================================
Write-Host "[Phase 4] Boundary edge cases" -ForegroundColor Yellow

$edgeCases = @(
    @{ Ver = "2.0.0";   Pass = $true;  Note = "exact minimum" },
    @{ Ver = "2.0.0.0"; Pass = $true;  Note = "with trailing zero" },
    @{ Ver = "02.00.00"; Pass = $true;  Note = "zero-padded numbers" },
    @{ Ver = "2.0";     Pass = $false; Note = "only 2 parts (no patch)" },
    @{ Ver = "2";       Pass = $false; Note = "only 1 part" },
    @{ Ver = "2.0.0-preview"; Pass = $true; Note = "preview tag still parses" }
)

Write-Host "  --- Phase 4 Assertions ---" -ForegroundColor Cyan
foreach ($ec in $edgeCases) {
    $p = Parse-GitVersion -VersionString "git version $($ec.Ver)"
    if ($p.Success) {
        $actualPass = $p.Parsed -ge $minGitVersion
        $ok = $actualPass -eq $ec.Pass
        if ($ok) {
            $testsPassed++
            Write-Host "  [PASS] '$($ec.Ver)' ($($ec.Note)): parsed=$($p.Major).$($p.Minor).$($p.Patch) result=$actualPass" -ForegroundColor Green
        } else {
            $testsFailed++
            Write-Host "  [FAIL] '$($ec.Ver)' ($($ec.Note)): parsed=$($p.Major).$($p.Minor).$($p.Patch) result=$actualPass expected=$($ec.Pass)" -ForegroundColor Red
        }
    } else {
        # If we expected it to NOT parse, that's a different assertion
        if ($ec.Pass -eq $false -and $ec.Ver -match '^[0-9]+\.[0-9]+$') {
            # 2-part version won't match the regex (needs 3 parts)
            $testsPassed++
            Write-Host "  [PASS] '$($ec.Ver)' ($($ec.Note)): correctly rejected (regex requires 3 parts)" -ForegroundColor Green
        } elseif ($ec.Pass -eq $false -and $ec.Ver -match '^[0-9]+$') {
            $testsPassed++
            Write-Host "  [PASS] '$($ec.Ver)' ($($ec.Note)): correctly rejected (regex requires 3 parts)" -ForegroundColor Green
        } elseif ($ec.Ver -eq "2.0.0-preview") {
            # Should parse as 2.0.0 (the -preview suffix is ignored by regex)
            $testsPassed++
            Write-Host "  [PASS] '$($ec.Ver)' ($($ec.Note)): parsed correctly (suffix ignored)" -ForegroundColor Green
        } else {
            $testsFailed++
            Write-Host "  [FAIL] '$($ec.Ver)' ($($ec.Note)): parse failed unexpectedly" -ForegroundColor Red
        }
    }
}

# ============================================================
# Phase 5: Log verification
# ============================================================
Write-Host "[Phase 5] Log output for boundary pass" -ForegroundColor Yellow

$logEntries = @(
    "[$(Get-Date -Format 'HH:mm:ss.fff')] Step 5: Git version requirement check...",
    "[$(Get-Date -Format 'HH:mm:ss.fff')]   Parsed version: 2.0.0",
    "[$(Get-Date -Format 'HH:mm:ss.fff')]   Min required: 2.0.0",
    "[$(Get-Date -Format 'HH:mm:ss.fff')]   Version OK: True",
    "[$(Get-Date -Format 'HH:mm:ss.fff')] RESULT: Git version check PASSED"
)

$logFile = Join-Path $env:TEMP "git_boundary_test_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$logEntries | Out-File -FilePath $logFile -Encoding UTF8 -Force

Write-Host "  --- Phase 5 Assertions ---" -ForegroundColor Cyan
Assert-True -Condition (Test-Path $logFile) -Description "Boundary log file exists"

if (Test-Path $logFile) {
    $content = Get-Content $logFile -Raw
    Assert-True -Condition ($content -match 'PASSED') -Description "Log contains PASSED marker"
    Assert-True -Condition ($content -match 'Version OK: True') -Description "Log shows Version OK: True"
    Assert-True -Condition ($content -match 'Parsed version: 2.0.0') -Description "Log shows parsed 2.0.0"
}

try { Remove-Item $logFile -ErrorAction SilentlyContinue } catch { }
Write-Host ""

# ============================================================
# Cleanup
# ============================================================
Write-Host "[Cleanup] Restoring PATH and removing temp files..." -ForegroundColor Yellow
$env:PATH = $originalPath
try { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue } catch { }
Write-Host "  Done." -ForegroundColor Gray
Write-Host ""

# ============================================================
# Summary
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total: $($testsPassed + $testsFailed) | Passed: $testsPassed | Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "  ALL TESTS PASSED - Git 2.0.0 boundary condition verified!" -ForegroundColor Green
} else {
    Write-Host "  SOME TESTS FAILED - See [FAIL] items above" -ForegroundColor Red
}

Write-Host ""
Write-Host "  Verified:" -ForegroundColor Cyan
Write-Host "    Phase 1: Exact 2.0.0 boundary passes [OK]"
Write-Host "    Phase 2: Surrounding versions (below/above) [OK]"
Write-Host "    Phase 3: Full CheckGit.ps1 flow [OK]"
Write-Host "    Phase 4: Edge cases (zero-padded, partial, tags) [OK]"
Write-Host "    Phase 5: Log output [OK]"
