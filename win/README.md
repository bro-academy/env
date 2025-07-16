# Quick Start Guide

1. **Download the ZIP**  
   - Click the link below to download the installer package:  
     [https://example.com/dev-installer.zip](https://github.com/bro-academy/env/archive/refs/heads/main.zip)
     
   - Save the file to your **Downloads** folder (or a location of your choice).

2. **Unzip the Folder**  
   - Open **File Explorer** and navigate to where you saved `dev-installer.zip`.  
   - Right-click the ZIP file and choose **Extract All…**.  
   - Accept or choose a destination folder (e.g. `C:\Users\<You>\Downloads\dev-installer\`).

3. **Run the Installer**  
   - Open the unzipped folder.  
   - **Double-click** `install-dev-env.cmd`.  
   - When prompted **“Do you want to allow this app to make changes?”**, click **Yes**.  
   - A PowerShell window will open and begin installing/updating your tools.

4. **Follow On-Screen Prompts**  
   - If you see any **Y/N** questions (for updates), type **Y** and press **Enter** to continue, or **N** to skip.

5. **Finish**  
   - When you see **“Installation complete”**, press any key to close the window.  
   - Your developer tools are now installed and ready to use!  

# To run manually
```
winget install --id Microsoft.PowerShell -e
winget install --id Microsoft.WindowsTerminal -e
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Volta.Volta -e
```
