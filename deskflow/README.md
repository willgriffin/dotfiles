# Deskflow Configuration

Shared keyboard/mouse between Mac (server) and Linux machines (clients).

## Mac Server Setup

1. Install Deskflow via Homebrew: `brew install --cask deskflow`

2. Symlink the server config:
   ```bash
   ln -sf ~/Work/willgriffin/repos/dotfiles/deskflow/deskflow-server.conf ~/Library/Deskflow/deskflow-server.conf
   ```

3. In Deskflow GUI:
   - Set as Server
   - Enable "Use external configuration file"
   - Point to `~/Library/Deskflow/deskflow-server.conf`
   - Enable TLS

## NixOS Client Setup

Configured via `services.deskflow-client` in the host's NixOS config.

Example (in hosts/rickety/default.nix):
```nix
services.deskflow-client = {
  enable = true;
  serverAddress = "100.127.7.33";  # Mac's Tailscale IP
  screenName = "rickety";
  enableTls = true;
  fixBackspace = true;  # Fixes backspace issues with Mac servers
};
```

## Backspace Fix

The `fixBackspace` option applies an xmodmap fix for the backspace key,
which can behave incorrectly when a Mac server sends key events to a Linux client.

## Screen Layout

```
    +-----+
    | mac |
    +-----+
       |
    +--------+
    | rickety|
    +--------+
```

Move mouse down from mac to reach rickety.
