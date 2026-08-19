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

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
$gitInstalled = $false

if ($gitCmd) {
    $gitVersion = (& git --version 2>&1)
    $gitPath    = $gitCmd.Source
    $gitInstalled = $true

    Write-Host "[OK] Git 已安装" -ForegroundColor Green
    Write-Host "     版本: $gitVersion" -ForegroundColor White
    Write-Host "     路径: $gitPath" -ForegroundColor White

    # 额外检查：git 是否真的能运行
    try {
        $null = & git rev-parse --is-inside-work-tree 2>&1
        Write-Host "     状态: 命令可正常执行" -ForegroundColor White
    } catch {
        Write-Host "     [警告] git 命令存在但执行异常: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[X] 未检测到 git 命令" -ForegroundColor Red

    # 额外检查：是否安装了 git 但未加入 PATH
    $commonPaths = @(
        "${env:ProgramFiles}\Git\cmd\git.exe",
        "${env:ProgramFiles}\Git\bin\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "${env:LOCALAPPDATA}\Programs\Git\cmd\git.exe",
        "${env:USERPROFILE}\scoop\shims\git.exe"
    )

    $foundGit = $null
    foreach ($p in $commonPaths) {
        if (Test-Path $p) {
            $foundGit = $p
            break
        }
    }

    if ($foundGit) {
        Write-Host "[发现] Git 已安装但未加入 PATH: $foundGit" -ForegroundColor Yellow
        Write-Host "[修复] 正在将 Git 添加到当前会话的 PATH..." -ForegroundColor Yellow
        $gitDir = Split-Path (Split-Path $foundGit)
        $env:PATH = "$gitDir;$env:PATH"
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd) {
            $gitVersion = (& git --version 2>&1)
            $gitInstalled = $true
            Write-Host "[OK] 已修复，Git 现在可用了" -ForegroundColor Green
            Write-Host "     版本: $gitVersion" -ForegroundColor White
            Write-Host "     注意: 请重启终端后再次使用，或永久添加到系统 PATH" -ForegroundColor Magenta
        }
    }
}

# ============================================================
# 2. 未安装则引导安装
# ============================================================
if (-not $gitInstalled) {
    Write-Host ""
    Write-Host "[2/5] Git 未安装，请选择安装方式：" -ForegroundColor Cyan
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

# ============================================================
# 3. 检查 Godot 安装状态
# ============================================================
Write-Host "[2/5] 检查 Godot 安装状态..." -ForegroundColor Cyan

$godotInstalled = $false
$godotPath = $null
$godotVersion = $null
$godotCmd = Get-Command godot -ErrorAction SilentlyContinue
if (-not $godotCmd) { $godotCmd = Get-Command godot4 -ErrorAction SilentlyContinue }
if (-not $godotCmd) { $godotCmd = Get-Command Godot_v4 -ErrorAction SilentlyContinue }

# Also scan PATH directories for Godot_v4*.exe pattern (handles versioned filenames)
if (-not $godotCmd) {
    $pathDirs = $env:PATH -split ';'
    foreach ($dir in $pathDirs) {
        if ($dir -and (Test-Path $dir)) {
            $found = Get-ChildItem -Path $dir -Filter "Godot_v4*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $godotCmd = Get-Item $found.FullName  # Use Get-Item to get full path
                $godotPath = $found.FullName
                $godotInstalled = $true
                try {
                    $godotVersion = (& $godotPath --version 2>&1).ToString()
                } catch {
                    $godotVersion = "4.x (已检测到)"
                }
                break
            }
        }
    }
}

if ($godotCmd -and -not $godotInstalled) {
    $godotPath = $godotCmd.Source
    $godotInstalled = $true
    try {
        $godotVersion = (& $godotCmd.Source --version 2>&1).ToString()
    } catch {
        $godotVersion = "4.x (已安装)"
    }
}

if ($godotInstalled) {
    Write-Host "[OK] Godot 已安装" -ForegroundColor Green
    Write-Host "     版本: $godotVersion" -ForegroundColor White
    Write-Host "     路径: $godotPath" -ForegroundColor White
} else {
    # 扫描常见安装路径
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

    # 也查找桌面/下载目录中的 Godot 压缩包解压目录
    $searchDirs = @(
        "${env:USERPROFILE}\Desktop",
        "${env:USERPROFILE}\Downloads",
        "${env:USERPROFILE}\Documents",
        "${env:LOCALAPPDATA}\Programs"
    )

    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            $found = Get-ChildItem -Path $dir -Filter "Godot*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $godotSearchPaths += $found.FullName
                break
            }
        }
    }

    # 查找 .zip 解压后的 Godot 目录
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            $foundDir = Get-ChildItem -Path $dir -Directory -Filter "Godot*" -Depth 1 -ErrorAction SilentlyContinue | Where-Object {
                Test-Path (Join-Path $_.FullName "Godot*.exe")
            } | Select-Object -First 1
            if ($foundDir) {
                $exe = Get-ChildItem -Path $foundDir.FullName -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($exe) {
                    $godotSearchPaths += $exe.FullName
                }
                break
            }
        }
    }

    $foundGodot = $null
    foreach ($p in $godotSearchPaths | Select-Object -Unique) {
        if ($p -and (Test-Path $p)) {
            $foundGodot = $p
            break
        }
    }

    if ($foundGodot) {
        $godotPath = $foundGodot
        $godotInstalled = $true
        try {
            $godotVersion = (& $godotPath --version 2>&1).ToString()
        } catch {
            $godotVersion = "4.x (已检测到)"
        }
        Write-Host "[发现] Godot 已找到: $godotPath" -ForegroundColor Yellow
        Write-Host "     版本: $godotVersion" -ForegroundColor White
        Write-Host "     建议添加到系统 PATH 方便全局调用" -ForegroundColor Magenta
    } else {
        Write-Host "[X] 未检测到 Godot 引擎" -ForegroundColor Red
        Write-Host "     运行《三界模拟器》需要 Godot 4.x 引擎" -ForegroundColor White
        Write-Host ""

        $downloadNow = Read-Host "     是否现在下载 Godot? (Y/N)"
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
