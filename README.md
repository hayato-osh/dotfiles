# dotfiles
managed by [chezmoi](https://www.chezmoi.io/)

## setup
### Homebrewとchezmoiのセットアップ
```zsh
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

// terminalに表示されるコマンドを入力

$ brew install chezmoi

$ git config --global user.email 〇〇
$ git config --global user.name 〇〇

$ cd ~/.ssh
$ ssh-keygen -t rsa -C hoge@example.com ←GitHubのメールアドレス

// 秘密鍵の権限を設定
$ sudo chmod 600 id_rsa

$ cat id_rsa.pub
// GitHubにssh keyを設定

$ chezmoi init git@github.com:GitHayato/dotfiles.git

$ chezmoi apply

$ brew bundle
```
i
