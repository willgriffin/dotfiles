# Dotfiles

Portable CLI configuration that works across NixOS, macOS, Linux distros, and containers.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/willgriffin/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer (packages, AI CLIs, and config symlinks)
./install.sh
```

## Structure

```
dotfiles/
├── agent/
│   └── manifest.json       # Agent workflow manifest for org bootstraps
├── .agents/                # Cross-agent workflow defaults
│   ├── commands/
│   └── skills/
├── .codex/                 # Codex defaults
│   └── AGENTS.md
├── zsh/                    # Zsh configuration
│   └── .zshrc
├── bash/                   # Bash configuration
│   └── .bashrc
├── nushell/                # Nushell configuration
│   └── .config/nushell/
│       ├── config.nu
│       └── env.nu
├── git/                    # Git configuration
│   └── .gitconfig
└── starship/               # Starship prompt (optional)
    └── .config/starship.toml
```

## How It Works

### On Non-Nix Systems (Ubuntu, macOS, Containers)

Uses [GNU Stow](https://www.gnu.org/software/stow/) to create symlinks:

```bash
./install.sh
# or manually:
stow zsh bash nushell git
```

To pick up new workstation dependencies later, use `update-home` or rerun `./install.sh`.

Agent workflow definitions live in this repo as generic personal defaults, but
`install.sh` does not install them directly. Organization bootstraps can consume
`agent/manifest.json` and layer their own standards over these defaults.

Audit without mutating packages or links:

```bash
./install.sh --dry-run
```

### On NixOS

The NixOS config uses `mkOutOfStoreSymlink` to point to this dotfiles repo:

```nix
home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink
  "${config.home.homeDirectory}/dotfiles/zsh/.zshrc";
```

This means:
- Edit files in `~/dotfiles/` directly
- Changes apply immediately (no `nixos-rebuild` needed for config tweaks)
- Package installation still managed by Nix

## Local Overrides

For machine-specific customizations, create local override files:

- `~/.zshrc.local` - Zsh overrides
- `~/.bashrc.local` - Bash overrides
- `~/.gitconfig.local` - Git overrides (signing keys, work email, etc.)
- `~/.config/nushell/local.nu` - Nushell overrides

These files are sourced at the end of the main configs.

## Platform Support

| Feature | NixOS | macOS | Linux | Containers |
|---------|-------|-------|-------|------------|
| Symlink method | mkOutOfStoreSymlink | stow | stow | stow |
| Package install | home-manager | brew/nix | apt/dnf | apk |
| Secrets | source-global-env | N/A | N/A | N/A |
| Rebuild alias | `nixos-rebuild` | `mac-rebuild` | `nixos-rebuild` | N/A |

## Included Aliases

### Navigation
- `ll` - `ls -l`
- `la` - `ls -la`
- `..` - `cd ..`
- `...` - `cd ../..`

### Git
- `gs` - `git status`
- `ga` - `git add`
- `gc` - `git commit`
- `gp` - `git push`
- `gl` - `git log --oneline --graph`

### Development
- `repomix` - `npx repomix`
- `claude` - `~/.claude/local/claude`
- `codex` - installed with npm into `~/.npm-global/bin`
- `gh copilot` - downloads the GitHub Copilot CLI via GitHub CLI
- `sops` / `age` / `gnupg` - local encrypted environment tooling where available
- `rebuild` / `update` - Platform-specific rebuild command
