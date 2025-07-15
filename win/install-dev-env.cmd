@echo off
REM Launcher for install-dev-env.ps1
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0install-dev-env.ps1' %*"
