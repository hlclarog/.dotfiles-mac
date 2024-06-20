# Enable aliases to be sudo’ed
alias sudo='sudo '

alias ..="cd .."
alias ...="cd ../.."
alias ll="ls -l"
alias la="ls -la"
alias ~="cd ~"
alias dotfiles='cd $DOTFILES_PATH'

# Git
alias gaa="git add -A"
alias gc='$DOTLY_PATH/bin/dot git commit'
alias gca="git add --all && git commit --amend --no-edit"
alias gco="git checkout"
alias gd='$DOTLY_PATH/bin/dot git pretty-diff'
alias gs="git status -sb"
alias gf="git fetch --all -p"
alias gps="git push"
alias gpsf="git push --force"
alias gpl="git pull"
alias gpll="git pull --rebase --autostash"
alias gb="git branch"
alias gl='$DOTLY_PATH/bin/dot git pretty-log'

# Utils
alias k='kill -9'
alias i.='(idea $PWD &>/dev/null &)'
alias ws.='(webstorm $PWD &>/dev/null &)'
alias c.='(code $PWD &>/dev/null &)'
alias o.='open .'
alias up='dot package update_all'
alias reload!='. ~/.zshrc && echo "Zsh reloaded" && . ~/.bashrc && echo "Bash reloaded"'

# own documents code
alias cdp='cd $HOME/Projects'
alias cdw='cd $HOME/Projects/work'
alias cdt2='cdw && cd trip2-cms'
alias cdsg='cdw && cd softgnet'
alias cdrh='cdsg && cd rh'

alias cls='clear'

# own nvm
alias nad='nvm alias default'
alias nu='nvm use'
alias nl='nvm list'


# view aliases docfiles
#alias vda='vim $DOTFILES_PATH/aliases.sh'

function help_aliases {
    echo 
    alias
}