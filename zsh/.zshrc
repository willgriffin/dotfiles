# Skip heavy plugins if running inside a coding agent
if [[ "$TERM_PROGRAM" == "vscode" || -n "$ANTIGRAVITY_AGENT" ]]; then
  export PS1='$ '
  return
fi

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
# Homebrew (macOS)
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Add local bin and agent CLIs to PATH
export PATH="$HOME/.local/bin:$HOME/.claude/local:$PATH"

export PR_REVIEW_DIR="${PR_REVIEW_DIR:-$HOME/Work/happyvertical/repos/pr-review}"
if [[ -d "$PR_REVIEW_DIR/bin" ]]; then
    export PATH="$PR_REVIEW_DIR/bin:$PATH"
fi

# PostgreSQL client tools (keg-only on macOS)
if [[ -d /opt/homebrew/opt/libpq/bin ]]; then
    export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
fi

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
    # NixOS: run the installer to pick up new CLI tools and config changes
    alias update-home="cd $HOME/Work/willgriffin/repos/dotfiles && git pull && ./install.sh && cd - > /dev/null"
else
    # Non-NixOS: rerun the installer so new packages and AI CLIs are provisioned
    alias update-home="cd $HOME/Work/willgriffin/repos/dotfiles && git pull && ./install.sh && cd - > /dev/null"
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
# Claude Code — alternate model providers
# ==============================================================================
# Non-shadowing launchers that run the real `claude` binary against an
# Anthropic-compatible third-party endpoint. Plain `claude` stays on your
# Anthropic subscription. Provider tokens come from sops via /run/secrets,
# provisioned by nixos-config (hosts/mac/default.nix -> darwin-rebuild).

# Read a provisioned provider secret, or explain how to provision it.
_cc_secret() {
    local f="/run/secrets/cli_keys/$1"
    if [[ ! -r "$f" ]]; then
        print -u2 "claude-models: $f not found or unreadable."
        print -u2 "  Provision it: cd ~/Work/willgriffin/repos/nixos-config && sudo darwin-rebuild switch --flake .#mac"
        return 1
    fi
    cat "$f"
}

# Z.AI GLM (glm-4.6 / glm-4.5-air)
claudeglm() {
    local tok; tok="$(_cc_secret zai_api_key)" || return 1
    (
        unset ANTHROPIC_API_KEY
        export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$tok"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.6"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.6"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
        exec claude "$@"
    )
}

# Moonshot Kimi for Coding
claudekimi() {
    local tok; tok="$(_cc_secret kimi_api_key)" || return 1
    (
        unset ANTHROPIC_API_KEY
        export ANTHROPIC_BASE_URL="https://api.kimi.com/coding/"
        export ANTHROPIC_AUTH_TOKEN="$tok"
        export ANTHROPIC_MODEL="kimi-for-coding"
        export ANTHROPIC_SMALL_FAST_MODEL="kimi-for-coding"
        exec claude "$@"
    )
}

# Qwen (Alibaba token-plan MaaS, Anthropic-compatible)
claudeqwen() {
    local tok; tok="$(_cc_secret qwen_api_key)" || return 1
    (
        unset ANTHROPIC_API_KEY
        export ANTHROPIC_BASE_URL="https://token-plan.ap-southeast-1.maas.aliyuncs.com/apps/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$tok"
        export ANTHROPIC_MODEL="qwen3.8-max-preview"
        export ANTHROPIC_SMALL_FAST_MODEL="qwen3.8-max-preview"
        exec claude "$@"
    )
}

# HappyVertical Bifrost gateway (virtual key). Model must be provider-prefixed;
# override with BIFROST_MODEL=<provider/model>. Requires a provisioned coding vk.
claudebifrost() {
    local tok; tok="$(_cc_secret bifrost_virtual_key)" || return 1
    if [[ "$tok" == REPLACE_ME_* ]]; then
        print -u2 "claudebifrost: bifrost_virtual_key is still a placeholder."
        print -u2 "  Provision a coding virtual key in iac/bifrost, store it in sops"
        print -u2 "  (cli_keys/bifrost_virtual_key), then run darwin-rebuild."
        return 1
    fi
    (
        unset ANTHROPIC_API_KEY
        export ANTHROPIC_BASE_URL="https://bifrost.happyvertical.com/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$tok"
        export ANTHROPIC_MODEL="${BIFROST_MODEL:-anthropic/claude-sonnet-4-6}"
        exec claude "$@"
    )
}

# List the available launchers.
claude-models() {
    print -r -- 'Claude Code model launchers (plain `claude` = Anthropic subscription):'
    print -r -- '  claudeglm      Z.AI GLM           glm-4.6 / glm-4.5-air'
    print -r -- '  claudekimi     Moonshot Kimi      kimi-for-coding'
    print -r -- '  claudeqwen     Qwen (token-plan)  qwen3.8-max-preview'
    print -r -- '  claudebifrost  Bifrost gateway    ${BIFROST_MODEL:-anthropic/claude-sonnet-4-6}'
}

# ==============================================================================
# Local Overrides (machine-specific customizations)
# ==============================================================================
# Source local overrides if they exist
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Added by Antigravity
export PATH="/Users/will/.antigravity/antigravity/bin:$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# Context Forge org memory token (rehydrated from Keychain for terminal sessions)
export HV_CONTEXTFORGE_MCP_TOKEN="$(security find-generic-password -a "$USER" -s happyvertical-contextforge-codex-mcp -w 2>/dev/null)"

# bun
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
if [[ -d "$BUN_INSTALL/bin" ]]; then
    # Move ~/.bun/bin to the front, dropping any earlier (inherited) occurrence
    path=("$BUN_INSTALL/bin" ${path:#"$BUN_INSTALL/bin"})
fi

# bun completions
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
