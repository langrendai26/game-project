#requires -Version 5.0
<#
.SYNOPSIS
    Godot project environment checker.
    Verifies Git config, Godot engine, and project requirements.
.DESCRIPTION
    Checks:
    - PowerShell version and execution policy
    - Git installation, version (>= 2.0.0), and user config
    - Godot installation and version (>= 4.0)
    - Project file integrity (project.godot)
    - Network connectivity to GitHub
    - Required directories
    - .gitignore configuration
    Produces a summary report and detailed log file.
#>

$ErrorActionPreference = "Continue"

# ============================================================
# Setup
# ============================================================
$scriptName = "CheckEnvironment"
$startTime = Get-Date
$logFile = Join-Path $env:TEMP "env_check_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$envLog = @()
$checksPassed = 0
$checksFailed = 0
$checksWarn = 0
$totalChecks = 0

$MIN_GIT_VERSION = "2.0.0"
$MIN_GODOT_VERSION = "4.0.0"
$REPO_URL = "https://github.com/langrendai26/game-project.git"

# Try to find project root (look for project.godot)
$projectRoot = $null
$searchDirs = @($PSScriptRoot, (Get-Location).Path, (Get-Location).Path + "\..")
foreach ($d in $searchDirs) {
    if (Test-Path (Join-Path $d "project.godot")) {
        $projectRoot = (Resolve-Path $d).Path
        break
    }
}
if (-not $projectRoot) {
    $projectRoot = (Get-Location).Path
}

function Add-EnvLog {
    param([string]$Message)
    $ts = Get-Date -Format "HH:mm:ss.fff"
    $entry = "[$ts] $Message"
    $script:envLog += $entry
    Write-Host "  [LOG] $Message" -ForegroundColor DarkGray
}

function Check-Pass {
    param([string]$Name, [string]$Detail = "")
    $script:checksPassed++
    $script:totalChecks++
    Write-Host "  [PASS] $Name $Detail" -ForegroundColor Green
    Add-EnvLog "  CHECK PASS: $Name $Detail"
}

function Check-Fail {
    param([string]$Name, [string]$Detail = "", [string]$Fix = "")
    $script:checksFailed++
    $script:totalChecks++
    Write-Host "  [FAIL] $Name $Detail" -ForegroundColor Red
    if ($Fix) {
        Write-Host "         Fix: $Fix" -ForegroundColor Yellow
    }
    Add-EnvLog "  CHECK FAIL: $Name $Detail"
    if ($Fix) { Add-EnvLog "    Fix: $Fix" }
}

function Check-Warn {
    param([string]$Name, [string]$Detail = "", [string]$Fix = "")
    $script:checksWarn++
    $script:totalChecks++
    Write-Host "  [WARN] $Name $Detail" -ForegroundColor Yellow
    if ($Fix) {
        Write-Host "         Tip: $Fix" -ForegroundColor DarkYellow
    }
    Add-EnvLog "  CHECK WARN: $Name $Detail"
    if ($Fix) { Add-EnvLog "    Tip: $Fix" }
}

# ============================================================
# Header
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Godot Project Environment Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Time: $startTime" -ForegroundColor Gray
Write-Host "  Log:  $logFile" -ForegroundColor Gray
Write-Host ""

Add-EnvLog "=== Environment Check Started ==="
Add-EnvLog "Script: $scriptName"
Add-EnvLog "Time: $startTime"
Add-EnvLog "OS: $([System.Environment]::OSVersion.VersionString)"
Add-EnvLog "PowerShell: $($PSVersionTable.PSVersion)"
Add-EnvLog "Project root: $projectRoot"

# ============================================================
# 1. System checks
# ============================================================
Write-Host "[1/7] System Environment" -ForegroundColor Cyan
Add-EnvLog "Section 1: System Environment"

# PowerShell version
$psVer = $PSVersionTable.PSVersion
$psVerOk = $psVer -ge [version]"5.0"
if ($psVerOk) {
    Check-Pass "PowerShell version" "($($psVer.ToString()) >= 5.0)"
} else {
    Check-Fail "PowerShell version" "($($psVer.ToString()) < 5.0)" "Upgrade to PowerShell 5.1 or later"
}

# Execution policy
$execPolicy = Get-ExecutionPolicy -Scope CurrentUser
Add-EnvLog "  Execution policy (CurrentUser): $execPolicy"
if ($execPolicy -eq 'Restricted') {
    Check-Warn "Execution policy" "(Restricted)" "Run: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass"
} else {
    Check-Pass "Execution policy" "(CurrentUser=$execPolicy)"
}

# OS architecture
$osArch = [System.Environment]::Is64BitOperatingSystem
if ($osArch) {
    Check-Pass "OS architecture" "(64-bit)"
} else {
    Check-Fail "OS architecture" "(32-bit not supported)" "Use a 64-bit Windows system"
}

Write-Host ""

# ============================================================
# 2. Git checks
# ============================================================
Write-Host "[2/7] Git Installation" -ForegroundColor Cyan
Add-EnvLog "Section 2: Git Installation"

$gitCmd = Get-Command git -ErrorAction SilentlyContinue

if ($gitCmd) {
    $gitPath = $gitCmd.Source
    Add-EnvLog "  Git found at: $gitPath"
    Check-Pass "Git found" "($gitPath)"

    # Get version
    $gitVerRaw = $null
    try {
        $gitVerRaw = (cmd /c "`"$gitPath`" --version" 2>&1 | Out-String).Trim()
    } catch {
        $gitVerRaw = $null
    }

    if ($gitVerRaw -and $gitVerRaw -match 'version\s+(\d+)\.(\d+)\.(\d+)') {
        $gitMajor = [int]$Matches[1]
        $gitMinor = [int]$Matches[2]
        $gitPatch = [int]$Matches[3]
        $gitVerObj = [version]"$gitMajor.$gitMinor.$gitPatch"
        $minGit = [version]$MIN_GIT_VERSION

        Add-EnvLog "  Git version raw: $gitVerRaw"
        Add-EnvLog "  Parsed: $gitMajor.$gitMinor.$gitPatch"

        if ($gitVerObj -ge $minGit) {
            Check-Pass "Git version" "($gitMajor.$gitMinor.$gitPatch >= $MIN_GIT_VERSION)"
        } else {
            Check-Fail "Git version" "($gitMajor.$gitMinor.$gitPatch < $MIN_GIT_VERSION)" "Run: winget upgrade Git.Git"
        }

        # Boundary check
        $isBoundary = ($gitMajor -eq [int]($minGit.Major) -and $gitMinor -eq [int]($minGit.Minor) -and $gitPatch -eq [int]($minGit.Build))
        if ($isBoundary) {
            Add-EnvLog "  **BOUNDARY**: Git version exactly equals minimum"
        }
    } else {
        Check-Warn "Git version parse" "(could not parse: '$gitVerRaw')" "Check git --version output manually"
    }

    # Test git functionality
    try {
        $null = cmd /c "`"$gitPath`" rev-parse --is-inside-work-tree 2>nul" 2>&1
        $gitFuncTest = $true
    } catch {
        $gitFuncTest = $false
    }
    # rev-parse may fail if not in a repo, that's OK
    try {
        $null = cmd /c "`"$gitPath`" config --list 2>nul" 2>&1
        Check-Pass "Git functional" "(config command works)"
    } catch {
        Check-Fail "Git functional" "(config command failed)" "Reinstall Git"
    }
} else {
    Add-EnvLog "  Git NOT found via Get-Command"
    Check-Fail "Git found" "(not in PATH)" "Run: winget install Git.Git or visit https://git-scm.com/download/win"

    # Deep scan preset paths
    $gitSearchPaths = @(
        "${env:ProgramFiles}\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "${env:LOCALAPPDATA}\Programs\Git\cmd\git.exe",
        "${env:USERPROFILE}\scoop\shims\git.exe"
    )
    foreach ($p in $gitSearchPaths) {
        if (Test-Path $p) {
            Check-Warn "Git found (not in PATH)" "($p)" "Add to PATH: $p"
            break
        }
    }
}

Write-Host ""

# ============================================================
# 3. Git user configuration
# ============================================================
Write-Host "[3/7] Git User Configuration" -ForegroundColor Cyan
Add-EnvLog "Section 3: Git User Configuration"

if ($gitCmd) {
    # User name
    $gitUserName = $null
    try {
        $gitUserName = (cmd /c "`"$($gitCmd.Source)`" config --global user.name 2>nul" 2>&1 | Out-String).Trim()
    } catch { }

    if ($gitUserName -and $gitUserName -ne "") {
        Check-Pass "Git user.name" "($gitUserName)"
        Add-EnvLog "  user.name: $gitUserName"
    } else {
        # Try local config
        try {
            $gitUserName = (cmd /c "`"$($gitCmd.Source)`" config user.name 2>nul" 2>&1 | Out-String).Trim()
        } catch { }
        if ($gitUserName) {
            Check-Pass "Git user.name (local)" "($gitUserName)"
        } else {
            Check-Fail "Git user.name" "(not configured)" "Run: git config --global user.name 'Your Name'"
        }
    }

    # User email
    $gitUserEmail = $null
    try {
        $gitUserEmail = (cmd /c "`"$($gitCmd.Source)`" config --global user.email 2>nul" 2>&1 | Out-String).Trim()
    } catch { }

    if ($gitUserEmail -and $gitUserEmail -ne "") {
        Check-Pass "Git user.email" "($gitUserEmail)"
        Add-EnvLog "  user.email: $gitUserEmail"
    } else {
        try {
            $gitUserEmail = (cmd /c "`"$($gitCmd.Source)`" config user.email 2>nul" 2>&1 | Out-String).Trim()
        } catch { }
        if ($gitUserEmail) {
            Check-Pass "Git user.email (local)" "($gitUserEmail)"
        } else {
            Check-Fail "Git user.email" "(not configured)" "Run: git config --global user.email 'you@example.com'"
        }
    }

    # init.defaultBranch
    $defaultBranch = $null
    try {
        $defaultBranch = (cmd /c "`"$($gitCmd.Source)`" config --global init.defaultBranch 2>nul" 2>&1 | Out-String).Trim()
    } catch { }

    if ($defaultBranch) {
        Check-Pass "Git init.defaultBranch" "($defaultBranch)"
    } else {
        Check-Warn "Git init.defaultBranch" "(not set, defaults to master)" "Run: git config --global init.defaultBranch main"
    }

    # core.longpaths (Windows-specific)
    $longPaths = $null
    try {
        $longPaths = (cmd /c "`"$($gitCmd.Source)`" config --global core.longpaths 2>nul" 2>&1 | Out-String).Trim()
    } catch { }

    if ($longPaths -eq "true") {
        Check-Pass "Git core.longpaths" "(enabled)"
    } else {
        Check-Warn "Git core.longpaths" "(not enabled)" "Run: git config --global core.longpaths true"
    }

    # core.quotepath
    $quotePath = $null
    try {
        $quotePath = (cmd /c "`"$($gitCmd.Source)`" config --global core.quotepath 2>nul" 2>&1 | Out-String).Trim()
    } catch { }

    if ($quotePath -eq "false") {
        Check-Pass "Git core.quotepath" "(false, shows Chinese filenames correctly)"
    } else {
        Check-Warn "Git core.quotepath" "(not set, may show escaped Chinese paths)" "Run: git config --global core.quotepath false"
    }
} else {
    Check-Fail "Git config" "(Git not installed)" "Install Git first"
}

Write-Host ""

# ============================================================
# 4. Godot engine checks
# ============================================================
Write-Host "[4/7] Godot Engine" -ForegroundColor Cyan
Add-EnvLog "Section 4: Godot Engine"

$godotCmd = Get-Command godot -ErrorAction SilentlyContinue
$godotPath = $null
$godotVersionRaw = $null

if ($godotCmd) {
    $godotPath = $godotCmd.Source
    Add-EnvLog "  Godot found at: $godotPath"
    Check-Pass "Godot found" "($godotPath)"

    # Try to get version
    try {
        $godotVersionRaw = (cmd /c "`"$godotPath`" --version 2>&1" | Out-String).Trim()
    } catch {
        $godotVersionRaw = $null
    }
} else {
    # Try common names
    $godotNames = @("godot", "godot.exe", "Godot_v4*.exe", "godot-mono.exe", "Godot_v4*_mono*.exe")
    foreach ($name in $godotNames) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) {
            $godotPath = $found.Source
            break
        }
    }

    # Wildcard PATH scan
    if (-not $godotPath) {
        $pathDirs = $env:PATH -split ';'
        foreach ($dir in $pathDirs) {
            if ($dir -and (Test-Path $dir)) {
                try {
                    $found = Get-ChildItem -Path $dir -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($found) {
                        $godotPath = $found.FullName
                        break
                    }
                } catch { }
            }
        }
    }

    # Check preset locations
    if (-not $godotPath) {
        $godotPresetPaths = @(
            "$env:USERPROFILE\Godot\Godot_v4*.exe",
            "${env:ProgramFiles}\Godot\Godot_v4*.exe",
            "$env:LOCALAPPDATA\Godot\Godot_v4*.exe",
            "D:\Godot\Godot_v4*.exe",
            "D:\Programs\Godot\Godot_v4*.exe"
        )
        foreach ($p in $godotPresetPaths) {
            if (Test-Path $p) {
                $found = Get-ChildItem $p -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $godotPath = $found.FullName
                    break
                }
            }
        }
    }

    if ($godotPath) {
        Add-EnvLog "  Godot found at: $godotPath (via deep scan)"
        Check-Warn "Godot found" "(not in PATH: $godotPath)" "Add Godot to PATH for easier access"
    } else {
        Add-EnvLog "  Godot NOT found anywhere"
        Check-Fail "Godot found" "(not installed)" "Download from https://godotengine.org/download/"
    }
}

# Version check
if ($godotPath) {
    if (-not $godotVersionRaw) {
        try {
            $godotVersionRaw = (cmd /c "`"$godotPath`" --version 2>&1" | Out-String).Trim()
        } catch { }
    }

    if ($godotVersionRaw) {
        Add-EnvLog "  Godot version raw: $godotVersionRaw"

        # Parse version (formats: "4.3.stable", "4.6.dev", "Godot_v4.3-stable-win64 4.3.stable")
        $godotVer = $null
        if ($godotVersionRaw -match '(\d+)\.(\d+)(?:\.(\d+))?') {
            $gMajor = [int]$Matches[1]
            $gMinor = [int]$Matches[2]
            $gPatch = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
            $godotVer = [version]"$gMajor.$gMinor.$gPatch"
            $minGodot = [version]$MIN_GODOT_VERSION

            Add-EnvLog "  Parsed Godot version: $gMajor.$gMinor.$gPatch"

            if ($godotVer -ge $minGodot) {
                Check-Pass "Godot version" "($gMajor.$gMinor.$gPatch >= $MIN_GODOT_VERSION)"
            } else {
                Check-Fail "Godot version" "($gMajor.$gMinor.$gPatch < $MIN_GODOT_VERSION)" "Download Godot 4.x from https://godotengine.org/download/"
            }
        } else {
            Check-Warn "Godot version parse" "(raw: '$godotVersionRaw')" "Verify version manually"
        }
    } else {
        # Try to extract version from filename
        if ($godotPath -match 'v?(\d+)\.(\d+)') {
            $gMajor = [int]$Matches[1]
            $gMinor = [int]$Matches[2]
            $minGodot = [version]$MIN_GODOT_VERSION
            $gVerObj = [version]"$gMajor.$gMinor.0"

            Add-EnvLog "  Parsed Godot version from filename: $gMajor.$gMinor"

            if ($gVerObj -ge $minGodot) {
                Check-Pass "Godot version (from filename)" "($gMajor.$gMinor >= $MIN_GODOT_VERSION)"
            } else {
                Check-Fail "Godot version (from filename)" "($gMajor.$gMinor < $MIN_GODOT_VERSION)" "Download Godot 4.x"
            }
        } else {
            Check-Warn "Godot version" "(could not determine)" "Run manually: godot --version"
        }
    }
}

Write-Host ""

# ============================================================
# 5. Project file checks
# ============================================================
Write-Host "[5/7] Project Files" -ForegroundColor Cyan
Add-EnvLog "Section 5: Project Files"
Add-EnvLog "  Project root: $projectRoot"

# project.godot
$projectGodot = Join-Path $projectRoot "project.godot"
if (Test-Path $projectGodot) {
    Check-Pass "project.godot" "(found)"
    Add-EnvLog "  project.godot: found"

    # Check Godot version in project file
    $projContent = Get-Content $projectGodot -Raw
    if ($projContent -match 'config/features=PackedStringArray\("(\d+\.\d+)"') {
        $projGodotVer = $Matches[1]
        Add-EnvLog "  Project Godot version: $projGodotVer"
        Check-Pass "Project Godot version" "($projGodotVer)"

        # Warn if installed Godot is older than project version
        if ($godotVer -and $projGodotVer) {
            $projVerObj = [version]($projGodotVer + ".0")
            if ($godotVer -lt $projVerObj) {
                Check-Warn "Godot vs Project" "(installed $godotVer < project $projGodotVer)" "Update Godot to $projGodotVer or later"
            }
        }
    } else {
        Check-Warn "Project Godot version" "(not found in project.godot)" "Check project.godot manually"
    }
} else {
    Check-Fail "project.godot" "(not found at $projectGodot)" "Clone the project: git clone $REPO_URL"
}

# scripts/ directory
$scriptsDir = Join-Path $projectRoot "scripts"
if (Test-Path $scriptsDir) {
    $scriptCount = (Get-ChildItem -Path $scriptsDir -Filter "*.gd" -Recurse -ErrorAction SilentlyContinue).Count
    Check-Pass "scripts/ directory" "($scriptCount .gd files)"
    Add-EnvLog "  scripts/: $scriptCount .gd files"
} else {
    Check-Fail "scripts/ directory" "(not found)" "Clone the project"
}

# test/ directory
$testDir = Join-Path $projectRoot "test"
if (Test-Path $testDir) {
    $testCount = (Get-ChildItem -Path $testDir -Filter "*.gd" -Recurse -ErrorAction SilentlyContinue).Count
    Check-Pass "test/ directory" "($testCount test files)"
    Add-EnvLog "  test/: $testCount .gd files"
} else {
    Check-Warn "test/ directory" "(not found)" "Clone the project"
}

# tools/ directory
$toolsDir = Join-Path $projectRoot "tools"
if (Test-Path $toolsDir) {
    $toolCount = (Get-ChildItem -Path $toolsDir -ErrorAction SilentlyContinue).Count
    Check-Pass "tools/ directory" "($toolCount files)"
    Add-EnvLog "  tools/: $toolCount files"
} else {
    Check-Warn "tools/ directory" "(not found)" "Clone the project"
}

Write-Host ""

# ============================================================
# 6. Git repository checks
# ============================================================
Write-Host "[6/7] Git Repository" -ForegroundColor Cyan
Add-EnvLog "Section 6: Git Repository"

if ($gitCmd -and (Test-Path (Join-Path $projectRoot ".git"))) {
    $gitDir = Join-Path $projectRoot ".git"

    # Check if it's a git repo
    Check-Pass "Git repository" "(.git directory found)"
    Add-EnvLog "  .git/: found"

    # Check remote
    try {
        $remoteUrl = (cmd /c "`"$($gitCmd.Source)`" -C `"$projectRoot`" remote get-url origin 2>nul" 2>&1 | Out-String).Trim()
        if ($remoteUrl -and $remoteUrl -notmatch 'error|fatal') {
            Check-Pass "Git remote origin" "($remoteUrl)"
            Add-EnvLog "  remote origin: $remoteUrl"
        } else {
            Check-Warn "Git remote origin" "(not set)" "Run: git remote add origin $REPO_URL"
        }
    } catch {
        Check-Warn "Git remote origin" "(check failed)"
    }

    # Check branch
    try {
        $currentBranch = (cmd /c "`"$($gitCmd.Source)`" -C `"$projectRoot`" rev-parse --abbrev-ref HEAD 2>nul" 2>&1 | Out-String).Trim()
        if ($currentBranch -and $currentBranch -notmatch 'error|fatal') {
            Check-Pass "Current branch" "($currentBranch)"
            Add-EnvLog "  branch: $currentBranch"
        } else {
            Check-Warn "Current branch" "(could not determine)"
        }
    } catch {
        Check-Warn "Current branch" "(check failed)"
    }

    # Check for uncommitted changes
    try {
        $statusOutput = cmd /c "`"$($gitCmd.Source)`" -C `"$projectRoot`" status --porcelain 2>nul" 2>&1
        $uncommitted = ($statusOutput | Measure-Object).Count
        if ($uncommitted -eq 0) {
            Check-Pass "Working tree" "(clean, no uncommitted changes)"
            Add-EnvLog "  working tree: clean"
        } else {
            Check-Warn "Working tree" "($uncommitted uncommitted changes)" "Run: git status to review"
            Add-EnvLog "  working tree: $uncommitted changes"
        }
    } catch {
        Check-Warn "Working tree" "(status check failed)"
    }
} elseif ($gitCmd -and -not (Test-Path (Join-Path $projectRoot ".git"))) {
    Check-Warn "Git repository" "(no .git directory, not a repo)" "Run: git init or git clone $REPO_URL"
    Add-EnvLog "  .git/: not found"
} elseif (-not $gitCmd) {
    Check-Fail "Git repository" "(Git not installed)"
}

# .gitignore check
$gitignorePath = Join-Path $projectRoot ".gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    $hasGodotIgnore = $gitignoreContent -match '\.godot/'
    $hasTempIgnore = $gitignoreContent -match 'tmp_|_tmp'
    if ($hasGodotIgnore) {
        Check-Pass ".gitignore" "(includes .godot/ rule)"
    } else {
        Check-Warn ".gitignore" "(missing .godot/ rule)" "Add '.godot/' to .gitignore"
    }
} else {
    Check-Warn ".gitignore" "(not found)" "Create a .gitignore file"
}

Write-Host ""

# ============================================================
# 7. Network connectivity
# ============================================================
Write-Host "[7/7] Network Connectivity" -ForegroundColor Cyan
Add-EnvLog "Section 7: Network Connectivity"

# GitHub connectivity (quick check, 3 second timeout)
Add-EnvLog "  Testing GitHub connectivity (3s timeout)..."
$githubOk = $false
try {
    $testResult = Test-NetConnection -ComputerName "github.com" -Port 443 -WarningAction SilentlyContinue
    if ($testResult.TcpTestSucceeded) {
        $githubOk = $true
    }
} catch {
    # Fallback: try a simple HTTP request
    try {
        $null = [System.Net.WebRequest]::Create("https://github.com")
        $githubOk = $true
    } catch {
        $githubOk = $false
    }
}

if ($githubOk) {
    Check-Pass "GitHub connectivity" "(port 443 reachable)"
    Add-EnvLog "  GitHub: reachable"
} else {
    Check-Warn "GitHub connectivity" "(port 443 not reachable)" "Check network/proxy settings. See docs/GitInstallGuide.md"
    Add-EnvLog "  GitHub: NOT reachable"
}

# Proxy check
$httpProxy = $env:HTTP_PROXY
$httpsProxy = $env:HTTPS_PROXY
if ($httpProxy -or $httpsProxy) {
    Add-EnvLog "  HTTP_PROXY: $httpProxy"
    Add-EnvLog "  HTTPS_PROXY: $httpsProxy"
    Check-Warn "Proxy detected" "(HTTP_PROXY=$httpProxy, HTTPS_PROXY=$httpsProxy)" "Ensure proxy allows GitHub traffic"
} else {
    Add-EnvLog "  No proxy environment variables set"
    Check-Pass "Proxy" "(none configured)"
}

Write-Host ""

# ============================================================
# Write log file
# ============================================================
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Add-EnvLog ""
Add-EnvLog "=== Summary ==="
Add-EnvLog "  Total checks: $totalChecks"
Add-EnvLog "  Passed: $checksPassed"
Add-EnvLog "  Warnings: $checksWarn"
Add-EnvLog "  Failed: $checksFailed"
Add-EnvLog "  Duration: $([math]::Round($duration, 2))s"
Add-EnvLog "=== Check Complete ==="

try {
    $envLog | Out-File -FilePath $logFile -Encoding UTF8 -Force
    Add-EnvLog "Log file written: $logFile"
} catch {
    Write-Host "  [WARNING] Could not write log file: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ============================================================
# Summary report
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Environment Check Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passColor = if ($checksPassed -gt 0) { "Green" } else { "Gray" }
$warnColor = if ($checksWarn -gt 0) { "Yellow" } else { "Gray" }
$failColor = if ($checksFailed -gt 0) { "Red" } else { "Gray" }

Write-Host "  Total:   $totalChecks" -ForegroundColor Gray
Write-Host "  Passed:  $checksPassed" -ForegroundColor $passColor
Write-Host "  Warnings: $checksWarn" -ForegroundColor $warnColor
Write-Host "  Failed:  $checksFailed" -ForegroundColor $failColor
Write-Host "  Time:    $([math]::Round($duration, 2))s" -ForegroundColor Gray
Write-Host ""

if ($checksFailed -eq 0 -and $checksWarn -eq 0) {
    Write-Host "  ALL CHECKS PASSED - Environment is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "    1. Open Godot, import project.godot"
    Write-Host "    2. Click Run to start the game"
    Write-Host "    3. For tests, open scenes in test/ directory"
} elseif ($checksFailed -eq 0) {
    Write-Host "  PASSED with warnings - Environment is functional." -ForegroundColor Yellow
    Write-Host "  Address warnings above for optimal experience." -ForegroundColor Yellow
} else {
    Write-Host "  SOME CHECKS FAILED - Fix the [FAIL] items above." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Quick fixes:" -ForegroundColor Cyan

    if (-not $gitCmd) {
        Write-Host "    Git:   winget install Git.Git" -ForegroundColor White
    }
    if ($gitCmd -and -not $gitUserName) {
        Write-Host "    Config: git config --global user.name 'Your Name'" -ForegroundColor White
        Write-Host "            git config --global user.email 'you@example.com'" -ForegroundColor White
    }
    if (-not $godotPath) {
        Write-Host "    Godot: Download from https://godotengine.org/download/" -ForegroundColor White
    }
    if (-not (Test-Path $projectGodot)) {
        Write-Host "    Clone: git clone $REPO_URL" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "  Log file: $logFile" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# Exit code
if ($checksFailed -gt 0) { exit 1 } else { exit 0 }
