# ~/.zshrc - Portable Zsh Configuration with Oh My Zsh
# Managed by dotfiles repo, works on NixOS, macOS, Linux, and containers

# ==============================================================================
# Platform Detection
# ==============================================================================
case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)      PLATFORM="unknown" ;;
esac

# ==============================================================================
# Oh My Zsh Configuration
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Theme - use starship if available, otherwise robbyrussell
if command -v starship &> /dev/null; then
    ZSH_THEME=""  # Disable oh-my-zsh theme, use starship
else
    ZSH_THEME="robbyrussell"
fi

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    history
    sudo
    command-not-found
)

# Load Oh My Zsh (if installed)
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    # Fallback: manual plugin loading if oh-my-zsh not installed
    # Autosuggestions
    for dir in \
        "$HOME/.nix-profile/share/zsh-autosuggestions" \
        "/run/current-system/sw/share/zsh-autosuggestions" \
        "/usr/share/zsh/plugins/zsh-autosuggestions" \
        "/usr/share/zsh-autosuggestions" \
        "/opt/homebrew/share/zsh-autosuggestions" \
        "/usr/local/share/zsh-autosuggestions"
    do
        [[ -f "$dir/zsh-autosuggestions.zsh" ]] && source "$dir/zsh-autosuggestions.zsh" && break
    done

    # Syntax Highlighting
    for dir in \
        "$HOME/.nix-profile/share/zsh-syntax-highlighting" \
        "/run/current-system/sw/share/zsh-syntax-highlighting" \
        "/usr/share/zsh/plugins/zsh-syntax-highlighting" \
        "/usr/share/zsh-syntax-highlighting" \
        "/opt/homebrew/share/zsh-syntax-highlighting" \
        "/usr/local/share/zsh-syntax-highlighting"
    do
        [[ -f "$dir/zsh-syntax-highlighting.zsh" ]] && source "$dir/zsh-syntax-highlighting.zsh" && break
    done

    # Completion initialization
    autoload -Uz compinit && compinit
fi

# ==============================================================================
# History Configuration
# ==============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_IGNORE_SPACE         # Don't record entries starting with space
setopt HIST_VERIFY               # Show command before executing from history
setopt SHARE_HISTORY             # Share history between sessions
setopt APPEND_HISTORY            # Append to history file
setopt INC_APPEND_HISTORY        # Add commands as they are typed

# ==============================================================================
# PATH Setup
# ==============================================================================
# Add local bin and claude to PATH
export PATH="$HOME/.local/bin:$HOME/.claude/local:$PATH"

# Configure npm to use home directory for global packages (avoids read-only Nix store)
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# ==============================================================================
# Shell Aliases
# ==============================================================================
# Navigation
alias ll="ls -l"
alias la="ls -la"
alias ..="cd .."
alias ...="cd ../.."

# Git aliases (supplement oh-my-zsh git plugin)
alias gs="git status"
alias gp="git push"
alias gl="git log --oneline --graph"

# Development tools
alias repomix="npx repomix"
alias claude-flow="npx claude-flow@alpha"
alias codebuff="npx codebuff"

# Platform-specific rebuild command
if [[ "$PLATFORM" == "macos" ]]; then
    alias update="$HOME/Work/willgriffin/repos/nixos-config/mac-rebuild"
    alias rebuild="$HOME/Work/willgriffin/repos/nixos-config/mac-rebuild"
else
    alias update="sudo nixos-rebuild switch"
    alias rebuild="sudo nixos-rebuild switch"
fi

# Dotfiles management
if [[ -f /etc/os-release ]] && grep -q "^ID=nixos" /etc/os-release; then
    # NixOS: just pull updates (home-manager manages symlinks)
    alias update-home="cd $HOME/Work/willgriffin/repos/dotfiles && git pull && ./install.sh && cd - > /dev/null"
else
    # Non-NixOS: use stow
    alias update-home="cd $HOME/Work/willgriffin/repos/dotfiles && git pull && stow --restow zsh bash git nushell && cd - > /dev/null"
fi

# ==============================================================================
# Tool Initialization
# ==============================================================================
# Initialize fnm (Fast Node Manager) if available
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# Initialize zoxide if available
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Initialize direnv if available
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# Initialize starship prompt if available (should be last for proper prompt)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# ==============================================================================
# Zellij Auto-Start (for Mosh sessions)
# ==============================================================================
# Auto-start zellij only for mosh sessions (human remote use)
# Local terminals and plain SSH sessions don't get zellij
# Detect mosh by walking up process tree (no MOSH_CONNECTION env var exists)
_is_mosh() {
    local pid=$$
    while [[ $pid -gt 1 ]]; do
        local comm=$(ps -o comm= -p $pid 2>/dev/null)
        [[ "$comm" == *mosh-server* ]] && return 0
        pid=$(ps -o ppid= -p $pid 2>/dev/null | tr -d ' ')
    done
    return 1
}

if [[ -z "$ZELLIJ" && $- == *i* ]] && _is_mosh; then
    zellij attach -c default
fi

# ==============================================================================
# Local Overrides (machine-specific customizations)
# ==============================================================================
# Source local overrides if they exist
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
