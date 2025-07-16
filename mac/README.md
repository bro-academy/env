# Install needed development environment on Mac OS

## 1) Install Git via Apple’s Command Line Tools
```
xcode-select --install
```

## 2) (If you don’t already have Homebrew) Install Homebrew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 3) Update Homebrew’s package database
```
brew update
```

## 4) (Optional) Install an improved Terminal app (iTerm2)
```
brew install --cask iterm2
```

## 5) Install GitHub CLI
```
brew install gh
```

## 6) Install Visual Studio Code
```
brew install --cask visual-studio-code
```

## 7) Install Volta (Node.js toolchain manager)
```
brew install volta
```

## 8) Add Volta to your shell’s PATH
###    If you use zsh (default on recent macOS):
```
echo 'export VOLTA_HOME="$HOME/.volta"' >> ~/.zshrc
echo 'export PATH="$VOLTA_HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

###    If you use bash:
```
echo 'export VOLTA_HOME="$HOME/.volta"' >> ~/.bash_profile
echo 'export PATH="$VOLTA_HOME/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

## 9) (Optional) Upgrade any already-installed formulae and casks
```
brew upgrade
```
