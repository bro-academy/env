#!/usr/bin/env bash
#
# install-dev-env-mac.sh
# A script to install and update developer tools on macOS.
#

set -e

# Prompt helper (compatible with macOS’s default Bash)
confirm() {
  local response
  while true; do
    read -rp "$1 [y/N]: " response
    response="$(echo "$response" | tr '[:upper:]' '[:lower:]')"
    case "$response" in
      y|yes) return 0 ;;
      n|no|"" ) return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

echo "🔧 Starting macOS dev-env installation..."

# 1) Install Apple Command Line Tools (includes Git)
if ! xcode-select -p &>/dev/null; then
  echo "1) Installing Xcode Command Line Tools (for Git)..."
  xcode-select --install || echo "→ Installer already running or installed."
else
  echo "1) Xcode Command Line Tools already installed."
  if confirm "   (Optional) Install any available updates via Software Update?"; then
    echo "   → Open System Settings → Software Update to apply updates."
  fi
fi

# 2) Install Homebrew if missing
if ! command -v brew &>/dev/null; then
  echo "2) Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "2) Homebrew already installed."
  if confirm "   (Optional) Update Homebrew itself now?"; then
    brew update
  fi
fi

# 3) Update Homebrew database
echo "3) Updating Homebrew package list..."
brew update

# 4) (Optional) iTerm2
if ! brew list --cask iterm2 &>/dev/null; then
  if confirm "4) Install iTerm2 (alternative terminal)?"; then
    brew install --cask iterm2
  fi
else
  echo "4) iTerm2 already installed."
  if confirm "   Upgrade iTerm2?"; then
    brew upgrade --cask iterm2
  fi
fi

# 5) GitHub CLI
if ! command -v gh &>/dev/null; then
  echo "5) Installing GitHub CLI..."
  brew install gh
else
  echo "5) GitHub CLI already installed."
  if confirm "   Upgrade GitHub CLI?"; then
    brew upgrade gh
  fi
fi

# 6) Visual Studio Code
if [ -d "/Applications/Visual Studio Code.app" ]; then
  echo "6) VS Code app already in /Applications."
  if confirm "   Upgrade via Homebrew?"; then
    brew upgrade --cask visual-studio-code
  fi

elif brew list --cask visual-studio-code &>/dev/null; then
  echo "6) VS Code installed via Homebrew."
  if confirm "   Upgrade VS Code?"; then
    brew upgrade --cask visual-studio-code
  fi

else
  echo "6) Installing Visual Studio Code..."
  brew install --cask visual-studio-code
fi

# 7) Volta
if brew list --formula volta &>/dev/null; then
  echo "7) Volta installed via Homebrew."
  if confirm "   Upgrade Volta?"; then
    brew upgrade volta
  fi

elif command -v volta &>/dev/null; then
  echo "7) Volta detected but not managed by Homebrew."
  if confirm "   Would you like to (re)install via Homebrew?"; then
    brew install volta
  fi

else
  echo "7) Installing Volta..."
  brew install volta
fi

# 8) Ensure Volta is on PATH in both bash_profile and zshrc
BASH_RC="$HOME/.bash_profile"
ZSH_RC="$HOME/.zshrc"

for rc in "$BASH_RC" "$ZSH_RC"; do
  if [ -w "$rc" ] || [ ! -e "$rc" ]; then
    if ! grep -q 'export VOLTA_HOME' "$rc" 2>/dev/null; then
      echo "Updating $rc to include Volta in PATH..."
      {
        echo ''
        echo '# Volta (Node.js toolchain manager)'
        echo 'export VOLTA_HOME="$HOME/.volta"'
        echo 'export PATH="$VOLTA_HOME/bin:$PATH"'
      } >> "$rc"
    else
      echo "$rc already contains Volta PATH entries."
    fi
  else
    echo "Cannot write to $rc; please add Volta exports manually."
  fi
done

echo
echo "✅ All done! Your macOS development environment is installed/updated."
echo "→ Open a new terminal or run: source ~/.bash_profile && source ~/.zshrc"
