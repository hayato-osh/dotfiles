###############
# aliasの設定 
###############

# rust
alias cat='bat'
alias ls='exa --icons'
alias ls.='exa --icons -a'
alias find='fd'
alias grep='rg'

# git
alias g='git'
alias gc='git commit -m'
alias gp='git push origin $(git rev-parse --abbrev-ref HEAD)'
alias gpl='git pull origin $(git rev-parse --abbrev-ref HEAD)'
alias gf='git fetch'
alias gsreset='git reset --soft HEAD^'
alias ghreset='git reset --hard HEAD^'
alias gbl='git branch --sort=-authordate | head -n 5'

# others
alias vim='nvim'
alias ll='ls -al'
