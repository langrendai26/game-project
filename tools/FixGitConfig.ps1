#requires -Version 5.0
<#
.SYNOPSIS
    Detect and fix Git core.longpaths setting.
.DESCRIPTION
    Checks if core.longpaths is enabled globally.
    If not, enables it and verifies the fix.
    Also checks core.quotepath and init.defaultBranch as bonus fixes.
#>

$ErrorActionPreference = "Continue"
$fixesApplied = 0
$fixesNeeded = 0

function Write-Status {
    param([string]$Msg, [string]$Color = "White")
    Write-Host "  $Msg" -ForegroundColor $Color
}

# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Git Config Auto-Fix Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. Check Git is installed
# ============================================================
Write-Host "[1/4] Checking Git installation..." -ForegroundColor Yellow

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Status "Git NOT found in PATH" "Red"
    Write-Status "Install Git first: winget install Git.Git" "Yellow"
    exit 1
}

Write-Status "Git found: $($gitCmd.Source)" "Green"
Write-Host ""

# ============================================================
# 2. Check and fix core.longpaths
# ============================================================
Write-Host "[2/4] Checking core.longpaths..." -ForegroundColor Yellow

$currentLongpaths = $null
try {
    $currentLongpaths = (git config --global core.longpaths 2>$null).Trim()
} catch { }

if ($currentLongpaths -eq "true") {
    Write-Status "core.longpaths = true (already enabled)" "Green"
} else {
    $fixesNeeded++
    Write-Status "core.longpaths = '$currentLongpaths' (NOT enabled)" "Yellow"
    Write-Status "Applying fix..." "Cyan"

    try {
        git config --global core.longpaths true 2>$null
        Start-Sleep -Milliseconds 300

        $verify = $null
        try {
            $verify = (git config --global core.longpaths 2>$null).Trim()
        } catch { }

        if ($verify -eq "true") {
            Write-Status "Fix applied: core.longpaths = true" "Green"
            $fixesApplied++
        } else {
            Write-Status "Fix FAILED: still '$verify'" "Red"
            Write-Status "Manual fix needed:" "Yellow"
            Write-Status "  Run PowerShell as Administrator, then:" "Yellow"
            Write-Status "  git config --global core.longpaths true" "Yellow"
        }
    } catch {
        Write-Status "Fix FAILED: $($_.Exception.Message)" "Red"
        Write-Status "Run PowerShell as Administrator and retry" "Yellow"
    }
}
Write-Host ""

# ============================================================
# 3. Check and fix core.quotepath
# ============================================================
Write-Host "[3/4] Checking core.quotepath..." -ForegroundColor Yellow

$currentQuotepath = $null
try {
    $currentQuotepath = (git config --global core.quotepath 2>$null).Trim()
} catch { }

if ($currentQuotepath -eq "false") {
    Write-Status "core.quotepath = false (Chinese filenames display correctly)" "Green"
} else {
    $fixesNeeded++
    Write-Status "core.quotepath = '$currentQuotepath' (Chinese paths may be escaped)" "Yellow"
    Write-Status "Applying fix..." "Cyan"

    try {
        git config --global core.quotepath false 2>$null
        Start-Sleep -Milliseconds 300

        $verify = $null
        try {
            $verify = (git config --global core.quotepath 2>$null).Trim()
        } catch { }

        if ($verify -eq "false") {
            Write-Status "Fix applied: core.quotepath = false" "Green"
            $fixesApplied++
        } else {
            Write-Status "Fix FAILED: still '$verify'" "Red"
            Write-Status "Run as Administrator: git config --global core.quotepath false" "Yellow"
        }
    } catch {
        Write-Status "Fix FAILED: $($_.Exception.Message)" "Red"
    }
}
Write-Host ""

# ============================================================
# 4. Check and fix init.defaultBranch
# ============================================================
Write-Host "[4/4] Checking init.defaultBranch..." -ForegroundColor Yellow

$currentBranch = $null
try {
    $currentBranch = (git config --global init.defaultBranch 2>$null).Trim()
} catch { }

if ($currentBranch -eq "main") {
    Write-Status "init.defaultBranch = main (correct)" "Green"
} else {
    $fixesNeeded++
    Write-Status "init.defaultBranch = '$currentBranch' (defaults to master)" "Yellow"
    Write-Status "Applying fix..." "Cyan"

    try {
        git config --global init.defaultBranch main 2>$null
        Start-Sleep -Milliseconds 300

        $verify = $null
        try {
            $verify = (git config --global init.defaultBranch 2>$null).Trim()
        } catch { }

        if ($verify -eq "main") {
            Write-Status "Fix applied: init.defaultBranch = main" "Green"
            $fixesApplied++
        } else {
            Write-Status "Fix FAILED: still '$verify'" "Red"
            Write-Status "Run as Administrator: git config --global init.defaultBranch main" "Yellow"
        }
    } catch {
        Write-Status "Fix FAILED: $($_.Exception.Message)" "Red"
    }
}
Write-Host ""

# ============================================================
# Summary
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fixes needed:  $fixesNeeded" -ForegroundColor $(if ($fixesNeeded -gt 0) { "Yellow" } else { "Gray" })
Write-Host "  Fixes applied: $fixesApplied" -ForegroundColor $(if ($fixesApplied -gt 0) { "Green" } else { "Gray" })
Write-Host ""

if ($fixesNeeded -eq 0) {
    Write-Host "  All Git config settings are correct!" -ForegroundColor Green
} elseif ($fixesApplied -eq $fixesNeeded) {
    Write-Host "  All fixes applied successfully!" -ForegroundColor Green
} else {
    $remaining = $fixesNeeded - $fixesApplied
    Write-Host "  $remaining fix(es) failed. Run as Administrator and retry." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Verified config:" -ForegroundColor Cyan
Write-Host "    core.longpaths     = $(git config --global core.longpaths 2>$null)" -ForegroundColor Gray
Write-Host "    core.quotepath     = $(git config --global core.quotepath 2>$null)" -ForegroundColor Gray
Write-Host "    init.defaultBranch  = $(git config --global init.defaultBranch 2>$null)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
