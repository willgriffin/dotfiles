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
├── .agents/                # Cross-agent skills
│   └── skills/
├── .codex/                 # Codex defaults
│   └── AGENTS.md
├── hv/                     # Personal baseline manifest for agent resolver
│   └── manifest.json
├── scripts/                # Bootstrap helper scripts
│   └── hv-agent-resolver.py
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

Agent skills and global agent docs are resolved separately from the normal
home-directory stow packages. The resolver composes these layers:

1. this dotfiles repo as your personal baseline
2. `have-config` as the HappyVertical organization standard
3. an optional Context Forge snapshot from `HV_CONTEXTFORGE_SNAPSHOT_DIR`
4. machine-local overrides from `~/.config/hv/overrides`

Commands and skills use this precedence: local override, Context Forge snapshot,
`have-config`, then dotfiles. AGENTS and CLAUDE docs are cumulative.

Generated files are written under `~/.config/hv/generated`, with an
`~/.config/hv/agent-lock.json` and `~/.config/hv/install-report.md` explaining
sources, selected winners, overrides, missing env vars, and skipped tooling.

Restart Codex after installing or updating skills; running sessions do not hot-load newly installed skills.

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
- `pr-review` - cloned/updated at `~/Work/happyvertical/repos/pr-review` and added to `PATH`
- HappyVertical agent workflows - `~/Work/happyvertical/repos/have-config/install.sh --live`
- `sops` / `age` / `gnupg` - local encrypted environment tooling where available
- `rclone` - WebDAV-capable client for OxiCloud where available
- `rebuild` / `update` - Platform-specific rebuild command
