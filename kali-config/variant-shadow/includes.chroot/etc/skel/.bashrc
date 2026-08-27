# Shadow - dynamic hostname@user prompt

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth

# Check window size after each command
shopt -s checkwinsize

# Enable color support
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Green on black prompt - shows current hostname@user dynamically
PS1='\[\033[01;32m\]\h@\u:\[\033[00m\]\w\$ '

# If this is an xterm set the title
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\033]0;\h@\u: \w\a\]$PS1"
    ;;
*)
    ;;
esac
