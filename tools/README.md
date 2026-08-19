# 三界模拟器 · 快速上手指南

> 本指南说明如何在另一台电脑上获取并运行《三界模拟器》项目。

---

## 目录

1. [方案 A：使用一键启动器（推荐）](#方案-a使用一键启动器推荐)
2. [方案 B：手动克隆（进阶用户）](#方案-b手动克隆进阶用户)
3. [运行项目](#运行项目)
4. [常见问题排查](#常见问题排查)
5. [项目结构](#项目结构)

---

## 方案 A：使用一键启动器（推荐）

启动器会自动检查 Git、处理权限问题、引导安装并克隆项目，全程无需手动输入命令。

### 第一步：获取启动器文件

在另一台电脑上，从 GitHub 下载以下两个文件：

| 文件 | 作用 |
|------|------|
| [启动器.bat](https://github.com/langrendai26/game-project/blob/main/tools/%E5%90%AF%E5%8A%A8%E5%99%A8.bat) | 双击即可运行的入口 |
| [CheckGit.ps1](https://github.com/langrendai26/game-project/blob/main/tools/CheckGit.ps1) | 核心检查与克隆脚本 |

**下载方法**：
1. 访问 https://github.com/langrendai26/game-project
2. 浏览到 `tools/` 目录
3. 点击文件名 → 点击右上角 `Raw` → 浏览器保存（Ctrl+S）
4. 将两个文件保存到同一文件夹下（例如 `D:\git-tools\`）

### 第二步：双击运行

双击 **`启动器.bat`**，脚本会自动完成：

```
[1/4] 检查 Git 安装状态...     ← 检测是否已装 Git
[2/4] 检查 Git 用户配置...     ← 询问设置用户名/邮箱
[3/4] 准备克隆项目...           ← 选择保存位置
[4/4] 正在克隆项目...           ← 从 GitHub 下载代码
```

如果 Git 未安装，会提供 4 种安装方式：

- `[1]` **winget 一键安装**：Windows 10/11 自带，自动安装
- `[2]` **官网下载**：打开 Git 官网下载页，双击安装
- `[3]` **chocolatey 安装**：使用 choco 包管理器
- `[4]` **详细步骤引导**：显示手动安装的详细说明

### 第三步：打开项目

克隆完成后，用 Godot 4.x 打开项目即可运行。

---

## 方案 B：手动克隆（进阶用户）

如果你已经熟悉 Git，可以直接在终端中执行：

### 1. 安装 Git

```powershell
# 方式 A：winget（Windows 10/11）
winget install Git.Git

# 方式 B：官网下载
# 访问 https://git-scm.com/download/win
```

### 2. 配置 Git 用户（仅首次）

```powershell
git config --global user.name "您的名字"
git config --global user.email "your-email@example.com"
```

### 3. 克隆项目

```powershell
# 克隆到默认目录
git clone https://github.com/langrendai26/game-project.git

# 或克隆到自定义位置
git clone https://github.com/langrendai26/game-project.git D:\Projects\game-project

# 进入项目目录
cd game-project
```

### 4. 后续更新

```powershell
# 拉取远程最新更新
git pull

# 查看本地修改
git status

# 提交自己的修改
git add .
git commit -m "你的修改说明"
git push origin main
```

---

## 运行项目

1. 安装 [Godot Engine 4.x](https://godotengine.org/download/)
2. 打开 Godot，点击 **Import**
3. 选择项目目录下的 `project.godot` 文件
4. 点击运行按钮 ▶️ 开始游戏

---

## 常见问题排查

### Q: 双击启动器.bat 闪退？

**原因**：Windows SmartScreen 可能拦截了脚本。

**解决**：
1. 右键 `启动器.bat` → **属性**
2. 勾选 **"解除锁定"** （在"常规"选项卡底部）
3. 点击 **应用** → **确定**
4. 重新双击运行

---

### Q: 提示"git 不是内部或外部命令"？

**原因**：Git 未安装或未加入系统 PATH。

**解决**：
- 运行启动器，选择 `[1]` winget 一键安装，或 `[2]` 官网下载安装
- 安装完成后**重新打开启动器**（必须关闭当前窗口后重新打开）

---

### Q: 提示"无法加载文件，因为在此系统上禁止运行脚本"？

**原因**：PowerShell 执行策略限制。

**解决**：启动器.bat 已自动处理此问题。如果仍报错，请：
1. 右键 `启动器.bat` → **以管理员身份运行**
2. 或手动设置执行策略：
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
   ```

---

### Q: 克隆时提示"Repository not found"？

**原因**：仓库地址错误或网络问题。

**解决**：
- 确认仓库地址为 `https://github.com/langrendai26/game-project.git`
- 检查网络连接
- 如果仓库是私有的，需要使用 GitHub Personal Access Token 认证

---

### Q: 克隆很慢或超时？

**原因**：网络不稳定或 GitHub 访问受限。

**解决**：
- 检查网络连接
- 尝试使用 SSH 协议（需配置 SSH key）：
  ```powershell
  git clone git@github.com:langrendai26/game-project.git
  ```
- 配置 Git 代理（如果需要）

---

### Q: 克隆后 Godot 无法打开项目？

**原因**：Godot 版本不兼容。

**解决**：
- 使用 Godot **4.x** 版本（推荐 4.3 或更高）
- 确认打开的是 `project.godot` 文件而非目录

---

### Q: 如何在另一台电脑上获取启动器？

启动器文件已经是项目的一部分，有三种获取方式：

1. **从 GitHub 下载**：访问仓库 → `tools/` 目录 → 下载两个文件
2. **从现有电脑复制**：项目克隆完成后，`tools/` 目录下自带启动器
3. **直接下载链接**：
   - 启动器.bat：[点击下载](https://raw.githubusercontent.com/langrendai26/game-project/main/tools/%E5%90%AF%E5%8A%A8%E5%99%A8.bat)
   - CheckGit.ps1：[点击下载](https://raw.githubusercontent.com/langrendai26/game-project/main/tools/CheckGit.ps1)

---

## 项目结构

```
game-project/
├── scripts/              # 游戏脚本
│   ├── Inventory.gd      # 背包系统
│   ├── Shop.gd           # 商店系统
│   ├── KarmaSystem.gd    # 业力系统
│   ├── AlchemySystem.gd  # 炼丹系统
│   ├── SkillSystem.gd    # 技能系统
│   ├── MapSystem.gd      # 地图探索
│   ├── MainGameScene.gd  # 主场景
│   └── ...
├── test/                 # 测试场景
│   ├── BuddhistMockTest.gd      # 佛教主题测试
│   ├── ComplexStabilityTest.gd   # 复杂稳定性测试
│   ├── SystemIntegrationTest.gd # 系统集成测试
│   └── ...
├── textures/             # 游戏素材
├── tools/                # 工具脚本
│   ├── 启动器.bat        # Git 环境检查启动器
│   └── CheckGit.ps1      # 核心检查脚本
├── docs/                 # 文档
└── project.godot         # Godot 项目文件
```

---

## 技术支持

如果遇到其他问题，可以：
- 提交 GitHub Issue：[https://github.com/langrendai26/game-project/issues](https://github.com/langrendai26/game-project/issues)
- 查看项目文档：[docs/](https://github.com/langrendai26/game-project/tree/main/docs)

---

© 三界模拟器 · 佛教世界观修仙游戏项目
