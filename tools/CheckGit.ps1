#requires -Version 5.0
<#
.SYNOPSIS
    三界模拟器 - Git + Godot 环境一键检查与项目拉取脚本
.DESCRIPTION
    自动检查 Git 和 Godot 安装状态，处理执行策略，支持 winget/choco/手动安装，
    并可一键克隆项目到本地，克隆后可直接用 Godot 打开。
.USAGE
    配合 启动器.bat 双击运行，或：
    powershell -ExecutionPolicy Bypass -File CheckGit.ps1
#>

# ============================================================
# 0. 处理执行策略与权限问题
# ============================================================

# 检测当前执行策略
$currentPolicy = (Get-ExecutionPolicy -List).CurrentUser
$policyBypassed = $false

if ($currentPolicy -ne 'Bypass' -and $currentPolicy -ne 'Unrestricted') {
    Write-Host "[权限] 当前执行策略: $currentPolicy" -ForegroundColor Yellow
    Write-Host "[权限] 尝试为当前用户设置 Bypass 策略（仅影响当前用户）..." -ForegroundColor Yellow

    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force -ErrorAction Stop
        $policyBypassed = $true
        Write-Host "[权限] 执行策略已设置为 Bypass" -ForegroundColor Green
    } catch {
        Write-Host "[权限] 无法自动修改执行策略：$($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[权限] 本脚本继续运行，但其他脚本可能受限" -ForegroundColor Yellow
        Write-Host "[权限] 建议以管理员身份打开 PowerShell 执行：" -ForegroundColor Yellow
        Write-Host "        Set-ExecutionPolicy -Scope CurrentUser Bypass" -ForegroundColor White
    }
}

# 管理员权限检测
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "[提示] 当前非管理员权限，winget/choco 安装可能失败" -ForegroundColor Magenta
    Write-Host "        若安装失败，请右键 PowerShell → 以管理员身份运行" -ForegroundColor Magenta
}

Write-Host ""

# ============================================================
# 1. 检查 Git 是否已安装
# ============================================================
Write-Host "[1/5] 检查 Git 安装状态..." -ForegroundColor Cyan

# Git logging infrastructure
$gitLog = @()
$gitLogFile = Join-Path $env:TEMP "git_detection_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Add-GitLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $entry = "[$timestamp] $Message"
    $script:gitLog += $entry
    Write-Host "  [LOG] $Message" -ForegroundColor DarkGray
}

Add-GitLog "=== Git Detection Started ==="
Add-GitLog "OS: $([System.Environment]::OSVersion.VersionString)"
Add-GitLog "PowerShell: $($PSVersionTable.PSVersion)"
Add-GitLog "PATH length: $($env:PATH.Length) chars"

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
$gitInstalled = $false
$gitVersion = $null
$gitPath = $null
$gitDetectionFailedReason = @()

# --- Step 1: Check via Get-Command ---
Add-GitLog "Step 1: Get-Command 'git' lookup..."
if ($gitCmd) {
    Add-GitLog "  Found 'git' via Get-Command at: $($gitCmd.Source)"
} else {
    Add-GitLog "  'git' not found in command cache"
    $gitDetectionFailedReason += "Get-Command 未找到 git 命令"
}

# --- Step 2: Verify Git actually works ---
if ($gitCmd) {
    $gitPath = $gitCmd.Source
    $gitInstalled = $true

    try {
        $gitVersionLine = & git --version 2>&1
        $gitVersion = $gitVersionLine.ToString().Trim()

        Write-Host "[OK] Git 已安装" -ForegroundColor Green
        Write-Host "     版本: $gitVersion" -ForegroundColor White
        Write-Host "     路径: $gitPath" -ForegroundColor White
        Add-GitLog "  Version: $gitVersion"
        Add-GitLog "  Path: $gitPath"

        # Verify git can actually run
        try {
            $null = & git rev-parse --is-inside-work-tree 2>&1
            Write-Host "     状态: 命令可正常执行" -ForegroundColor White
            Add-GitLog "  Status: git command works correctly"
        } catch {
            Write-Host "     [警告] git 命令存在但执行异常: $($_.Exception.Message)" -ForegroundColor Yellow
            Add-GitLog "  WARNING: git command exists but execution failed: $($_.Exception.Message)"
        }
    } catch {
        Write-Host "[OK] Git 已安装" -ForegroundColor Green
        Write-Host "     版本: 无法获取（$($_.Exception.Message)）" -ForegroundColor Yellow
        Write-Host "     路径: $gitPath" -ForegroundColor White
        Add-GitLog "  WARNING: Version query failed: $($_.Exception.Message)"
        Add-GitLog "  Path: $gitPath"
        $gitVersion = "unknown"
    }
}

# --- Step 3: If not found via PATH, scan common installation paths ---
if (-not $gitInstalled) {
    Write-Host "[X] 未检测到 git 命令" -ForegroundColor Red
    Add-GitLog "Step 2: Deep scan for Git installation paths..."

    $gitSearchPaths = @(
        "${env:ProgramFiles}\Git\cmd\git.exe",
        "${env:ProgramFiles}\Git\bin\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\bin\git.exe",
        "${env:LOCALAPPDATA}\Programs\Git\cmd\git.exe",
        "${env:LOCALAPPDATA}\Programs\Git\bin\git.exe",
        "${env:USERPROFILE}\scoop\shims\git.exe",
        "${env:USERPROFILE}\scoop\apps\git\current\cmd\git.exe",
        "${env:ChocolateyInstall}\bin\git.exe",
        "${env:ChocolateyInstall}\lib\git\tools\cmd\git.exe"
    )

    $foundGit = $null
    $presetFound = 0
    foreach ($p in $gitSearchPaths) {
        if (Test-Path $p) {
            Add-GitLog "  [EXISTS] $p"
            $presetFound++
            if (-not $foundGit) { $foundGit = $p }
        } else {
            Add-GitLog "  [NOT FOUND] $p"
        }
    }

    # Also search registry for Git install location
    Add-GitLog "Step 3: Check Windows Registry for Git installation..."
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $regGitFound = $null
    foreach ($regPath in $regPaths) {
        try {
            $items = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Git*" }
            if ($items) {
                foreach ($item in ($items | Select-Object -First 3)) {
                    Add-GitLog "  Registry found: $($item.DisplayName) at $($item.InstallLocation)"
                    if (-not $regGitFound -and $item.InstallLocation) {
                        $candidate = Join-Path $item.InstallLocation "cmd\git.exe"
                        if (Test-Path $candidate) {
                            $regGitFound = $candidate
                            Add-GitLog "  Registry confirmed git at: $regGitFound"
                        }
                    }
                }
            }
        } catch {
            Add-GitLog "  Registry scan error: $($_.Exception.Message)"
        }
    }

    # Prioritize registry found or preset found
    if ($regGitFound) { $foundGit = $regGit }
    if ($presetFound -eq 0 -and -not $regGitFound) {
        $gitDetectionFailedReason += "$($gitSearchPaths.Count) 个预设路径和注册表中均未找到 Git"
    }

    # --- Step 4: Also search PATH directories for git.exe ---
    Add-GitLog "Step 4: PATH directory scan for git.exe..."
    $pathDirs = $env:PATH -split ';'
    $pathHit = $false
    $dirsChecked = 0
    foreach ($dir in $pathDirs) {
        if ($dir -and (Test-Path $dir)) {
            $dirsChecked++
            try {
                $found = Get-ChildItem -Path $dir -Filter "git.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    Add-GitLog "  FOUND in PATH dir '$dir': $($found.FullName)"
                    if (-not $foundGit) { $foundGit = $found.FullName }
                    $pathHit = $true
                }
            } catch {
                Add-GitLog "  Error scanning '$dir': $($_.Exception.Message)"
            }
        }
    }
    Add-GitLog "  Scanned $dirsChecked PATH directories for git.exe"
    if (-not $pathHit -and -not $foundGit) {
        $gitDetectionFailedReason += "PATH 目录扫描 ($dirsChecked 个目录) 未找到 git.exe"
    }

    # --- Step 5: Try to fix PATH ---
    if ($foundGit) {
        Write-Host "[发现] Git 已安装但未加入 PATH: $foundGit" -ForegroundColor Yellow
        Add-GitLog "RESULT: Git found via deep scan at $foundGit but not in PATH"
        Write-Host "[修复] 正在将 Git 添加到当前会话的 PATH..." -ForegroundColor Yellow
        $gitDir = Split-Path (Split-Path $foundGit)
        $env:PATH = "$gitDir;$env:PATH"
        Add-GitLog "  Added $gitDir to session PATH"

        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd) {
            try {
                $gitVersion = (& git --version 2>&1).ToString().Trim()
            } catch {
                $gitVersion = "unknown"
            }
            $gitPath = $foundGit
            $gitInstalled = $true
            Write-Host "[OK] 已修复，Git 现在可用了" -ForegroundColor Green
            Write-Host "     版本: $gitVersion" -ForegroundColor White
            Write-Host "     路径: $gitPath" -ForegroundColor White
            Write-Host "     注意: 请重启终端后再次使用，或永久添加到系统 PATH" -ForegroundColor Magenta
            Add-GitLog "RESULT: Git INSTALLED after PATH fix - version=$gitVersion"
        } else {
            Write-Host "[X] 修复失败，请手动重启终端" -ForegroundColor Red
            Add-GitLog "  Failed to make git available after PATH fix"
        }
    }
}

# ============================================================
# 2. 未安装则引导安装
# ============================================================
if (-not $gitInstalled) {
    Write-Host ""
    Write-Host "[2/5] Git 未安装，请选择安装方式：" -ForegroundColor Cyan

    # --- Diagnostics ---
    Write-Host ""
    Write-Host "  --- 诊断信息 ---" -ForegroundColor Yellow
    Add-GitLog "RESULT: Git NOT FOUND anywhere"
    Add-GitLog "Failure reasons:"
    foreach ($reason in $gitDetectionFailedReason) {
        Write-Host "    - $reason" -ForegroundColor Red
        Add-GitLog "  REASON: $reason"
    }

    # PATH diagnostics
    $pathDirCount = ($env:PATH -split ';').Count
    $validPathDirs = 0
    foreach ($d in ($env:PATH -split ';')) {
        if ($d -and (Test-Path $d)) { $validPathDirs++ }
    }
    $pathDiagnostic = "PATH: $pathDirCount entries total, $validPathDirs valid directories"
    Write-Host "    $pathDiagnostic" -ForegroundColor Gray
    Add-GitLog "  PATH DIAGNOSTIC: $pathDiagnostic"

    # Check if any Git-related files exist on the system
    $allDrives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue
    Write-Host "    扫描驱动器: $($allDrives.Root -join ', ')" -ForegroundColor Gray
    Add-GitLog "  Drives: $($allDrives.Root -join ', ')"

    # Log Program Files Git-related dirs
    $pfGitDirs = Get-ChildItem -Path "${env:ProgramFiles}" -Filter "Git*" -Directory -ErrorAction SilentlyContinue
    if ($pfGitDirs) {
        Write-Host "    [NOTE] 发现 Git 相关目录：" -ForegroundColor Yellow
        foreach ($d in $pfGitDirs) {
            Write-Host "      $($d.FullName)" -ForegroundColor Yellow
            Add-GitLog "  NOTE: Git dir in Program Files: $($d.FullName)"
        }
    }

    # Log AppData Git-related dirs
    $appDataGitDirs = Get-ChildItem -Path "${env:LOCALAPPDATA}\Programs" -Filter "Git*" -Directory -ErrorAction SilentlyContinue
    if ($appDataGitDirs) {
        Write-Host "    [NOTE] 发现 Git 相关目录：" -ForegroundColor Yellow
        foreach ($d in $appDataGitDirs) {
            Write-Host "      $($d.FullName)" -ForegroundColor Yellow
            Add-GitLog "  NOTE: Git dir in LocalAppData: $($d.FullName)"
        }
    }

    Write-Host ""
    Write-Host "  --- 安装方式 ---" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] winget 一键安装 (Windows 10/11 自带，推荐)" -ForegroundColor White
    Write-Host "  [2] 官网下载安装包 (最可靠，双击安装)" -ForegroundColor White
    Write-Host "  [3] chocolatey 安装 (需先装 choco)" -ForegroundColor White
    Write-Host "  [4] 手动安装详细步骤" -ForegroundColor White
    Write-Host "  [Q] 退出" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "请输入选项"

    switch ($choice) {
        '1' {
            Write-Host ""
            Write-Host "[安装] 正在通过 winget 安装 Git..." -ForegroundColor Yellow
            # 尝试 winget
            $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
            if (-not $wingetCmd) {
                Write-Host "[X] winget 不可用" -ForegroundColor Red
                Write-Host "    Windows 10 1709+ 或 Windows 11 自带 winget" -ForegroundColor White
                Write-Host "    请改用方式 [2] 或更新 App Installer：" -ForegroundColor White
                Write-Host "    https://apps.microsoft.com/detail/9nblggh4nns1" -ForegroundColor Yellow
                return
            }
            try {
                winget install Git.Git --accept-source-agreements --accept-package-agreements --silent
                Write-Host ""
                Write-Host "[完成] Git 安装完成！" -ForegroundColor Green
                Write-Host "请关闭此窗口，重新打开 启动器.bat 来验证和克隆项目" -ForegroundColor Yellow
            } catch {
                Write-Host "[错误] winget 安装失败: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "        请改用方式 [2] 官网下载" -ForegroundColor Yellow
            }
            return
        }
        '2' {
            Write-Host ""
            Start-Process "https://git-scm.com/download/win"
            Write-Host "[安装] 已打开 Git 官网下载页" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "步骤：" -ForegroundColor Cyan
            Write-Host "  1. 下载完成后双击 .exe 安装包" -ForegroundColor White
            Write-Host "  2. 一路 Next 使用默认设置" -ForegroundColor White
            Write-Host "  3. 安装完成后重新打开 启动器.bat" -ForegroundColor White
            return
        }
        '3' {
            Write-Host ""
            Write-Host "[安装] 正在通过 chocolatey 安装 Git..." -ForegroundColor Yellow
            try {
                choco install git -y -f
                Write-Host "[完成] Git 安装完成！请重新打开 启动器.bat" -ForegroundColor Green
            } catch {
                Write-Host "[X] chocolatey 不可用" -ForegroundColor Red
                Write-Host "    请改用方式 [2]，或先安装 choco：" -ForegroundColor Yellow
                Write-Host "    Set-ExecutionPolicy Bypass -Scope Process; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Yellow
            }
            return
        }
        '4' {
            Write-Host ""
            Write-Host "========== 手动安装详细步骤 ==========" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "1. 浏览器访问: https://git-scm.com/download/win" -ForegroundColor Yellow
            Write-Host "   页面自动开始下载，若未下载请手动点击 Windows 图标" -ForegroundColor Gray
            Write-Host ""
            Write-Host "2. 双击下载的 .exe 安装包" -ForegroundColor White
            Write-Host ""
            Write-Host "3. 安装向导: 一路 Next，默认设置即可" -ForegroundColor White
            Write-Host "   - 建议勾选: Add Git to the PATH" -ForegroundColor Yellow
            Write-Host "   - 建议勾选: Windows Terminal profile" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "4. 安装完成后，重新打开 启动器.bat 继续" -ForegroundColor White
            return
        }
        'Q' { return }
        default {
            Write-Host "[无效输入] 请输入 1-4 或 Q" -ForegroundColor Red
            return
        }
    }
}

# Write git detection log file (single write after all Git detection logic)
try {
    $gitLog | Out-File -FilePath $gitLogFile -Encoding UTF8 -Force
    $logNote = if ($gitInstalled) { "Git 已安装" } else { "Git 未安装" }
    Write-Host "  [日志] Git 检测日志已保存: $gitLogFile ($logNote)" -ForegroundColor Magenta
} catch {
    Write-Host "  [警告] 无法写入日志文件: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ============================================================
# 2.5 Git version requirement check
# ============================================================
if ($gitInstalled -and $gitVersion -and $gitVersion -ne "unknown") {
    Write-Host ""
    Add-GitLog "Step 5: Git version requirement check..."
    Add-GitLog "  Input version string: '$gitVersion'"
    Add-GitLog "  Input string length: $($gitVersion.Length) chars"

    # Minimum required Git version
    $minGitVersionStr = "2.0.0"
    Write-Host "[版本] 检查 Git 版本要求（最低 $minGitVersionStr）..." -ForegroundColor Cyan
    Add-GitLog "  Minimum required version: $minGitVersionStr"

    # Parse version from string like "git version 2.47.1.windows.1"
    # Log the regex match attempt in detail
    Add-GitLog "  Attempting regex match: 'version\s+(\d+)\.(\d+)\.(\d+)'"
    Add-GitLog "  Full version string: $gitVersion"
    Add-GitLog "  Regex target: looking for 'version' keyword followed by 3 number groups"

    if ($gitVersion -match 'version\s+(\d+)\.(\d+)\.(\d+)') {
        $verMajor = [int]$Matches[1]
        $verMinor = [int]$Matches[2]
        $verPatch = [int]$Matches[3]
        $verParsed = [version]"$verMajor.$verMinor.$verPatch"

        $minVerParsed = [version]$minGitVersionStr

        Add-GitLog "  Regex MATCHED!"
        Add-GitLog "    Group[1] (major): '$($Matches[1])' -> int=$verMajor"
        Add-GitLog "    Group[2] (minor): '$($Matches[2])' -> int=$verMinor"
        Add-GitLog "    Group[3] (patch): '$($Matches[3])' -> int=$verPatch"
        Add-GitLog "    Parsed version object: $verParsed (type: $($verParsed.GetType().Name))"
        Add-GitLog "    Min version object: $minVerParsed (type: $($minVerParsed.GetType().Name))"

        # Perform comparison with detailed logging
        Add-GitLog "  Performing version comparison: $verParsed -ge $minVerParsed"

        # Break down the comparison
        $majorCompare = $verMajor -ge [int]($minVerParsed.Major)
        $minorCompare = $verMinor -ge [int]($minVerParsed.Minor)
        $patchCompare = $verPatch -ge [int]($minVerParsed.Build)

        Add-GitLog "    Major compare: $verMajor >= $($minVerParsed.Major) => $majorCompare"
        if (-not $majorCompare) {
            Add-GitLog "      => FAIL: major version too low"
        } elseif ($verMajor -eq [int]($minVerParsed.Major)) {
            Add-GitLog "      => Major equal, checking minor..."
            Add-GitLog "    Minor compare: $verMinor >= $($minVerParsed.Minor) => $minorCompare"
            if (-not $minorCompare) {
                Add-GitLog "      => FAIL: minor version too low (major is equal)"
            } elseif ($verMinor -eq [int]($minVerParsed.Minor)) {
                Add-GitLog "      => Minor equal, checking patch..."
                Add-GitLog "    Patch compare: $verPatch >= $($minVerParsed.Build) => $patchCompare"
                if (-not $patchCompare) {
                    Add-GitLog "      => FAIL: patch version too low (major.minor equal)"
                } else {
                    Add-GitLog "      => All parts equal or greater"
                }
            }
        }

        $versionOk = $verParsed -ge $minVerParsed

        Add-GitLog "  Final version OK (=$verParsed -ge $minVerParsed): $versionOk"
        Add-GitLog "  Comparison details: [$verMajor.$verMinor.$verPatch] vs [$($minVerParsed.Major).$($minVerParsed.Minor).$($minVerParsed.Build)]"

        # Also test with both -ge and -gt to document the boundary
        $isBoundary = ($verMajor -eq [int]($minVerParsed.Major) -and
                       $verMinor -eq [int]($minVerParsed.Minor) -and
                       $verPatch -eq [int]($minVerParsed.Build))
        if ($isBoundary) {
            Add-GitLog "  **BOUNDARY DETECTED**: Version exactly equals minimum ($verMajor.$verMinor.$verPatch == $minGitVersionStr)"
            Add-GitLog "     -ge operator returns: $versionOk (as expected, >= includes equal)"
            Add-GitLog "     -gt operator would return: $($verParsed -gt $minVerParsed) (correctly false for boundary)"
        }

        if ($versionOk) {
            Write-Host "[OK] Git 版本满足要求: $verMajor.$verMinor.$verPatch >= $minGitVersionStr" -ForegroundColor Green
            Add-GitLog "RESULT: Git version check PASSED"
            Add-GitLog "  User-facing message: '[OK] Git $verMajor.$verMinor.$verPatch meets requirement'"
        } else {
            Write-Host "[警告] Git 版本过低: $verMajor.$verMinor.$verPatch < $minGitVersionStr" -ForegroundColor Yellow
            Write-Host "       建议升级到 Git 2.0 或更高版本" -ForegroundColor Yellow
            Add-GitLog "RESULT: Git version check FAILED - too old"
            Add-GitLog "  User-facing message: '[WARNING] Git version too old: $verMajor.$verMinor.$verPatch < $minGitVersionStr'"
            Add-GitLog "  Upgrade guidance will be offered"

            $upgradeNow = Read-Host "       是否现在升级 Git? (Y/N，留空=跳过)"
            $upgradeDecision = if ($upgradeNow) { $upgradeNow } else { "empty (skip)" }
            Add-GitLog "  Upgrade decision: $upgradeDecision"

            if ($upgradeNow -eq 'Y' -or $upgradeNow -eq 'y') {
                Write-Host ""
                Write-Host "  [1] winget upgrade Git.Git" -ForegroundColor White
                Write-Host "  [2] 官网下载最新版: https://git-scm.com/download/win" -ForegroundColor White
                Write-Host "  [3] chocolatey upgrade git" -ForegroundColor White
                Write-Host "  [Q] 稍后再升" -ForegroundColor White
                Write-Host ""
                $upgradeChoice = Read-Host "  请选择"
                Add-GitLog "  Upgrade method chosen: $upgradeChoice"

                switch ($upgradeChoice) {
                    '1' {
                        Add-GitLog "  Method 1: winget upgrade Git.Git"
                        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
                        if ($wingetCmd) {
                            Add-GitLog "    winget found at: $($wingetCmd.Source)"
                            try {
                                winget upgrade Git.Git --accept-source-agreements --accept-package-agreements 2>&1 | ForEach-Object { Add-GitLog "      winget output: $_" }
                                Write-Host "[完成] Git 升级完成！请重启终端" -ForegroundColor Green
                                Add-GitLog "    RESULT: winget upgrade completed"
                            } catch {
                                Write-Host "[X] 升级失败，请改用方式 [2]" -ForegroundColor Red
                                Add-GitLog "    ERROR: winget upgrade failed: $($_.Exception.Message)"
                            }
                        } else {
                            Write-Host "[X] winget 不可用，请改用方式 [2]" -ForegroundColor Red
                            Add-GitLog "    ERROR: winget not found on system"
                        }
                    }
                    '2' {
                        Add-GitLog "  Method 2: Opening Git download page in browser"
                        Start-Process "https://git-scm.com/download/win"
                        Write-Host "[下载] 已打开 Git 下载页，请下载安装最新版" -ForegroundColor Green
                        Add-GitLog "    RESULT: Browser opened to git-scm.com/download/win"
                    }
                    '3' {
                        Add-GitLog "  Method 3: chocolatey upgrade git"
                        try {
                            choco upgrade git -y 2>&1 | ForEach-Object { Add-GitLog "      choco output: $_" }
                            Write-Host "[完成] Git 升级完成！请重启终端" -ForegroundColor Green
                            Add-GitLog "    RESULT: choco upgrade completed"
                        } catch {
                            Write-Host "[X] chocolatey 不可用，请改用方式 [2]" -ForegroundColor Red
                            Add-GitLog "    ERROR: choco upgrade failed: $($_.Exception.Message)"
                        }
                    }
                    default {
                        Add-GitLog "  Method: skipped (user chose not to upgrade now)"
                        Write-Host "  已跳过升级。请从 https://git-scm.com/download 下载最新版" -ForegroundColor Gray
                    }
                }
            } else {
                Add-GitLog "  Upgrade skipped by user"
            }
        }
    } else {
        Write-Host "[警告] 无法解析 Git 版本号: $gitVersion" -ForegroundColor Yellow
        Write-Host "       建议手动确认版本是否 >= $minGitVersionStr" -ForegroundColor Yellow
        Add-GitLog "RESULT: Git version parse FAILED - format not recognized"
        Add-GitLog "  Input value: '$gitVersion'"
        Add-GitLog "  Input type: $($gitVersion.GetType().Name)"
        Add-GitLog "  Input length: $($gitVersion.Length)"
        Add-GitLog "  Regex tried: 'version\s+(\d+)\.(\d+)\.(\d+)'"
        Add-GitLog "  Suggestion: Check if git --version output format changed"
        Add-GitLog "  Suggested action: Visit https://git-scm.com/download to check latest version"
    }
} elseif (-not $gitInstalled) {
    Add-GitLog "Step 5: Git version check SKIPPED (Git not installed)"
} elseif ($gitVersion -eq "unknown") {
    Add-GitLog "Step 5: Git version check SKIPPED (version unknown)"
} elseif (-not $gitVersion) {
    Add-GitLog "Step 5: Git version check SKIPPED (version string is empty/null)"
} else {
    Add-GitLog "Step 5: Git version check SKIPPED (gitInstalled=$gitInstalled, gitVersion='$gitVersion')"
}

# ============================================================
# 3. 检查 Godot 安装状态
# ============================================================
Write-Host "[2/5] 检查 Godot 安装状态..." -ForegroundColor Cyan

# Logging infrastructure
$godotLog = @()
$godotLogFile = Join-Path $env:TEMP "godot_detection_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Add-GodotLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $entry = "[$timestamp] $Message"
    $script:godotLog += $entry
    Write-Host "  [LOG] $Message" -ForegroundColor DarkGray
}

Add-GodotLog "=== Godot Detection Started ==="
Add-GodotLog "OS: $([System.Environment]::OSVersion.VersionString)"
Add-GodotLog "PowerShell: $($PSVersionTable.PSVersion)"
Add-GodotLog "PATH length: $($env:PATH.Length) chars"

$godotInstalled = $false
$godotPath = $null
$godotVersion = $null
$detectionFailedReason = @()

# --- Step 1: Check via Get-Command (exact names) ---
Add-GodotLog "Step 1: Get-Command exact name lookup..."
$godotCmd = Get-Command godot -ErrorAction SilentlyContinue
if ($godotCmd) {
    Add-GodotLog "  Found 'godot' at: $($godotCmd.Source)"
} else {
    Add-GodotLog "  'godot' not found in command cache"
}

if (-not $godotCmd) {
    $godotCmd = Get-Command godot4 -ErrorAction SilentlyContinue
    if ($godotCmd) {
        Add-GodotLog "  Found 'godot4' at: $($godotCmd.Source)"
    } else {
        Add-GodotLog "  'godot4' not found in command cache"
    }
}

if (-not $godotCmd) {
    $godotCmd = Get-Command Godot_v4 -ErrorAction SilentlyContinue
    if ($godotCmd) {
        Add-GodotLog "  Found 'Godot_v4' at: $($godotCmd.Source)"
    } else {
        Add-GodotLog "  'Godot_v4' not found in command cache"
        $detectionFailedReason += "Get-Command 精确匹配未找到 godot/godot4/Godot_v4"
    }
}

# --- Step 2: Scan PATH directories with wildcard ---
Add-GodotLog "Step 2: PATH directory wildcard scan for Godot_v4*.exe..."
if (-not $godotCmd) {
    $pathDirs = $env:PATH -split ';'
    $pathScanHit = $false
    $dirsChecked = 0
    foreach ($dir in $pathDirs) {
        if ($dir -and (Test-Path $dir)) {
            $dirsChecked++
            try {
                $found = Get-ChildItem -Path $dir -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    Add-GodotLog "  FOUND in PATH dir '$dir': $($found.FullName)"
                    $godotCmd = Get-Item $found.FullName
                    $godotPath = $found.FullName
                    $godotInstalled = $true
                    $pathScanHit = $true
                    break
                }
            } catch {
                Add-GodotLog "  Error scanning '$dir': $_"
            }
        }
    }
    Add-GodotLog "  Scanned $dirsChecked PATH directories with wildcard (Godot_v4*.exe)"
    if (-not $pathScanHit) {
        $detectionFailedReason += "PATH 通配符扫描 (Godot_v4*.exe) 在 $dirsChecked 个目录中未找到匹配文件"
        Add-GodotLog "  No Godot_v4*.exe found in any PATH directory"
    }
}

# --- Step 3: Handle Get-Command result ---
if ($godotCmd -and -not $godotInstalled) {
    $godotPath = $godotCmd.Source
    $godotInstalled = $true
    try {
        $godotVersion = (& $godotCmd.Source --version 2>&1).ToString()
        Add-GodotLog "  Version from command: $godotVersion"
    } catch {
        $godotVersion = "4.x (已安装)"
        Add-GodotLog "  Version query failed, using fallback: $godotVersion"
    }
}

if ($godotInstalled) {
    Write-Host "[OK] Godot 已安装" -ForegroundColor Green
    Write-Host "     版本: $godotVersion" -ForegroundColor White
    Write-Host "     路径: $godotPath" -ForegroundColor White
    Add-GodotLog "RESULT: Godot INSTALLED - path=$godotPath version=$godotVersion"
    # Write log file for installed case
    try {
        $godotLog | Out-File -FilePath $godotLogFile -Encoding UTF8 -Force
        Write-Host "  [日志] 检测日志已保存: $godotLogFile" -ForegroundColor Magenta
    } catch { }
} else {
    Add-GodotLog "RESULT: Godot NOT found via PATH/PATH-wildcard, starting deep scan..."
    $detectionFailedReason += "PATH 命令查找和通配符扫描均未找到 Godot"

    # --- Step 4: Scan common installation paths ---
    Add-GodotLog "Step 3: Deep scan of common installation paths..."
    $godotSearchPaths = @(
        "${env:ProgramFiles}\Godot\Godot.exe",
        "${env:ProgramFiles}\Godot_v4-stable-win64\Godot_v4-stable-win64.exe",
        "${env:ProgramFiles}\Godot_v4.3-stable-win64\Godot_v4.3-stable-win64.exe",
        "${env:ProgramFiles(x86)}\Godot\Godot.exe",
        "${env:LOCALAPPDATA}\Programs\Godot\Godot.exe",
        "${env:USERPROFILE}\Desktop\Godot_v4-stable-win64.exe",
        "${env:USERPROFILE}\Downloads\Godot_v4-stable-win64.exe",
        "${env:USERPROFILE}\Godot\Godot.exe",
        "C:\Godot\Godot.exe",
        "D:\Godot\Godot.exe"
    )

    # Log existence of each preset path
    $presetFound = 0
    foreach ($p in $godotSearchPaths) {
        if (Test-Path $p) {
            Add-GodotLog "  [EXISTS] $p"
            $presetFound++
        } else {
            Add-GodotLog "  [NOT FOUND] $p"
        }
    }
    if ($presetFound -eq 0) {
        $detectionFailedReason += "10 个预设安装路径均不存在 Godot 可执行文件"
    }

    # --- Step 5: Recursive search in user directories ---
    Add-GodotLog "Step 4: Recursive search in user directories (Desktop/Downloads/Documents/AppData)..."
    $searchDirs = @(
        "${env:USERPROFILE}\Desktop",
        "${env:USERPROFILE}\Downloads",
        "${env:USERPROFILE}\Documents",
        "${env:LOCALAPPDATA}\Programs"
    )

    $recursiveFound = 0
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            try {
                $found = Get-ChildItem -Path $dir -Filter "Godot*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    Add-GodotLog "  FOUND via recursive search: $($found.FullName)"
                    $godotSearchPaths += $found.FullName
                    $recursiveFound++
                } else {
                    Add-GodotLog "  No Godot*.exe found in '$dir' (depth=2)"
                }
            } catch {
                Add-GodotLog "  Error scanning '$dir': $_"
            }
        } else {
            Add-GodotLog "  Directory does not exist: $dir"
        }
    }
    if ($recursiveFound -eq 0) {
        $detectionFailedReason += "4 个用户目录递归搜索 (depth=2) 未找到 Godot*.exe"
    }

    # --- Step 6: Search extracted directories ---
    Add-GodotLog "Step 5: Search for extracted Godot directories (Godot*/Godot*.exe)..."
    $extractFound = $false
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            try {
                $foundDir = Get-ChildItem -Path $dir -Directory -Filter "Godot*" -Depth 1 -ErrorAction SilentlyContinue | Where-Object {
                    Test-Path (Join-Path $_.FullName "Godot*.exe")
                } | Select-Object -First 1
                if ($foundDir) {
                    $exe = Get-ChildItem -Path $foundDir.FullName -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($exe) {
                        $godotSearchPaths += $exe.FullName
                        $extractFound = $true
                        Add-GodotLog "  FOUND in extracted dir: $($exe.FullName)"
                    }
                } else {
                    Add-GodotLog "  No Godot* directory with Godot*.exe in '$dir'"
                }
            } catch {
                Add-GodotLog "  Error scanning '$dir': $_"
            }
        }
    }
    if (-not $extractFound) {
        $detectionFailedReason += "解压目录搜索未找到 Godot 可执行文件"
    }

    # --- Step 7: Final check on all collected paths ---
    Add-GodotLog "Step 6: Final verification of $($godotSearchPaths.Count) candidate paths..."
    $foundGodot = $null
    foreach ($p in ($godotSearchPaths | Select-Object -Unique)) {
        if ($p -and (Test-Path $p)) {
            $foundGodot = $p
            Add-GodotLog "  FINAL MATCH: $p"
            break
        }
    }

    if ($foundGodot) {
        $godotPath = $foundGodot
        $godotInstalled = $true
        try {
            $godotVersion = (& $godotPath --version 2>&1).ToString()
            Add-GodotLog "  Version from final match: $godotVersion"
        } catch {
            $godotVersion = "4.x (已检测到)"
            Add-GodotLog "  Version query failed, using fallback: $godotVersion"
        }
        Write-Host "[发现] Godot 已找到: $godotPath" -ForegroundColor Yellow
        Write-Host "     版本: $godotVersion" -ForegroundColor White
        Write-Host "     建议添加到系统 PATH 方便全局调用" -ForegroundColor Magenta
        Add-GodotLog "RESULT: Godot FOUND via deep scan - path=$godotPath"
    } else {
        Write-Host "[X] 未检测到 Godot 引擎" -ForegroundColor Red
        Write-Host "     运行《三界模拟器》需要 Godot 4.x 引擎" -ForegroundColor White

        # Print detailed failure reasons
        Write-Host ""
        Write-Host "  --- 诊断信息 ---" -ForegroundColor Yellow
        Add-GodotLog "RESULT: Godot NOT FOUND anywhere"
        Add-GodotLog "Failure reasons:"
        foreach ($reason in $detectionFailedReason) {
            Write-Host "    - $reason" -ForegroundColor Red
            Add-GodotLog "  REASON: $reason"
        }

        # PATH diagnostics
        $pathDirCount = ($env:PATH -split ';').Count
        $validPathDirs = 0
        foreach ($d in ($env:PATH -split ';')) {
            if ($d -and (Test-Path $d)) { $validPathDirs++ }
        }
        $pathDiagnostic = "PATH: $pathDirCount entries total, $validPathDirs valid directories"
        Write-Host "    $pathDiagnostic" -ForegroundColor Gray
        Add-GodotLog "  PATH DIAGNOSTIC: $pathDiagnostic"

        $godotExeInPath = Get-Command godot -ErrorAction SilentlyContinue
        if ($godotExeInPath) {
            Write-Host "    [NOTE] 'godot' command exists at $($godotExeInPath.Source) but was not matched" -ForegroundColor Yellow
            Add-GodotLog "  NOTE: 'godot' command exists at $($godotExeInPath.Source)"
        }

        # Check if any Godot-related files exist on the system
        $allDrives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue
        Write-Host "    扫描驱动器: $($allDrives.Root -join ', ')" -ForegroundColor Gray
        Add-GodotLog "  Drives: $($allDrives.Root -join ', ')"

        # Log Program Files contents for debugging
        $pfGodotDirs = Get-ChildItem -Path "${env:ProgramFiles}" -Filter "Godot*" -Directory -ErrorAction SilentlyContinue
        if ($pfGodotDirs) {
            Write-Host "    [NOTE] Found Godot-related dirs in Program Files:" -ForegroundColor Yellow
            foreach ($d in $pfGodotDirs) {
                Write-Host "      $($d.FullName)" -ForegroundColor Yellow
                Add-GodotLog "  NOTE: Godot dir in Program Files: $($d.FullName)"
            }
        }

        Write-Host ""
        Write-Host "  --- 建议 ---" -ForegroundColor Yellow
        Write-Host "    1. 下载 Godot: https://godotengine.org/download/windows" -ForegroundColor White
        Write-Host "    2. 解压到 C:\Godot\ 或 D:\Godot\" -ForegroundColor White
        Write-Host "    3. 将 Godot 目录添加到系统 PATH" -ForegroundColor White
        Write-Host "    4. 重新运行启动器" -ForegroundColor White
        Write-Host ""

        # Write log file
        try {
            $godotLog | Out-File -FilePath $godotLogFile -Encoding UTF8 -Force
            Write-Host "  [日志] 检测日志已保存: $godotLogFile" -ForegroundColor Magenta
            Add-GodotLog "Log saved to: $godotLogFile"
        } catch {
            Write-Host "  [警告] 无法写入日志文件: $_" -ForegroundColor Yellow
        }

        $downloadNow = Read-Host "  是否现在下载 Godot? (Y/N)"
        if ($downloadNow -eq 'Y' -or $downloadNow -eq 'y') {
            Write-Host ""
            Write-Host "  [1] 打开 Godot 官网下载页（推荐）" -ForegroundColor White
            Write-Host "  [2] winget 一键安装" -ForegroundColor White
            Write-Host "  [3] chocolatey 安装" -ForegroundColor White
            Write-Host "  [Q] 稍后再装" -ForegroundColor White
            Write-Host ""
            $godotChoice = Read-Host "  请选择"

            switch ($godotChoice) {
                '1' {
                    Start-Process "https://godotengine.org/download/windows"
                    Write-Host ""
                    Write-Host "  [下载] 已打开 Godot 下载页" -ForegroundColor Green
                    Write-Host "  建议下载 Godot 4.3 或更新版本 (Standard 版本即可)" -ForegroundColor Yellow
                    Write-Host "  下载后解压到任意目录（如 C:\Godot\）" -ForegroundColor Yellow
                    Write-Host "  然后重新打开 启动器.bat" -ForegroundColor Yellow
                }
                '2' {
                    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
                    if ($wingetCmd) {
                        try {
                            winget install GodotEngine.GodotEngine --accept-source-agreements --accept-package-agreements
                            Write-Host "[完成] Godot 安装完成！请重新打开 启动器.bat" -ForegroundColor Green
                        } catch {
                            Write-Host "[X] winget 安装失败，请改用方式 [1]" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "[X] winget 不可用，请改用方式 [1]" -ForegroundColor Red
                    }
                }
                '3' {
                    try {
                        choco install godot -y
                        Write-Host "[完成] Godot 安装完成！请重新打开 启动器.bat" -ForegroundColor Green
                    } catch {
                        Write-Host "[X] chocolatey 不可用，请改用方式 [1]" -ForegroundColor Red
                    }
                }
                default {
                    Write-Host "  已跳过。请稍后从 https://godotengine.org/download 下载" -ForegroundColor Gray
                }
            }
            Write-Host ""
        }
    }

# ============================================================
# 4. 检查 Git 用户配置
# ============================================================
Write-Host "[3/5] 检查 Git 用户配置..." -ForegroundColor Cyan

$userName = git config --global user.name 2>$null
$userEmail = git config --global user.email 2>$null

if (-not $userName -or -not $userEmail) {
    Write-Host "[提示] Git 用户信息未配置" -ForegroundColor Yellow
    Write-Host "       这会影响以后提交代码（可跳过，仅克隆代码无需配置）" -ForegroundColor Gray
    Write-Host ""
    $configNow = Read-Host "是否现在配置 Git 用户信息? (Y/N，留空=跳过)"
    if ($configNow -eq 'Y' -or $configNow -eq 'y') {
        $newName = Read-Host "请输入用户名（可任意填写）"
        $newEmail = Read-Host "请输入邮箱（建议用 GitHub 绑定邮箱）"
        if ($newName) { git config --global user.name $newName }
        if ($newEmail) { git config --global user.email $newEmail }
        Write-Host "[OK] 配置完成" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] 用户已配置: $userName <$userEmail>" -ForegroundColor Green
}

# ============================================================
# 5. 克隆项目
# ============================================================
Write-Host "[4/5] 准备克隆项目..." -ForegroundColor Cyan

$repoUrl = "https://github.com/langrendai26/game-project.git"
$repoName = "game-project"

Write-Host "  远程仓库: $repoUrl" -ForegroundColor White
Write-Host ""

# 选择目标目录
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$parentDir = Split-Path $scriptDir
$defaultDir = Join-Path $parentDir $repoName

Write-Host "  默认保存位置: $defaultDir" -ForegroundColor White
Write-Host ""

$customDir = Read-Host "按 Enter 使用默认位置，或输入自定义路径（如 D:\Projects\game）"
if ([string]::IsNullOrWhiteSpace($customDir)) {
    $targetDir = $defaultDir
} else {
    $targetDir = $customDir.Trim('"')
}

# 检查目录是否已存在
if (Test-Path $targetDir) {
    Write-Host "[警告] 目标目录已存在: $targetDir" -ForegroundColor Yellow
    $overwrite = Read-Host "        覆盖? (Y=删除后重新克隆 / S=跳过 / 其他=退出)"
    if ($overwrite -eq 'Y' -or $overwrite -eq 'y') {
        Write-Host "        正在删除旧目录..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $targetDir -ErrorAction SilentlyContinue
    } elseif ($overwrite -eq 'S' -or $overwrite -eq 's') {
        Write-Host "        跳过克隆。如需更新，请在该目录内执行 git pull" -ForegroundColor Gray
        Set-Location $targetDir
        git status
        return
    } else {
        Write-Host "        已取消" -ForegroundColor Gray
        return
    }
}

# 执行克隆
Write-Host ""
Write-Host "[5/5] 正在克隆项目..." -ForegroundColor Cyan
Write-Host "      克隆地址: $repoUrl" -ForegroundColor White
Write-Host "      保存到: $targetDir" -ForegroundColor White
Write-Host ""

try {
    Push-Location (Split-Path $targetDir)
    git clone $repoUrl (Split-Path $targetDir)
    Pop-Location

    if (Test-Path $targetDir) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  [成功] 项目已克隆到: $targetDir" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""

        # Godot 安装状态总结与自动打开
        if ($godotInstalled -and $godotPath) {
            $openNow = Read-Host "是否现在用 Godot 打开项目? (Y/N)"
            if ($openNow -eq 'Y' -or $openNow -eq 'y') {
                Write-Host "  正在启动 Godot..." -ForegroundColor Yellow
                Start-Process -FilePath $godotPath -ArgumentList "--path", "`"$targetDir`""
                Write-Host "  已启动 Godot，项目应自动加载" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "  后续打开方式：" -ForegroundColor Cyan
                Write-Host "    1. 直接双击: $targetDir\project.godot" -ForegroundColor White
                Write-Host "    2. 或启动 Godot 后点击 Import 选择 project.godot" -ForegroundColor White
                Write-Host "    3. 命令行: $godotPath --path `"$targetDir`"" -ForegroundColor White
            }
        } else {
            Write-Host "下一步：" -ForegroundColor Cyan
            Write-Host "  1. 安装 Godot 4.x（从 https://godotengine.org/download 下载）" -ForegroundColor White
            Write-Host "  2. 打开 Godot，点击 Import" -ForegroundColor White
            Write-Host "  3. 选择 $targetDir\project.godot" -ForegroundColor White
            Write-Host "  4. 开始游戏开发！" -ForegroundColor White
        }
    } else {
        Write-Host "[X] 克隆失败，目标目录未创建" -ForegroundColor Red
    }
} catch {
    Write-Host "[X] 克隆失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    常见原因：网络问题、仓库不存在、权限不足" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
