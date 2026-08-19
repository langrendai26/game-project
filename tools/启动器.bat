@echo off
REM ============================================================
REM 三界模拟器 - Git 环境一键检查与项目拉取启动器
REM 双击即可运行，自动绕过 PowerShell 执行策略限制
REM ============================================================

chcp 65001 >nul 2>&1
title 三界模拟器 - Git 环境检查与项目拉取

echo.
echo ========================================
echo    Git 环境一键检查与项目拉取
echo ========================================
echo.

REM 切换到脚本所在目录
cd /d "%~dp0"

REM 以 Bypass 执行策略调用 PowerShell 脚本
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CheckGit.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [提示] 脚本退出码: %ERRORLEVEL%
    echo        若遇到错误，请截图反馈
    echo.
    pause
)
