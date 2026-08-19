# Git 安装引导文档

> 本文档详细说明 Git 在 Windows 系统上的安装、配置、验证和故障排查方法。
> 适用于所有水平的用户，从零基础到进阶开发者。

---

## 目录

1. [安装前检查](#安装前检查)
2. [安装方式](#安装方式)
   - [方式 A：winget 一键安装（推荐）](#方式-awinget-一键安装推荐)
   - [方式 B：官网下载安装包](#方式-b官网下载安装包)
   - [方式 C：Chocolatey 安装](#方式-cchocolatey-安装)
   - [方式 D：Scoop 安装](#方式-dscoop-安装)
   - [方式 E：便携版（免安装）](#方式-e便携版免安装)
3. [安装后验证](#安装后验证)
4. [版本要求检查](#版本要求检查)
5. [Git 用户配置](#git-用户配置)
6. [PATH 环境变量问题](#path-环境变量问题)
7. [网络与代理配置](#网络与代理配置)
8. [日志文件位置](#日志文件位置)
9. [故障排查速查表](#故障排查速查表)

---

## 安装前检查

在安装 Git 之前，先检查系统是否已经安装了 Git。

### 方法 1：命令行检查

打开 PowerShell（按 `Win + X` → 选择「Windows PowerShell」），输入：

```powershell
git --version
```

- **如果显示** `git version 2.x.x.windows.1` → 已安装，跳到 [安装后验证](#安装后验证)
- **如果显示** `'git' 不是内部或外部命令` → 未安装或未加入 PATH，继续阅读

### 方法 2：启动器自动检查

双击项目中的 `tools/启动器.bat`，启动器会自动检测 Git 安装状态。

### 方法 3：手动检查常见安装路径

```powershell
# 检查常见安装位置
$paths = @(
    "$env:ProgramFiles\Git\cmd\git.exe",
    "$env:ProgramFiles(x86)\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
)
foreach ($p in $paths) {
    if (Test-Path $p) { Write-Host "Found: $p" -ForegroundColor Green }
}
```

---

## 安装方式

### 方式 A：winget 一键安装（推荐）

> 适用：Windows 10 1809+ / Windows 11，无需额外安装包管理器。

#### 步骤

1. 打开 PowerShell（不需要管理员权限）

2. 执行安装命令：

```powershell
winget install Git.Git --accept-source-agreements --accept-package-agreements
```

3. 等待下载安装完成（通常 1-3 分钟）

4. **关闭当前 PowerShell 窗口**，重新打开一个新的窗口

5. 验证安装：

```powershell
git --version
```

#### 如果 winget 不可用

```powershell
# 检查 winget 是否可用
Get-Command winget -ErrorAction SilentlyContinue

# 如果返回空，说明 winget 不可用
# 从 Microsoft Store 安装 "App Installer"
# 或跳转到方式 B
```

---

### 方式 B：官网下载安装包

> 适用：所有 Windows 版本，最可靠的方式。

#### 步骤

1. 访问 Git 官方下载页：https://git-scm.com/download/win

2. 页面会自动检测你的系统，点击下载 **"64-bit Git for Windows Setup"**

3. 运行下载的 `.exe` 安装程序

4. 安装选项建议（一路点 Next 即可，以下为推荐设置）：

   | 安装步骤 | 推荐选择 | 说明 |
   |---------|---------|------|
   | 组件选择 | 保持默认 | 不需要额外修改 |
   | 默认编辑器 | Use Visual Studio Code (if installed) 或 Use Vim | 根据个人习惯 |
   | PATH 设置 | **Git from the command line and also from 3rd-party software** | 最重要的一步，确保 git 可在终端使用 |
   | SSH 可执行文件 | Use bundled OpenSSH | 使用 Git 自带的 SSH |
   | HTTPS 传输后端 | Use the native Windows Secure Channel | 兼容性最好 |
   | 换行符转换 | Checkout Windows-style, commit Unix-style | 跨平台推荐 |
   | 终端模拟器 | Use MinTTY | Git Bash 默认终端 |
   | 默认拉取行为 | Default (fast-forward or merge) | 保持默认 |

5. 安装完成后，**重新打开 PowerShell 窗口**

6. 验证安装：

```powershell
git --version
```

---

### 方式 C：Chocolatey 安装

> 适用：已安装 Chocolatey 包管理器的用户。

#### 前提条件

```powershell
# 检查 chocolatey 是否已安装
Get-Command choco -ErrorAction SilentlyContinue
```

如果未安装 Chocolatey，先执行：

```powershell
# 以管理员身份运行 PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### 安装 Git

```powershell
# 以管理员身份运行
choco install git -y
```

#### 升级 Git

```powershell
choco upgrade git -y
```

---

### 方式 D：Scoop 安装

> 适用：已安装 Scoop 包管理器的用户。

#### 前提条件

```powershell
# 检查 scoop 是否已安装
Get-Command scoop -ErrorAction SilentlyContinue
```

如果未安装 Scoop：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
iwr -useb get.scoop.sh | iex
```

#### 安装 Git

```powershell
scoop install git
```

#### 升级 Git

```powershell
scoop update git
```

---

### 方式 E：便携版（免安装）

> 适用：没有管理员权限的电脑（如公司、学校电脑）。

#### 步骤

1. 访问 https://git-scm.com/download/win

2. 下载 **"64-bit Git for Windows Portable"**（便携版）

3. 解压到任意目录，例如 `D:\PortableGit\`

4. 手动将 Git 加入 PATH：

```powershell
# 在 PowerShell 中执行（仅对当前用户生效）
$gitBin = "D:\PortableGit\cmd"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$gitBin", "User")
$env:PATH += ";$gitBin"
```

5. 验证安装：

```powershell
git --version
```

> **注意**：便携版不会写入注册表，启动器的注册表扫描可能无法检测到它。
> 请确保手动添加到 PATH 后再运行启动器。

---

## 安装后验证

安装完成后，依次执行以下命令确认一切正常：

### 1. 基本命令检查

```powershell
# 检查版本
git --version
# 预期输出: git version 2.47.1.windows.1 (或更高)

# 检查安装路径
where.exe git
# 或
Get-Command git | Select-Object -ExpandProperty Source
```

### 2. 版本验证

```powershell
# 确保版本 >= 2.0.0
$ver = git --version
if ($ver -match 'version\s+(\d+)\.(\d+)\.(\d+)') {
    $parsed = [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])"
    $min = [version]"2.0.0"
    if ($parsed -ge $min) {
        Write-Host "Git 版本满足要求: $parsed >= $min" -ForegroundColor Green
    } else {
        Write-Host "Git 版本过低: $parsed < $min，建议升级" -ForegroundColor Yellow
    }
}
```

### 3. 基本功能测试

```powershell
# 测试 git config 命令
git config --list

# 测试 git 基本操作
$testDir = Join-Path $env:TEMP "git_test_$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force
Set-Location $testDir
git init
git status
Set-Location $env:TEMP
Remove-Item -Recurse -Force $testDir
```

---

## 版本要求检查

本项目要求 Git 版本 >= **2.0.0**。

### 版本过低时的处理

如果启动器检测到 Git 版本过低，会提示升级。选择升级方式：

```powershell
# 方式 1：winget 升级
winget upgrade Git.Git --accept-source-agreements --accept-package-agreements

# 方式 2：choco 升级
choco upgrade git -y

# 方式 3：官网下载最新版覆盖安装
# 访问 https://git-scm.com/download/win 下载最新版
```

### 版本检查日志

启动器会自动记录版本检查的详细日志到：

```
%TEMP%\git_detection_log_YYYYMMDD_HHMMSS.txt
```

日志内容包括：
- 输入的版本字符串
- 正则匹配过程
- 解析后的 major.minor.patch
- 与最低版本的逐级比较
- 边界条件检测结果
- 最终通过/失败结果

---

## Git 用户配置

安装 Git 后，需要配置用户名和邮箱（用于提交代码时的身份标识）。

### 基本配置

```powershell
# 设置全局用户名
git config --global user.name "你的名字"

# 设置全局邮箱
git config --global user.email "your-email@example.com"
```

### 查看配置

```powershell
# 查看所有配置
git config --list

# 查看用户名
git config user.name

# 查看邮箱
git config user.email
```

### 推荐配置

```powershell
# 设置默认分支名为 main
git config --global init.defaultBranch main

# 设置中文文件名不转义
git config --global core.quotepath false

# 设置默认编辑器（可选）
git config --global core.editor "code --wait"   # VS Code
# 或
git config --global core.editor "notepad"       # 记事本

# 设置长路径支持（Windows）
git config --global core.longpaths true
```

---

## PATH 环境变量问题

### 症状

安装 Git 后在 PowerShell 中执行 `git --version` 提示：

```
'git' 不是内部或外部命令，也不是可运行的程序
```

### 原因

Git 的安装目录未添加到系统 PATH 环境变量中。

### 解决方法 1：自动修复（启动器）

启动器检测到 Git 安装在预设路径但不在 PATH 中时，会自动将 Git 路径添加到当前会话的 PATH。

### 解决方法 2：手动添加到系统 PATH

```powershell
# 以管理员身份运行 PowerShell

# Git 默认安装路径
$gitPath = "$env:ProgramFiles\Git\cmd"

# 获取当前系统 PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")

# 如果 Git 路径不在 PATH 中，添加它
if ($currentPath -notlike "*$gitPath*") {
    $newPath = "$currentPath;$gitPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
    Write-Host "已将 $gitPath 添加到系统 PATH" -ForegroundColor Green
}

# 刷新当前会话 PATH
$env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")

# 验证
git --version
```

### 解决方法 3：通过图形界面添加

1. 按 `Win + R` → 输入 `sysdm.cpl` → 回车
2. 切换到「高级」选项卡
3. 点击「环境变量」
4. 在「系统变量」中找到 `Path` → 点击「编辑」
5. 点击「新建」→ 输入 `C:\Program Files\Git\cmd`
6. 点击「确定」关闭所有窗口
7. **重新打开 PowerShell**

---

## 网络与代理配置

### 症状

克隆项目时出现：

```
fatal: unable to access 'https://github.com/...': Failed to connect to github.com
```

或

```
fatal: unable to access 'https://github.com/...': Recv failure: Connection was reset
```

### 解决方法 1：配置 Git 代理

```powershell
# 如果使用 HTTP 代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 如果使用 SOCKS5 代理
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080
```

### 取消代理

```powershell
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 解决方法 2：使用 SSH 协议

```powershell
# 克隆时改用 SSH 地址
git clone git@github.com:langrendai26/game-project.git
```

> SSH 协议通常比 HTTPS 更稳定，但需要先配置 SSH Key。

### 配置 SSH Key

```powershell
# 1. 生成 SSH Key
ssh-keygen -t ed25519 -C "your-email@example.com"
# 一路回车使用默认设置

# 2. 查看公钥
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub

# 3. 复制公钥到剪贴板
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard

# 4. 添加到 GitHub
# 访问 https://github.com/settings/keys → New SSH key → 粘贴公钥

# 5. 测试连接
ssh -T git@github.com
```

### 解决方法 3：增大 HTTP 缓冲

```powershell
# 增大 HTTP 缓冲（解决大仓库克隆失败）
git config --global http.postBuffer 524288000

# 增大超时时间
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
```

---

## 日志文件位置

启动器运行时会生成以下日志文件，便于排查问题：

### Git 检测日志

```
%TEMP%\git_detection_log_YYYYMMDD_HHMMSS.txt
```

日志内容包括：
- Get-Command 检测结果
- 预设路径扫描（10 个路径逐一检查）
- 注册表扫描结果
- PATH 目录扫描
- 版本检查详情（解析、比较、边界检测）
- 用户决策记录
- 安装/升级过程输出

### Godot 检测日志

```
%TEMP%\godot_detection_log_YYYYMMDD_HHMMSS.txt
```

### 查看日志的方法

```powershell
# 打开日志目录
explorer $env:TEMP

# 查看最新的 Git 日志
$latestGitLog = Get-ChildItem -Path $env:TEMP -Filter "git_detection_log_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestGitLog) {
    Get-Content $latestGitLog.FullName
}

# 查看最新的 Godot 日志
$latestGodotLog = Get-ChildItem -Path $env:TEMP -Filter "godot_detection_log_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestGodotLog) {
    Get-Content $latestGodotLog.FullName
}
```

---

## 故障排查速查表

| 症状 | 可能原因 | 解决方法 |
|------|---------|---------|
| `'git' 不是内部或外部命令` | Git 未安装或不在 PATH | 重新安装时选择「Git from command line」，或手动添加 PATH |
| `git: command not found` | PATH 配置未生效 | 关闭并重新打开 PowerShell 窗口 |
| `git version` 显示低于 2.0 | Git 版本过旧 | 执行 `winget upgrade Git.Git` 或从官网下载最新版 |
| 克隆时 `Connection was reset` | 网络不稳定或被防火墙拦截 | 配置代理或使用 SSH 协议克隆 |
| 克隆时 `Repository not found` | 仓库地址错误或无权限 | 确认地址正确，如为私有仓库需配置认证 |
| `Failed to connect to github.com` | 网络不通或 DNS 问题 | 检查网络连接，尝试配置代理 |
| `Permission denied (publickey)` | SSH Key 未配置或未添加到 GitHub | 参照[网络与代理配置](#网络与代理配置)生成并添加 SSH Key |
| PowerShell 脚本无法运行 | 执行策略限制 | `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass` |
| 启动器.bat 闪退 | Windows SmartScreen 拦截 | 右键 → 属性 → 勾选「解除锁定」 |
| 中文乱码 | PowerShell 编码问题 | 执行 `chcp 65001` 切换为 UTF-8 编码 |
| winget 提示未找到 | winget 版本过旧或不可用 | 从 Microsoft Store 更新「App Installer」，或改用官网下载 |
| `SSL certificate problem` | SSL 证书问题 | `git config --global http.sslVerify false`（仅临时使用） |

---

## 参考链接

- Git 官方下载：https://git-scm.com/download/win
- Git 官方文档：https://git-scm.com/doc
- winget 文档：https://learn.microsoft.com/en-us/windows/package-manager/winget/
- Chocolatey：https://chocolatey.org/
- Scoop：https://scoop.sh/
- GitHub SSH 文档：https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- 本项目仓库：https://github.com/langrendai26/game-project

---

© 三界模拟器 · Git 安装引导文档
