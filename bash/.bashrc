# ~/.bashrc - Portable Bash Configuration
# Managed by dotfiles repo, works on NixOS, macOS, Linux, and containers
#
# Note: Bash is typically the login shell for agents/automation.
# Interactive human sessions exec into zsh for a richer experience.

# ==============================================================================
# Platform Detection
# ==============================================================================
case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)      PLATFORM="unknown" ;;
esac

# ==============================================================================
# PATH Setup
# ==============================================================================
# Add ~/.local/bin to PATH (for locally installed tools like claude-code)
export PATH="$HOME/.local/bin:$PATH"

# Configure npm to use home directory for global packages (avoids read-only Nix store)
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

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
# Interactive Shell Detection and Zsh Exec
# ==============================================================================
# Detect mosh by walking up process tree
_is_mosh() {
    local pid=$$
    while [[ $pid -gt 1 ]]; do
        local comm=$(ps -o comm= -p $pid 2>/dev/null)
        [[ "$comm" == *mosh-server* ]] && return 0
        pid=$(ps -o ppid= -p $pid 2>/dev/null | tr -d ' ')
    done
    return 1
}

# Mosh sessions or local terminals: exec into zsh for human-friendly shell
# Only plain SSH sessions (agents) stay in bash
if [[ $- == *i* ]] && { _is_mosh || [[ -z "$SSH_CONNECTION" ]]; }; then
    # Only exec into zsh if it's available
    if command -v zsh &> /dev/null; then
        exec zsh
    fi
fi

# ==============================================================================
# If we're still in bash (SSH agent sessions), provide basic aliases
# ==============================================================================
alias ll="ls -l"
alias la="ls -la"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"

# Dotfiles management
alias update-home="cd $HOME/Work/willgriffin/repos/dotfiles && stow --restow zsh bash git nushell && cd - > /dev/null"

# ==============================================================================
# Local Overrides (machine-specific customizations)
# ==============================================================================
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
