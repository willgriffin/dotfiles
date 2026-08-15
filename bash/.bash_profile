# ~/.bash_profile - Bash Login Shell Configuration
# Source .bashrc for consistent environment across login and non-login shells

export BASH_ENV="${BASH_ENV:-$HOME/.bash_env}"
[[ -f ~/.bashrc ]] && source ~/.bashrc
