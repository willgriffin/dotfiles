#!/usr/bin/env bash
# Dotfiles Installation Script
# Completely self-contained - installs shells, tools, and configs
# Works on macOS, Linux (Debian/Ubuntu, Fedora, Alpine), and containers

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Platform Detection
# ==============================================================================
detect_platform() {
    case "$(uname -s)" in
        Darwin) PLATFORM="macos" ;;
        Linux)  PLATFORM="linux" ;;
        *)      PLATFORM="unknown" ;;
    esac

    if [[ "$PLATFORM" == "linux" ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            DISTRO="$ID"
        elif [[ -f /etc/alpine-release ]]; then
            DISTRO="alpine"
        else
            DISTRO="unknown"
        fi
    fi
}

# ==============================================================================
# Package Installation
# ==============================================================================
install_packages() {
    echo "Installing packages..."

    # Core packages to install
    local packages=(
        zsh
        git
        curl
        stow
    )

    # Optional but recommended packages
    local optional_packages=(
        starship      # prompt
        zoxide        # smart cd
        direnv        # directory environments
        fzf           # fuzzy finder
        bat           # better cat
        eza           # better ls
        ripgrep       # better grep
        fd            # better find
        jq            # json processor
    )

    case "$PLATFORM" in
        macos)
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi

            echo "Installing core packages..."
            brew install "${packages[@]}" 2>/dev/null || true

            echo "Installing optional packages..."
            brew install "${optional_packages[@]}" 2>/dev/null || true

            # Zsh plugins via Homebrew
            brew install zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
            ;;
        linux)
            case "$DISTRO" in
                ubuntu|debian|pop)
                    sudo apt-get update
                    sudo apt-get install -y "${packages[@]}"
                    # Optional packages (some may not be in default repos)
                    sudo apt-get install -y zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
                    sudo apt-get install -y fzf bat ripgrep fd-find jq 2>/dev/null || true
                    # Starship, zoxide, eza need manual install on Debian/Ubuntu
                    install_starship
                    install_zoxide
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y "${packages[@]}"
                    sudo dnf install -y zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
                    sudo dnf install -y fzf bat ripgrep fd-find jq eza 2>/dev/null || true
                    install_starship
                    install_zoxide
                    ;;
                alpine)
                    sudo apk add "${packages[@]}"
                    sudo apk add zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
                    sudo apk add fzf bat ripgrep fd jq 2>/dev/null || true
                    install_starship
                    install_zoxide
                    ;;
                arch|manjaro)
                    sudo pacman -S --noconfirm "${packages[@]}"
                    sudo pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
                    sudo pacman -S --noconfirm starship zoxide fzf bat eza ripgrep fd jq direnv 2>/dev/null || true
                    ;;
                *)
                    echo "Warning: Unknown distro $DISTRO - installing core packages only"
                    echo "Please manually install: ${optional_packages[*]}"
                    ;;
            esac
            ;;
    esac
}

install_starship() {
    if command -v starship &> /dev/null; then
        echo "Starship already installed"
        return 0
    fi
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_zoxide() {
    if command -v zoxide &> /dev/null; then
        echo "Zoxide already installed"
        return 0
    fi
    echo "Installing Zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

# ==============================================================================
# AI CLI Tools
# ==============================================================================
install_claude_code() {
    if [[ -x "$HOME/.claude/local/claude" ]] || command -v claude &> /dev/null; then
        echo "Claude Code already installed"
        return 0
    fi
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
}

install_gemini_cli() {
    if command -v gemini &> /dev/null; then
        echo "Gemini CLI already installed"
        return 0
    fi
    echo "Installing Gemini CLI..."
    npm install -g @google/gemini-cli
}

# ==============================================================================
# Stow Packages
# ==============================================================================
stow_packages() {
    cd "$DOTFILES_DIR"

    local packages=(
        "zsh"
        "bash"
        "nushell"
        "git"
    )

    echo "Stowing dotfiles to home directory..."

    for pkg in "${packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            echo "  Stowing $pkg..."
            # --adopt takes ownership of existing files, --restow re-links
            stow -v --adopt --restow --target="$HOME" "$pkg" 2>&1 | grep -v "^LINK:" || true
        fi
    done
}

# ==============================================================================
# Backup Existing Configs
# ==============================================================================
backup_existing() {
    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    local need_backup=false

    local files_to_check=(
        ".zshrc"
        ".bashrc"
        ".config/nushell/config.nu"
        ".config/nushell/env.nu"
        ".gitconfig"
    )

    for file in "${files_to_check[@]}"; do
        local target="$HOME/$file"
        if [[ -e "$target" && ! -L "$target" ]]; then
            need_backup=true
            break
        fi
    done

    if [[ "$need_backup" == true ]]; then
        echo "Backing up existing config files to $backup_dir..."
        mkdir -p "$backup_dir"

        for file in "${files_to_check[@]}"; do
            local target="$HOME/$file"
            if [[ -e "$target" && ! -L "$target" ]]; then
                local backup_path="$backup_dir/$file"
                mkdir -p "$(dirname "$backup_path")"
                mv "$target" "$backup_path"
                echo "  Backed up: $file"
            fi
        done
    fi
}

# ==============================================================================
# Set Default Shell
# ==============================================================================
set_default_shell() {
    local zsh_path
    zsh_path=$(which zsh)

    if [[ "$SHELL" != "$zsh_path" ]]; then
        echo ""
        read -p "Set zsh as default shell? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! grep -q "$zsh_path" /etc/shells; then
                echo "$zsh_path" | sudo tee -a /etc/shells
            fi
            chsh -s "$zsh_path"
            echo "Default shell changed to zsh. Log out and back in for it to take effect."
        fi
    fi
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    echo "========================================"
    echo "Dotfiles Installation"
    echo "========================================"
    echo

    detect_platform
    echo "Platform: $PLATFORM"
    [[ -n "$DISTRO" ]] && echo "Distro: $DISTRO"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo

    # Install packages
    install_packages
    echo

    # Install AI CLI tools
    install_claude_code
    install_gemini_cli
    echo

    # Backup existing configs
    backup_existing
    echo

    # Stow packages
    stow_packages
    echo

    # Offer to set default shell
    set_default_shell

    echo
    echo "========================================"
    echo "Installation complete!"
    echo "========================================"
    echo
    echo "Start a new zsh session:"
    echo "  zsh"
    echo
    echo "Or restart your terminal."
}

main "$@"
