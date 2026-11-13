# Usage Guide

Complete guide for using syncenv in all operation modes.

## Table of Contents

- [Quick Commands](#quick-commands)
- [Mode Management](#mode-management)
- [Peer Management](#peer-management)
- [Secret Management](#secret-management)
- [Sync Operations](#sync-operations)
- [Service Management](#service-management)
- [Shell Integration](#shell-integration)
- [Troubleshooting](#troubleshooting)

## Quick Commands

```bash
# Sync with peers (works in all modes)
syncenv

# Check current status
syncenv status

# Discover peers on network
syncenv discover

# Show help
syncenv --help
```

## Mode Management

syncenv operates in three distinct security modes. See [SECURITY-MODES.md](./SECURITY-MODES.md) for detailed security information.

### View Current Mode

```bash
syncenv mode get
```

### Switch Modes

```bash
# Switch to trusted-owner-ssh mode (default)
syncenv mode set trusted-owner-ssh

# Switch to secure-peer mode (for cross-owner collaboration)
syncenv mode set secure-peer

# Switch to dev mode (insecure, for debugging only)
syncenv mode set dev-plaintext-http

# Force mode switch without confirmation (non-interactive)
syncenv mode set secure-peer --yes

# Switch and clean up old mode's data
syncenv mode set trusted-owner-ssh --prune-old-material --yes
```

**Important**: Mode switches are non-destructive by default. Your keys, secrets, and peer data are preserved. Use `--prune-old-material` to clean up.

## Peer Management

### Secure-Peer Mode

In `secure-peer` mode, peers must be explicitly authorized before they can sync secrets.

#### Invite a New Peer

On an existing trusted peer:

```bash
# Create an enrollment invitation
syncenv peer invite

# Create invitation that expires in 1 hour
syncenv peer invite --expires 1h

# Create invitation with description
syncenv peer invite --expires 30m --description "John's laptop"
```

The command outputs:
- Enrollment token
- Hostname to connect to
- Transport fingerprint (for verification)

#### Join as a New Peer

On the new machine:

```bash
# 1. Set mode to secure-peer
syncenv mode set secure-peer

# 2. Request access using the token from invitation (peer IDs are user@host)
syncenv peer request alice@hostname.local <token>

# 3. Wait for approval, then sync
syncenv
```

#### Approve Pending Peers

```bash
# List pending requests
syncenv peer list --pending

# Approve a peer (peer IDs are user@host)
syncenv peer approve bob@new-host.local

# Revoke a peer's access
syncenv peer revoke mallory@compromised-host.local

# List all peers
syncenv peer list
```

#### View Peer Trust Information

```bash
# Show trust details for a specific peer (peer ID: user@host)
syncenv peer trust show alice@hostname.local

# List all trusted fingerprints
syncenv peer trust list
```

### Trusted-Owner-SSH Mode

In `trusted-owner-ssh` mode, any peer with SSH access can sync. No explicit approval needed.

```bash
# Discover peers (also filters by SSH reachability)
syncenv discover

# Collect public keys from discovered peers
syncenv discover --collect-keys
```

### Multiple Users on One Machine (v4.0+)

Peer IDs are per-user `user@host` (username + hostname, overridable via
`SYNCENV_USER` / `SYNCENV_HOSTNAME`). Each OS user gets their own port:
default `5739`, else `SYNCENV_PORT`, else `~/.config/syncenv/port`
(auto-bumped when taken). `serve -p/--port` or `SYNCENV_PORT` pins an
explicit port that is never bumped. Endpoints accept `host`, `host:port`, or
`user@host[:port]`; `user@host` auto-resolves the right port when reachable.
Legacy bare-hostname peers keep working via fallback.

## Secret Management

Manage your secrets with these commands. All commands work in both encrypted and plaintext modes.

### Add Secrets

```bash
# Add a new secret
syncenv add OPENAI_API_KEY="sk-abc123xyz"

# Add secret with spaces (use quotes)
syncenv add DATABASE_URL="postgres://user:pass@localhost/db"

# Add multiple secrets
syncenv add API_KEY="value1"
syncenv add AWS_ACCESS_KEY="AKIA..."
```

**Features:**
- Updates existing key if it already exists
- Automatically creates backup before modification
- Updates metadata (timestamp, checksum)
- Properly handles quotes in values

### Remove Secrets

```bash
# Remove a secret
syncenv remove OPENAI_API_KEY

# Safe to run - warns if key doesn't exist
syncenv remove NONEXISTENT_KEY
```

### List Secrets

```bash
# List all secret keys (values hidden)
syncenv list

# Output example:
# Secrets keys:
#   • OPENAI_API_KEY
#   • DATABASE_URL
#   • AWS_ACCESS_KEY
#
# Total: 3 keys
```

### View Secret Values

```bash
# Show value of a specific key
syncenv show OPENAI_API_KEY

# Output: sk-abc123xyz
```

### Load Secrets for Shell

```bash
# Output secrets as export statements
syncenv load

# Typical usage in shell profile
eval "$(syncenv load 2>/dev/null)"
```

## Sync Operations

### Automatic Sync

```bash
# Sync with all discovered peers
syncenv

# Same as:
syncenv sync
```

### Sync from Specific Host

```bash
# Sync from a specific peer only (peer IDs are user@host; port optional)
syncenv sync alice@hostname.local
```

### Force Pull

Forcefully overwrite local secrets with those from a specific host:

```bash
# Force pull from specific peer
syncenv sync --force-pull alice@hostname.local
```

**Use when:**
- You want to reset local secrets to match a trusted source
- You've made incorrect local changes and want to revert
- You want exact consistency with a specific machine

**Warning:** Local changes will be lost. A backup is created automatically.

### Dry Run

```bash
# Preview what would happen without making changes
syncenv sync --dry-run
```

## Service Management

The background service handles mDNS advertising and periodic sync.

### Start Service

```bash
# Start as background service
syncenv serve -d
```

### Stop Service

```bash
syncenv service stop
```

### Restart Service

```bash
syncenv service restart
```

### Check Service Status

```bash
# Native OS commands
systemctl --user status syncenv      # Linux
launchctl print gui/$(id -u)/syncenv # macOS
```

### Uninstall Service

```bash
syncenv service uninstall
```

## Shell Integration

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# Auto-load secrets on shell startup (decrypts automatically if encrypted)
eval "$(syncenv load 2>/dev/null)"

# Auto-sync in background on shell startup
if command -v syncenv &> /dev/null; then
    (syncenv --quiet &)
fi
```

## Cron Jobs

### Install Cron Job

```bash
# Install with default 30-minute interval
syncenv cron --install

# Install with custom interval (minutes)
syncenv cron --install --interval 10
syncenv cron --install --interval 60
```

### View Cron Job

```bash
syncenv cron --show
```

### Remove Cron Job

```bash
syncenv cron --remove
```

## Backups

Backups are created automatically before any modification.

### View Backups

```bash
ls ~/.config/syncenv/backups/
```

### Restore from Backup

```bash
# Restore from most recent backup
syncenv restore

# Restore from specific backup (1-5, where 1 is most recent)
syncenv restore 1
syncenv restore 3
```

## Troubleshooting

### Cannot Decrypt (Not in Recipient List)

```bash
# In trusted-owner-ssh mode
syncenv key request-access --trigger alice@hostname.local

# In secure-peer mode
# Ensure you've been approved by a trusted peer
syncenv peer list
```

### SSH Connection Fails (Trusted-Owner Mode)

```bash
# Test SSH connectivity (user = remote OS login)
ssh -v user@hostname.local

# Copy SSH key again
ssh-copy-id user@hostname.local
```

### Sync Not Working

```bash
# Check status
syncenv status

# View logs
tail -f ~/.config/syncenv/logs/syncenv.log

# Test discovery
syncenv discover
```

### Certificate/Trust Issues (Secure-Peer Mode)

```bash
# View peer trust status (peer ID: user@host)
syncenv peer trust show alice@hostname.local

# Check for pending approvals
syncenv peer list --pending

# Verify your transport identity
syncenv key show --transport
```

### Mode Switch Issues

```bash
# View current mode
syncenv mode get

# Check if old mode material exists
ls ~/.config/syncenv/

# Force mode switch with cleanup
syncenv mode set trusted-owner-ssh --prune-old-material --yes
```

## File Locations

```
~/.config/syncenv/
├── config                      # Config file
├── .secrets.env                # Secrets (encrypted or plaintext)
├── .secrets.env.backup.1..5    # Backups
├── keys/
│   ├── age_key                 # AGE private key (secure-peer mode)
│   ├── age_key.pub             # AGE public key
│   ├── transport_key           # mTLS transport private key
│   ├── transport_cert.pem      # mTLS transport certificate
│   ├── known_hosts/            # Cached peer pubkeys
│   └── cache/
│       └── pubkey_cache.json
├── peers/
│   ├── registry.json           # Peer registry (secure-peer mode)
│   └── trust_store/            # Pinned peer certificates
├── events/
│   └── membership.log          # Signed membership events
└── logs/
    └── syncenv.log            # Application logs
```
