# ~/.zshrc - Portable Zsh Configuration
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
# Zsh Plugins (sourced from various possible locations)
# ==============================================================================
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

# ==============================================================================
# PATH Setup
# ==============================================================================
# Add local bin to PATH (for locally installed tools like claude-code)
export PATH="$HOME/.local/bin:$PATH"

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

# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph"

# Development tools
alias repomix="npx repomix"
alias claude-flow="npx claude-flow@alpha"
alias codebuff="npx codebuff"

# Claude command (local installation)
alias claude="~/.claude/local/claude"

# Platform-specific rebuild command
if [[ "$PLATFORM" == "macos" ]]; then
    alias update="$HOME/Work/willgriffin/repos/nixos-config/mac-rebuild"
    alias rebuild="$HOME/Work/willgriffin/repos/nixos-config/mac-rebuild"
else
    alias update="sudo nixos-rebuild switch"
    alias rebuild="sudo nixos-rebuild switch"
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
# Platform-Specific Configuration
# ==============================================================================
if [[ "$PLATFORM" == "linux" ]]; then
    # Source global environment variables from secrets (NixOS only)
    if command -v source-global-env &> /dev/null; then
        ENV_FILE=$(source-global-env)
        if [[ -f "$ENV_FILE" ]]; then
            source "$ENV_FILE"
            rm "$ENV_FILE"  # Clean up the temporary file
        fi
    fi
fi

# ==============================================================================
# Local Overrides (machine-specific customizations)
# ==============================================================================
# Source local overrides if they exist
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
