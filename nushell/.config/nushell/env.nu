# ~/.config/nushell/env.nu - Nushell Environment Configuration
# Managed by dotfiles repo, works on NixOS, macOS, Linux, and containers

# ==============================================================================
# Environment Variables
# ==============================================================================

# PNPM environment setup
$env.PNPM_HOME = ($env.HOME | path join ".local/share/pnpm")

# Configure npm to use home directory for global packages (avoids read-only Nix store)
$env.NPM_CONFIG_PREFIX = ($env.HOME | path join ".npm-global")

# ==============================================================================
# Platform-Specific Environment
# ==============================================================================
let platform = (sys host | get name)

if $platform == "Linux" {
    # Playwright environment setup (Linux only - macOS uses system browsers)
    # Only set if chromium is available
    let chromium_path = (which chromium | get 0?.path? | default "")
    if $chromium_path != "" {
        $env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1"
        $env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = $chromium_path
        $env.PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true"
    }
}

# ==============================================================================
# Starship Prompt (if available)
# ==============================================================================
# Configure starship prompt if available
let starship_path = (which starship | get 0?.path? | default "")
if $starship_path != "" {
    mkdir ~/.cache/starship
    starship init nu | save -f ~/.cache/starship/init.nu
}
