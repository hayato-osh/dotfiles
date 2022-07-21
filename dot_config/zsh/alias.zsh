###############
# aliasの設定 
###############

# rust
alias cat='bat'
alias ls='exa --icons'
alias ls.='exa --icons -a'
alias find='fd'
alias grep='gp'

# git
alias ga='git add .'
alias gan='git add -n .'
alias gc='git commit -m'
alias gco='git checkout'
alias gp='git push origin $(git rev-parse --abbrev-ref HEAD)'
alias gpl='git pull origin $(git rev-parse --abbrev-ref HEAD)'
alias gplm='git pull origin main'
alias gpld='git pull origin develop'
alias gf='git fetch'
alias gl='git log --oneline --graph'
alias greset='git reset --soft HEAD^'
alias gempty='git commit --allow-empty -m "empty commit"'

# yarn
alias y='yarn'
alias yd='yarn dev'
alias ydp='yarn dev-proxy'
alias ydpp='yarn dev-prod-proxy'
alias ys='yarn storybook'
