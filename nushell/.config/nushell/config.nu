# ~/.config/nushell/config.nu - Nushell Interactive Configuration
# Managed by dotfiles repo, works on NixOS, macOS, Linux, and containers

# ==============================================================================
# Platform Detection
# ==============================================================================
let platform = (sys host | get name)

# ==============================================================================
# Shell Aliases
# ==============================================================================
# Navigation
alias ll = ls -l
alias la = ls -la

# Git aliases
alias gs = git status
alias ga = git add
alias gc = git commit
alias gp = git push
alias gl = git log --oneline --graph

# Development tools
alias repomix = npx repomix
alias claude-flow = npx claude-flow@alpha
alias codebuff = npx codebuff

# Claude command (local installation)
alias claude = ~/.claude/local/claude

# Platform-specific rebuild command
def update [] {
    let platform = (sys host | get name)
    if $platform == "Darwin" {
        run-external ($env.HOME | path join "Work/willgriffin/repos/nixos-config/mac-rebuild")
    } else {
        sudo nixos-rebuild switch
    }
}

def rebuild [] {
    update
}

# Dotfiles management
def update-home [] {
    cd ($env.HOME | path join "Work/willgriffin/repos/dotfiles")
    stow --restow zsh bash git nushell
    cd -
}

# ==============================================================================
# PATH Management
# ==============================================================================
# Add ~/.local/bin to PATH (for locally installed tools like claude-code)
let local_bin = ($env.HOME | path join ".local/bin")
if ($local_bin not-in $env.PATH) {
    $env.PATH = ($env.PATH | prepend $local_bin)
}

# Add PNPM to PATH if not already present
if ($env.PNPM_HOME not-in $env.PATH) {
    $env.PATH = ($env.PATH | prepend $env.PNPM_HOME)
}

# Add npm global packages to PATH
let npm_bin = ($env.HOME | path join ".npm-global/bin")
if ($npm_bin not-in $env.PATH) {
    $env.PATH = ($env.PATH | prepend $npm_bin)
}

# ==============================================================================
# Tool Initialization
# ==============================================================================
# Initialize fnm (Fast Node Manager) if available
if (which fnm | is-not-empty) {
    fnm env --shell nushell | save -f ~/.fnm-env.nu
    source ~/.fnm-env.nu
}

# Initialize zoxide if available
if (which zoxide | is-not-empty) {
    zoxide init nushell | save -f ~/.zoxide.nu
    source ~/.zoxide.nu
}

# Initialize direnv if available
if (which direnv | is-not-empty) {
    $env.config = ($env.config? | default {} | merge {
        hooks: {
            pre_prompt: [{ ||
                if (which direnv | is-not-empty) {
                    direnv export json | from json | default {} | load-env
                }
            }]
        }
    })
}

# Source starship init if it was created in env.nu
let starship_init = ($env.HOME | path join ".cache/starship/init.nu")
if ($starship_init | path exists) {
    source ~/.cache/starship/init.nu
}

# ==============================================================================
# Platform-Specific Configuration
# ==============================================================================
if $platform == "Linux" {
    # Source global environment variables from secrets (NixOS only)
    if (which source-global-env | is-not-empty) {
        let env_file = (source-global-env)
        if ($env_file | path exists) {
            source $env_file
            rm $env_file  # Clean up the temporary file
        }
    }
}

# ==============================================================================
# Local Overrides (machine-specific customizations)
# ==============================================================================
let local_config = ($env.HOME | path join ".config/nushell/local.nu")
if ($local_config | path exists) {
    source ~/.config/nushell/local.nu
}
