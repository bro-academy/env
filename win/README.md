# Developer Environment Setup Script

This PowerShell script automates the installation of essential developer tools on Windows 10 and 11, including PowerShell 7, Windows Terminal, Git, GitHub CLI, Visual Studio Code, and Volta.

---

## ✅ What the script does

- Checks if `winget` is available and initialized
- Installs or updates the following tools silently:
  - PowerShell 7
  - Windows Terminal
  - Git
  - GitHub CLI
  - Visual Studio Code
  - Volta (Node.js version manager)
- Displays progress and logs installation details to `install-dev-env.log`
- Asks for confirmation before updating existing tools (unless `-Force` is passed)

---

## 🧰 Requirements

- Windows 10 or Windows 11
- Administrator privileges to install software
- Internet connection
- `winget` (Windows Package Manager) installed and initialized

---

## ▶️ How to run the script

### 🧭 Option 1: Run as Administrator from current session

1. Open PowerShell **normally** (not as administrator).
2. Run this command to relaunch the script in an elevated session:

   ```powershell
   Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\install-dev-env.ps1"'
   ```

Replace the path with the actual location of your script file.
 3. Accept the UAC prompt to begin the installation.

⸻

### 🖥 Option 2: Run directly in an elevated terminal
 1. Open Windows Terminal or PowerShell as Administrator:
 • Press Win, type powershell or windows terminal
 • Right-click and select Run as administrator
 2. Navigate to the script folder:

```
cd C:\Path\To
```

 3. Run the script:

```
.\install-dev-env.ps1
```

⸻

## ⚠️ Important Notes
 • On first use, winget may show a terms & conditions (EULA) prompt.
To initialize it manually before running the script:

```
winget list
```

 • After script completion, restart Windows Terminal or open a new session to use the new tools.
 • This script installs Volta, but does not install Node.js yet. You can run volta install node manually after restart.

⸻

## 🛠 Troubleshooting
 • If you see execution policy errors:

```
Set-ExecutionPolicy RemoteSigned
```

 • If winget fails to work, install the latest App Installer from Microsoft Store and run winget list once manually.
 • Check install-dev-env.log (created in the same directory) for installation details or errors.

⸻

## 📝 License

This script is free to use, modify, and distribute.
