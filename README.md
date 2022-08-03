# dotfiles
managed by [chezmoi](https://www.chezmoi.io/)

## setup
### Homebrewとchezmoiのセットアップ
```zsh
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

// terminalに表示されるコマンドを入力

$ brew install chezmoi

$ chezmoi init git@github.com:GitHayato/dotfiles.git

$ chezmoi apply

$ brew bundle
```
