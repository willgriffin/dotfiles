#!/usr/bin/env bash
# Dotfiles Installation Script
# Completely self-contained - installs shells, tools, and configs
# Works on macOS, Linux (Debian/Ubuntu, Fedora, Alpine), and containers

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

usage() {
	cat <<'EOF'
Usage: ./install.sh [--dry-run|--audit] [-h|--help]

Installs workstation tooling, shells, CLI tools, and personal dotfiles.

Options:
  --dry-run, --audit  Report platform/install intent without changing packages,
                      symlinks, or generated files.
  -h, --help          Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run | --audit)
		DRY_RUN=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
done

# ==============================================================================
# Platform Detection
# ==============================================================================
detect_platform() {
	case "$(uname -s)" in
	Darwin) PLATFORM="macos" ;;
	Linux) PLATFORM="linux" ;;
	*) PLATFORM="unknown" ;;
	esac

	if [[ "$PLATFORM" == "linux" ]]; then
		if [[ -f /etc/os-release ]]; then
			# Platform file is present only on Linux.
			# shellcheck disable=SC1091
			. /etc/os-release
			DISTRO="$ID"
		elif [[ -f /etc/alpine-release ]]; then
			DISTRO="alpine"
		else
			DISTRO="unknown"
		fi
	fi
}

run_privileged() {
	if [[ "$(id -u)" -eq 0 ]]; then
		"$@"
		return $?
	fi

	if command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
		sudo -n "$@"
		return $?
	fi

	echo "Skipping privileged command (sudo unavailable or requires a password): $*"
	return 0
}

can_run_privileged() {
	[[ "$(id -u)" -eq 0 ]] || (command -v sudo &>/dev/null && sudo -n true 2>/dev/null)
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
		starship # prompt
		zoxide   # smart cd
		direnv   # directory environments
		fzf      # fuzzy finder
		bat      # better cat
		eza      # better ls
		ripgrep  # better grep
		fd       # better find
		jq       # json processor
	)

	case "$PLATFORM" in
	macos)
		if ! command -v brew &>/dev/null; then
			echo "Installing Homebrew..."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
			# Add brew to PATH for current session
			eval "$(/opt/homebrew/bin/brew shellenv)"
		fi

		echo "Installing core packages..."
		brew install "${packages[@]}" 2>/dev/null || true

		echo "Installing optional packages..."
		brew install "${optional_packages[@]}" 2>/dev/null || true

		# PostgreSQL client tools (psql, pg_dump, etc.)
		brew install libpq 2>/dev/null || true

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
		ubuntu | debian | pop)
			run_privileged apt-get update
			run_privileged apt-get install -y "${packages[@]}"
			# Optional packages (some may not be in default repos)
			run_privileged apt-get install -y zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
			run_privileged apt-get install -y fzf bat ripgrep fd-find jq unzip 2>/dev/null || true
			# Starship, zoxide need manual install on Debian/Ubuntu
			install_starship
			install_zoxide
			# Cloud CLI tools
			install_gh
			install_awscli
			install_gcloud
			;;
		fedora | rhel | centos)
			run_privileged dnf install -y "${packages[@]}"
			run_privileged dnf install -y zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
			run_privileged dnf install -y fzf bat ripgrep fd-find jq eza unzip 2>/dev/null || true
			install_starship
			install_zoxide
			# Cloud CLI tools
			install_gh
			install_awscli
			install_gcloud
			;;
		alpine)
			run_privileged apk add "${packages[@]}"
			run_privileged apk add zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
			run_privileged apk add fzf bat ripgrep fd jq unzip 2>/dev/null || true
			install_starship
			install_zoxide
			# Cloud CLI tools
			run_privileged apk add github-cli aws-cli 2>/dev/null || true
			install_gcloud
			;;
		arch | manjaro)
			run_privileged pacman -S --noconfirm "${packages[@]}"
			run_privileged pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
			run_privileged pacman -S --noconfirm starship zoxide fzf bat eza ripgrep fd jq direnv unzip 2>/dev/null || true
			# Cloud CLI tools
			run_privileged pacman -S --noconfirm github-cli aws-cli 2>/dev/null || true
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

install_sops_tools() {
	echo "Installing SOPS tooling..."

	case "$PLATFORM" in
	macos)
		brew install sops age gnupg 2>/dev/null || true
		;;
	linux)
		case "$DISTRO" in
		ubuntu | debian | pop)
			run_privileged apt-get install -y age gnupg 2>/dev/null || true
			run_privileged apt-get install -y sops 2>/dev/null || true
			;;
		fedora | rhel | centos)
			run_privileged dnf install -y age gnupg2 sops 2>/dev/null || true
			;;
		alpine)
			run_privileged apk add age gnupg sops 2>/dev/null || true
			;;
		arch | manjaro)
			run_privileged pacman -S --noconfirm age gnupg sops 2>/dev/null || true
			;;
		nixos)
			echo "NixOS detected - SOPS tooling should be managed by Nix"
			;;
		esac
		;;
	esac

	if command -v sops &>/dev/null; then
		echo "SOPS available: $(command -v sops)"
	else
		echo "SOPS not found after package install; configure it via your platform package manager."
	fi
}

install_starship() {
	if command -v starship &>/dev/null; then
		echo "Starship already installed"
		return 0
	fi
	echo "Installing Starship..."
	curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_zoxide() {
	if command -v zoxide &>/dev/null; then
		echo "Zoxide already installed"
		return 0
	fi
	echo "Installing Zoxide..."
	curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

install_gcloud() {
	if command -v gcloud &>/dev/null; then
		echo "Google Cloud SDK already installed"
		return 0
	fi
	echo "Installing Google Cloud SDK..."
	curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
	# Add to path for current session
	export PATH="$HOME/google-cloud-sdk/bin:$PATH"
}

install_awscli() {
	if command -v aws &>/dev/null; then
		echo "AWS CLI already installed"
		return 0
	fi
	echo "Installing AWS CLI..."
	if [[ "$PLATFORM" == "linux" ]]; then
		curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
		unzip -q /tmp/awscliv2.zip -d /tmp
		run_privileged /tmp/aws/install
		rm -rf /tmp/awscliv2.zip /tmp/aws
	fi
}

install_gh() {
	if command -v gh &>/dev/null; then
		echo "GitHub CLI already installed"
		return 0
	fi
	echo "Installing GitHub CLI..."
	case "$DISTRO" in
	ubuntu | debian | pop)
		if can_run_privileged; then
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | run_privileged dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | run_privileged tee /etc/apt/sources.list.d/github-cli.list >/dev/null
			run_privileged apt-get update && run_privileged apt-get install -y gh
		else
			echo "Skipping gh apt setup; root/sudo is not available noninteractively."
		fi
		;;
	fedora | rhel | centos)
		run_privileged dnf install -y gh 2>/dev/null || true
		;;
	*)
		echo "Please install gh manually: https://cli.github.com/"
		;;
	esac
}

install_bun() {
	# NixOS manages packages via Nix; prebuilt bun binaries cannot run there
	if [[ "$DISTRO" == "nixos" ]]; then
		echo "NixOS detected - bun and omp should be managed by Nix"
		return 0
	fi

	export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

	if [[ -x "$BUN_INSTALL/bin/bun" ]]; then
		echo "Upgrading bun to latest..."
		"$BUN_INSTALL/bin/bun" upgrade || echo "bun upgrade failed; continuing"
	elif command -v bun &>/dev/null; then
		echo "bun found at $(command -v bun) (externally managed), skipping upgrade"
	else
		echo "Installing bun..."
		curl -fsSL https://bun.sh/install | bash || echo "bun install failed; install manually from https://bun.sh"
	fi

	# Make bun available for the rest of this install run
	if [[ -d "$BUN_INSTALL/bin" ]] && [[ ":$PATH:" != *":$BUN_INSTALL/bin:"* ]]; then
		export PATH="$BUN_INSTALL/bin:$PATH"
	fi
}

ensure_npm() {
	if command -v npm &>/dev/null; then
		return 0
	fi

	echo "Installing Node.js and npm..."
	case "$PLATFORM" in
	macos)
		brew install node
		;;
	linux)
		case "$DISTRO" in
		ubuntu | debian | pop)
			run_privileged apt-get update
			run_privileged apt-get install -y nodejs npm
			;;
		fedora | rhel | centos)
			run_privileged dnf install -y nodejs npm
			;;
		alpine)
			run_privileged apk add nodejs npm
			;;
		arch | manjaro)
			run_privileged pacman -S --noconfirm nodejs npm
			;;
		nixos)
			echo "NixOS detected - Node.js and npm should be managed by Nix"
			return 1
			;;
		*)
			echo "Please install Node.js and npm manually"
			return 1
			;;
		esac
		;;
	*)
		echo "Please install Node.js and npm manually"
		return 1
		;;
	esac

	if ! command -v npm &>/dev/null; then
		echo "npm still not available after install attempt"
		return 1
	fi
}

ensure_agent_paths() {
	export NPM_CONFIG_PREFIX="$HOME/.npm-global"

	if [[ -d "$HOME/.npm-global/bin" ]] && [[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]]; then
		export PATH="$HOME/.npm-global/bin:$PATH"
	fi

	if [[ -d "$HOME/.claude/local" ]] && [[ ":$PATH:" != *":$HOME/.claude/local:"* ]]; then
		export PATH="$HOME/.claude/local:$PATH"
	fi

}

# ==============================================================================
# AI CLI Tools
# ==============================================================================
install_omp() {
	if ! command -v bun &>/dev/null; then
		echo "bun not available, skipping omp (install bun first)"
		return 0
	fi

	if command -v omp &>/dev/null; then
		echo "Upgrading omp to latest..."
	else
		echo "Installing omp (oh-my-pi)..."
	fi
	bun install -g @oh-my-pi/pi-coding-agent@latest || echo "omp install failed; retry manually: bun install -g @oh-my-pi/pi-coding-agent@latest"
}

install_codex_cli() {
	ensure_agent_paths

	if command -v codex &>/dev/null || [[ -x "$HOME/.npm-global/bin/codex" ]]; then
		echo "Codex CLI already installed"
		return 0
	fi

	ensure_npm

	echo "Installing Codex CLI..."
	mkdir -p "$HOME/.npm-global"
	npm install -g --prefix "$HOME/.npm-global" @openai/codex
	ensure_agent_paths
}

install_claude_code() {
	if [[ -x "$HOME/.claude/local/claude" ]] || command -v claude &>/dev/null; then
		echo "Claude Code already installed"
		return 0
	fi
	echo "Installing Claude Code..."
	curl -fsSL https://claude.ai/install.sh | bash
}

install_copilot_cli() {
	if ! command -v gh &>/dev/null; then
		echo "GitHub CLI not installed, skipping Copilot CLI"
		return 0
	fi

	if ! gh auth status &>/dev/null; then
		echo "GitHub CLI not authenticated, skipping Copilot CLI"
		return 0
	fi

	if ! gh copilot --help &>/dev/null; then
		echo "This gh version does not support 'gh copilot', skipping Copilot CLI"
		return 0
	fi

	echo "Installing GitHub Copilot CLI..."
	if gh copilot -- --version &>/dev/null; then
		echo "GitHub Copilot CLI installed"
	else
		echo "Could not install GitHub Copilot CLI"
	fi
}

install_gemini_cli() {
	ensure_agent_paths

	if command -v gemini &>/dev/null; then
		echo "Gemini CLI already installed"
		return 0
	fi
	# Check ~/.npm-global/bin as well (our custom prefix)
	if [[ -x "$HOME/.npm-global/bin/gemini" ]]; then
		echo "Gemini CLI already installed"
		return 0
	fi

	ensure_npm

	echo "Installing Gemini CLI..."
	# Use custom prefix to avoid read-only nix store issues
	mkdir -p "$HOME/.npm-global"
	npm install -g --prefix "$HOME/.npm-global" @google/gemini-cli
	ensure_agent_paths
}

install_pi_cli() {
	ensure_agent_paths

	if command -v pi &>/dev/null || [[ -x "$HOME/.npm-global/bin/pi" ]]; then
		echo "Pi coding agent already installed"
		return 0
	fi

	ensure_npm

	echo "Installing Pi coding agent..."
	mkdir -p "$HOME/.npm-global"
	# --ignore-scripts per upstream's documented install command (pi.dev)
	npm install -g --ignore-scripts --prefix "$HOME/.npm-global" @earendil-works/pi-coding-agent
	ensure_agent_paths
}

install_kimi_code() {
	if command -v kimi &>/dev/null; then
		echo "Kimi Code already installed"
	else
		echo "Installing Kimi Code..."
		curl -LsSf https://code.kimi.com/install.sh | bash
	fi

	# Add chrome-devtools MCP server
	if command -v kimi &>/dev/null; then
		echo "Adding chrome-devtools MCP server to Kimi..."
		kimi mcp add --transport stdio chrome-devtools -- npx chrome-devtools-mcp@latest 2>/dev/null || true
	fi
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
		"direnv"
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

	local backup_dir
	backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
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

	if [[ "${DOTFILES_NONINTERACTIVE:-1}" == "1" || ! -t 0 ]]; then
		echo "Skipping default shell prompt (noninteractive install)."
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
	[[ "$DRY_RUN" -eq 1 ]] && echo "Mode: dry-run"
	echo

	if [[ "$DRY_RUN" -eq 1 ]]; then
		echo "Dry-run: would install packages, AI CLIs, shell tooling, and stowed dotfiles."
		echo
		echo "Core tools: zsh git curl stow starship zoxide direnv fzf bat eza ripgrep fd jq bun"
		echo "AI CLIs: omp codex claude copilot gemini kimi pi"
		echo "Package mutation, downloads, shell changes, and stow operations skipped."
		echo "Dry-run complete!"
		echo "========================================"
		return 0
	fi

	# Install packages
	install_packages
	install_sops_tools
	install_bun
	echo

	# Install AI CLI tools
	install_omp
	install_codex_cli
	install_claude_code
	install_copilot_cli
	install_kimi_code
	install_gemini_cli
	install_pi_cli
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
