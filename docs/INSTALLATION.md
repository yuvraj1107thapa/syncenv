# Installation Guide

Complete installation instructions for syncenv on Linux, macOS, and Windows (WSL2).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Install](#quick-install)
- [Install from Source](#install-from-source)
- [Platform-Specific Notes](#platform-specific-notes)
- [Post-Installation](#post-installation)
- [Verification](#verification)
- [Uninstallation](#uninstallation)

## Prerequisites

### Required

- **Go 1.24+** (only for building from source)
- **SSH client** (for `trusted-owner-ssh` mode)
- **mDNS support**:
  - Linux: `avahi-daemon` and `avahi-utils`
  - macOS: Built-in (Bonjour)
  - Windows WSL2: See [WSL2 notes](#windows-wsl2)

### SSH Key Setup (Trusted-Owner Mode)

For `trusted-owner-ssh` mode, ensure SSH keys are set up between your machines:

```bash
# On each machine, copy your SSH key to other machines
ssh-copy-id hostname1.local
ssh-copy-id hostname2.local
```

## Quick Install

### Web-Based Install (Recommended)

Download and install the latest release directly:

```bash
# Install to /usr/local/bin (requires sudo)
curl -fsSL https://syncenv.yuvrajthapa.com/install.sh | sudo bash

# Or install to ~/.local/bin (user-only, no sudo)
curl -fsSL https://syncenv.yuvrajthapa.com/install.sh | bash -s -- --user
```

### What the Installer Does

1. Detects your platform (Linux/macOS)
2. Downloads or builds the requested CLI and/or GUI artifacts
3. Installs the CLI to `/usr/local/bin` (system) or `~/.local/bin` (user)
4. Installs the GUI to `/Applications` / `~/Applications` on macOS, or into XDG app locations on Linux
5. If a CLI service is running, stops it, upgrades, and restarts automatically

For macOS GUI releases, GitHub Releases publishes separate `amd64` and `arm64` DMG files containing `syncenv.app`.

### Manual Binary Install

Download the pre-built binary from releases:

```bash
# Download latest release
curl -L -o syncenv https://github.com/yuvraj1107thapa/syncenv/releases/latest/download/syncenv-linux-amd64
chmod +x syncenv

# Install system-wide
sudo mv syncenv /usr/local/bin/

# Or install user-only
mkdir -p ~/.local/bin
mv syncenv ~/.local/bin/
```

## Install from Source

### Clone Repository

```bash
git clone https://github.com/yuvraj1107thapa/syncenv.git
cd syncenv
```

### Build

```bash
# Build Go binary
make build

# Ubuntu/Debian GUI prerequisites (GUI builds only)
sudo apt-get update
sudo apt-get install -y pkg-config libgtk-3-dev libwebkit2gtk-4.1-dev

# Run tests
make test

# Install system-wide
sudo make install

# Or install user-only
make install-user
```

### Using install.sh

```bash
# Install to /usr/local/bin (requires sudo)
sudo ./install.sh

# Or install to ~/.local/bin (user-only)
./install.sh --user

# Install GUI only in the proper desktop-app location
sudo ./install.sh --gui-only

# Install both CLI + GUI
sudo ./install.sh --all
```

For Linux GUI builds, use a machine or CI runner that matches the target architecture. Ubuntu's `libwebkit2gtk-4.1-dev` packages for `amd64` and `arm64` conflict with each other, so installing both on the same system is not a supported build path here.

## Platform-Specific Notes

### Linux

#### Ubuntu/Debian

```bash
# Install mDNS dependencies
sudo apt-get update
sudo apt-get install -y avahi-daemon avahi-utils

# Install syncenv
curl -fsSL https://syncenv.yuvrajthapa.com/install.sh | sudo bash
```

#### Fedora/RHEL/CentOS

```bash
# Install mDNS dependencies
sudo dnf install -y avahi avahi-tools

# Install syncenv
curl -fsSL https://syncenv.yuvrajthapa.com/install.sh | sudo bash
```

#### Arch Linux

```bash
# Install mDNS dependencies
sudo pacman -S avahi

# Install syncenv
curl -fsSL https://syncenv.yuvrajthapa.com/install.sh | sudo bash
```

### macOS

mDNS (Bonjour) is built-in, no additional dependencies needed.

```bash
# Install syncenv
curl -fsSL https://syncenv.yuvrajthapa.com/install.sh | sudo bash
```

For web installs, `install.sh` automatically selects the correct CLI binary for your OS/architecture. If you include `--gui`, it likewise downloads the matching GUI package for your platform (`.deb` on Linux, `.dmg` on macOS).

**Note**: On macOS, the service uses `launchd` instead of `systemd`.

### Windows WSL2

WSL2 has limitations with mDNS. You have two options:

#### Option 1: Use Windows Host mDNS (Recommended)

Install and run syncenv on Windows, then access from WSL2 via the Windows host.

#### Option 2: mDNS Relay in WSL2

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y avahi-daemon avahi-utils

# Edit avahi config to use reflector
sudo tee /etc/avahi/avahi-daemon.conf <<EOF
[reflector]
enable-reflector=yes
EOF

# Restart avahi
sudo service avahi-daemon restart

# Install syncenv
curl -fsSL https://syncenv.yuvrajthapa.com/install.sh | sudo bash
```

## Post-Installation

### Add to PATH (User Install)

If you installed to `~/.local/bin`, ensure it's in your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
```

### Initial Setup

```bash
# 1. Check installation
syncenv --version

# 2. Check current mode (default: trusted-owner-ssh)
syncenv mode get

# 3. Initialize secrets file
syncenv init

# 4. Set up periodic sync (optional)
syncenv cron --install

# 5. Start background service (optional)
# This enables mDNS advertising and periodic sync
syncenv serve -d
```

## Verification

### Check Installation

```bash
# Verify binary works
syncenv --version

# Check status
syncenv status

# Discover peers (if any exist on network)
syncenv discover
```

### Test Sync

```bash
# Add a test secret
syncenv add TEST_KEY="test_value"

# Sync (with verbose output)
syncenv sync --verbose

# View the secret
syncenv show TEST_KEY

# Remove test secret
syncenv remove TEST_KEY
```

### Verify Service (if running)

```bash
# Linux
systemctl --user status syncenv

# macOS
launchctl print gui/$(id -u)/syncenv
```

## Upgrading

### Upgrade with install.sh

The install script handles upgrades seamlessly:

```bash
# Upgrade system-wide install
sudo ./install.sh

# Upgrade user install
./install.sh --user
```

**Note**: If the service is running, it will be stopped, upgraded, and restarted automatically.

### Upgrade from Source

```bash
git pull origin main
make build
sudo make install
```

## Uninstallation

### Remove Binary

```bash
# System install
sudo rm /usr/local/bin/syncenv

# User install
rm ~/.local/bin/syncenv
```

### Remove Service

```bash
# Stop and remove service
syncenv service uninstall
```

### Remove Configuration

```bash
# Remove all config, secrets, and keys
rm -rf ~/.config/syncenv
```

### Complete Removal

```bash
# One-liner to remove everything
syncenv service uninstall 2>/dev/null; \
  rm -rf ~/.config/syncenv; \
  sudo rm -f /usr/local/bin/syncenv; \
  rm -f ~/.local/bin/syncenv
```

## Troubleshooting Installation

### "command not found" after install

```bash
# Check if in PATH
which syncenv

# If using user install, ensure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Add to shell profile
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Permission Denied

```bash
# Fix permissions on user install
chmod +x ~/.local/bin/syncenv

# Or use sudo for system install
sudo ./install.sh
```

### Build Failures

```bash
# Check Go version
go version  # Should be 1.24+

# Install dependencies
cd src && go mod download

# Build again
make build
```

### mDNS Not Working

```bash
# Linux: Check avahi status
sudo systemctl status avahi-daemon

# Test mDNS manually
avahi-browse -a  # List all services

# macOS: Check dns-sd
dns-sd -B _syncenv._tcp
```

## Development Install

For development work on syncenv itself:

```bash
git clone https://github.com/yuvraj1107thapa/syncenv.git
cd syncenv

# Build locally (doesn't install)
make build

# Test locally
./target/syncenv --version

# Run tests
make test

# Run integration tests
./tests/test-dockers.sh
```

## Docker Install (Advanced)

```dockerfile
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN cd src && go build -o ../target/syncenv ./cmd/syncenv

FROM alpine:latest
RUN apk add --no-cache openssh-client avahi
COPY --from=builder /app/target/syncenv /usr/local/bin/
ENTRYPOINT ["syncenv"]
```

Build and run:

```bash
docker build -t syncenv .
docker run --rm -it syncenv --version
```
