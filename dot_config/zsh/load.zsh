######################
# ファイルの読み込み
######################


# git-promptの読み込み(無効化)
# source ~/.zsh/git-prompt.sh

# git-completionの読み込み
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit

# zsh-autosuggestionsの読み込み
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-autocompleteの読み込み
source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh

