# HappyVertical Agent Resolver

`scripts/hv-agent-resolver.py` composes agent behavior from four layers:

1. `dotfiles` personal baseline (`hv/manifest.json`)
2. HappyVertical organization standards from `have-config`
3. optional Context Forge snapshot from `HV_CONTEXTFORGE_SNAPSHOT_DIR`
4. machine-local overrides from `~/.config/hv/overrides`

Command and skill conflicts resolve in this order:

`local override > Context Forge snapshot > have-config > dotfiles`

AGENTS and CLAUDE docs are cumulative and assembled in layer order.

## Local Overrides

Local overrides are never rewritten by the installer. Use these conventions:

- `~/.config/hv/overrides/skills/<name>/SKILL.md`
- `~/.config/hv/overrides/skills/codex/<name>/SKILL.md`
- `~/.config/hv/overrides/skills/claude/<name>/SKILL.md`
- `~/.config/hv/overrides/commands/claude/<name>.md`
- `~/.config/hv/overrides/commands/codex/<name>.md`
- `~/.config/hv/overrides/agent-docs/AGENTS.md`
- `~/.config/hv/overrides/agent-docs/CLAUDE.md`

For more control, create `~/.config/hv/overrides/manifest.json` using the same
shape as `hv/manifest.json`.

## Context Forge Snapshots

The installer cannot call MCP prompts directly from shell. Export Context Forge
material into a local directory with a `manifest.json`, then set:

```bash
export HV_CONTEXTFORGE_SNAPSHOT_DIR="$HOME/.config/hv/contextforge"
```

Rerun `./install.sh` to materialize the snapshot into local runtime files and
record hashes in `~/.config/hv/agent-lock.json`.

## Local Environment

If present, `~/.config/hv/env` is sourced by the installer before resolving
agent configuration. If `~/.config/hv/env.sops.env` exists, install decrypts it
with SOPS into `~/.config/hv/env` first. Keep real values local and use Warden
as the sharing standard.
