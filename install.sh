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

    # Cloud CLI tools
    local cloud_packages=(
        gh            # GitHub CLI
        awscli        # AWS CLI (awscli2 on some distros)
    )

    case "$PLATFORM" in
        macos)
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Add brew to PATH for current session
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi

            echo "Installing core packages..."
            brew install "${packages[@]}" 2>/dev/null || true

            echo "Installing optional packages..."
            brew install "${optional_packages[@]}" 2>/dev/null || true

            # Cloud CLI tools
            echo "Installing cloud CLI tools..."
            brew install gh awscli 2>/dev/null || true
            # gcloud via cask
            brew install --cask google-cloud-sdk 2>/dev/null || true

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
                    sudo apt-get install -y fzf bat ripgrep fd-find jq unzip 2>/dev/null || true
                    # Starship, zoxide need manual install on Debian/Ubuntu
                    install_starship
                    install_zoxide
                    # Cloud CLI tools
                    install_gh
                    install_awscli
                    install_gcloud
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y "${packages[@]}"
                    sudo dnf install -y zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
                    sudo dnf install -y fzf bat ripgrep fd-find jq eza unzip 2>/dev/null || true
                    install_starship
                    install_zoxide
                    # Cloud CLI tools
                    install_gh
                    install_awscli
                    install_gcloud
                    ;;
                alpine)
                    sudo apk add "${packages[@]}"
                    sudo apk add zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
                    sudo apk add fzf bat ripgrep fd jq unzip 2>/dev/null || true
                    install_starship
                    install_zoxide
                    # Cloud CLI tools
                    sudo apk add github-cli aws-cli 2>/dev/null || true
                    install_gcloud
                    ;;
                arch|manjaro)
                    sudo pacman -S --noconfirm "${packages[@]}"
                    sudo pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
                    sudo pacman -S --noconfirm starship zoxide fzf bat eza ripgrep fd jq direnv 2>/dev/null || true
                    # Cloud CLI tools
                    sudo pacman -S --noconfirm github-cli aws-cli 2>/dev/null || true
                    install_gcloud
                    ;;
                nixos)
                    echo "NixOS detected - packages managed by Nix, skipping system package installation"
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

install_gcloud() {
    if command -v gcloud &> /dev/null; then
        echo "Google Cloud SDK already installed"
        return 0
    fi
    echo "Installing Google Cloud SDK..."
    curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
    # Add to path for current session
    export PATH="$HOME/google-cloud-sdk/bin:$PATH"
}

install_awscli() {
    if command -v aws &> /dev/null; then
        echo "AWS CLI already installed"
        return 0
    fi
    echo "Installing AWS CLI..."
    if [[ "$PLATFORM" == "linux" ]]; then
        curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
        unzip -q /tmp/awscliv2.zip -d /tmp
        sudo /tmp/aws/install
        rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
}

install_gh() {
    if command -v gh &> /dev/null; then
        echo "GitHub CLI already installed"
        return 0
    fi
    echo "Installing GitHub CLI..."
    case "$DISTRO" in
        ubuntu|debian|pop)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update && sudo apt-get install -y gh
            ;;
        fedora|rhel|centos)
            sudo dnf install -y gh 2>/dev/null || true
            ;;
        *)
            echo "Please install gh manually: https://cli.github.com/"
            ;;
    esac
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
    # Check ~/.npm-global/bin as well (our custom prefix)
    if [[ -x "$HOME/.npm-global/bin/gemini" ]]; then
        echo "Gemini CLI already installed"
        return 0
    fi
    echo "Installing Gemini CLI..."
    # Use custom prefix to avoid read-only nix store issues
    mkdir -p "$HOME/.npm-global"
    npm install -g --prefix "$HOME/.npm-global" @google/gemini-cli
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh already installed"
    else
        echo "Installing Oh My Zsh..."
        # --unattended: don't change shell, --keep-zshrc: don't overwrite .zshrc
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    fi

    # Install oh-my-zsh plugins
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        echo "Installing zsh-autosuggestions plugin..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        echo "Installing zsh-syntax-highlighting plugin..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
}

# ==============================================================================
# Stow Packages
# ==============================================================================
stow_packages() {
    cd "$DOTFILES_DIR"

    local packages=(
        "zsh"
        "bash"
        "git"
        "starship"
    )

    # nushell managed by home-manager on NixOS
    if [[ "$DISTRO" != "nixos" ]]; then
        packages+=("nushell")
    fi

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
    # Skip on NixOS - shell configured in system config
    if [[ "$DISTRO" == "nixos" ]]; then
        return 0
    fi

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

    # Install Oh My Zsh
    install_oh_my_zsh
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
