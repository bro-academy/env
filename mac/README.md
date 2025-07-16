# MacOS Dev Environment Installer

A simple script to install or update your core developer tools on macOS.

## Quick Start

1. **Download the ZIP**
    - Click the link below to download the installer package:
      ```
      https://github.com/bro-academy/env/archive/refs/heads/main.zip
      ```
    - Save it to your **Downloads** folder (or any location you prefer).

2. **Unzip the Folder**
    - Open **Finder** and locate `dev-installer-mac.zip`.
    - Double-click it (or right-click → **“Open With → Archive Utility”**) to extract.
    - You’ll get a folder, e.g. `~/Downloads/env-main/`, containing:
      ```
      install-dev-env-mac.sh
      install-dev-env-mac.command
      README.md
      ```

3. **Run by Double-Clicking**
    - In **Finder**, navigate to `~/Downloads/env-main/`.
    - **Control-click** (or right-click) the `install-dev-env-mac.command` file.
    - Choose Open from the contextual menu.
    - You’ll get the same warning—but now the dialog will have an Open button. Click Open.
    - Terminal will open and begin installing/updating tools.

4. **Or Run Manually in Terminal**
    - Open **Terminal** and type:
      ```bash
      cd ~/Downloads/env-main
      ./install-dev-env-mac.command
      ```
    - Follow any on-screen prompts to confirm installations or upgrades.

5. **Follow On-Screen Prompts**
    - You may be asked to install Apple’s Command Line Tools (for Git), Homebrew, and to approve upgrades.
    - Type **y** or **yes** to proceed, or **n**/Enter to skip.

7. **Finish**
    - When you see **“✅ All done!”**, close the Terminal window or press any key.
    - Your tools (Git, Homebrew, iTerm2, GitHub CLI, VS Code, Volta) are now installed and ready.

---

Now you’re all set—enjoy your streamlined macOS dev environment! 🚀


## Manual install needed development environment on Mac OS

### 1) Install Git via Apple’s Command Line Tools
```
xcode-select --install
```

### 2) (If you don’t already have Homebrew) Install Homebrew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3) Update Homebrew’s package database
```
brew update
```

### 4) (Optional) Install an improved Terminal app (iTerm2)
```
brew install --cask iterm2
```

### 5) Install GitHub CLI
```
brew install gh
```

### 6) Install Visual Studio Code
```
brew install --cask visual-studio-code
```

### 7) Install Volta (Node.js toolchain manager)
```
brew install volta
```
if you can't use Homebrew, you can install Volta manually by running:
```
curl https://get.volta.sh | bash
```

### 8) Add Volta to your shell’s PATH
####    If you use zsh (default on recent macOS):
```
echo 'export VOLTA_HOME="$HOME/.volta"' >> ~/.zshrc
echo 'export PATH="$VOLTA_HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

####    If you use bash:
```
echo 'export VOLTA_HOME="$HOME/.volta"' >> ~/.bash_profile
echo 'export PATH="$VOLTA_HOME/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

### 9) (Optional) Upgrade any already-installed formulae and casks
```
brew upgrade
```
