# pve-freq Docker

Run [pve-freq](https://github.com/Low-Freq-Labs/pve-freq) in Docker — one CLI to manage your entire infrastructure. Proxmox VMs, Docker stacks, switches, firewalls, storage, DNS, VPN, certificates, security, monitoring. 25 domains, 275+ API routes, zero dependencies.

## Prerequisites

- A Linux host (Debian 12+, Ubuntu 22.04+, or similar)
- Docker Engine and Docker Compose plugin
- Network access to your Proxmox VE nodes

### Install Docker (Debian/Ubuntu)

```bash
# Install Docker from the official repository
curl -fsSL https://get.docker.com | sh

# Add your user to the docker group (log out and back in after)
sudo usermod -aG docker $USER
```

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/Low-Freq-Labs/pve-freq-docker.git
cd pve-freq-docker
```

### 2. Build the image

The build script handles everything — it builds a Python wheel from the pve-freq source and bakes it into the Docker image.

```bash
# If pve-freq source is at ../pve-freq
./build.sh

# Or point to the source repo
FREQ_SRC=/path/to/pve-freq ./build.sh

# Or use a pre-built wheel
./build.sh /path/to/pve_freq-1.0.0-py3-none-any.whl
```

### 3. Start the container

```bash
docker compose up -d
```

### 4. Run first-time setup

```bash
./freq init
```

This walks you through connecting to your Proxmox VE cluster — PVE API token, SSH keys, fleet host registration. Config is generated in TOML format. After first use, the `freq` wrapper installs itself to `/usr/local/bin/freq` so you can run `freq` from anywhere.

### 5. Open the dashboard

```
http://<your-host>:8888
```

## Usage

The `freq` wrapper script is included in the repo. On first use it installs itself to `/usr/local/bin/freq` so you can run `freq` from anywhere.

```bash
# Interactive TUI
freq

# CLI commands (v1.0.0 domain syntax)
freq doctor            # Diagnostics
freq fleet status      # Fleet health summary
freq vm list           # VMs across cluster
freq host list         # Fleet hosts
freq net switch facts  # Switch details
freq secure audit      # Security audit
freq plugin list       # Installed plugins

# Any freq command works
freq help
```

All commands run inside the container — the wrapper handles `docker exec` for you.

## Configuration

### Environment

```bash
cp .env.example .env
```

Edit `.env` to set your timezone:

```
TZ=UTC
```

### Change the dashboard port

Edit `compose.yml` to change the host port:

```yaml
ports:
  - "2550:8888"   # host:container
```

### SSH keys

To manage fleet hosts over SSH, mount your SSH key into the container. Uncomment and edit in `compose.yml`:

```yaml
volumes:
  - ~/.ssh/id_ed25519:/home/freq/.ssh/id_ed25519:ro
  - ~/.ssh/known_hosts:/home/freq/.ssh/known_hosts:ro
```

### Persistent data

| Path | Type | Contents |
|---|---|---|
| `./config/` | Bind mount | User-editable config files (freq.toml, hosts.toml, etc.) |
| `freq-data` | Docker volume | Vault, keys, logs, cache — managed by freq |

Config files live in the repo directory so you can version them. Data is in a Docker volume so it persists across rebuilds.

## Updating

```bash
# Pull latest pve-freq source and rebuild
cd pve-freq-docker
git pull
./build.sh

# Recreate the container with the new image
docker compose up -d --build
```

Your config and data persist across updates.

## Troubleshooting

### Container won't start

```bash
# Check logs
docker compose logs -f

# Verify the image built correctly
docker run --rm pve-freq:local freq --version
```

### Dashboard shows setup wizard after init

This means `freq init` created root-owned config files. The `freq` wrapper fixes this automatically, but if you ran `docker exec` manually:

```bash
docker exec pve-freq chown -R freq:freq /config /data /opt/pve-freq
```

### Health check failing

```bash
# Check container health
docker inspect pve-freq --format='{{.State.Health.Status}}'

# Check if freq serve is running
docker exec pve-freq ps aux | grep freq
```

## Architecture

```
pve-freq-docker/
  Dockerfile              # Image definition (python:3.13-slim + tini)
  compose.yml             # Docker Compose config
  docker-entrypoint.sh    # Container startup (symlinks, permissions, privilege drop)
  freq                    # CLI wrapper (self-installs to /usr/local/bin)
  build.sh                # Build helper (wheel + docker build)
  config/                 # Bind-mounted config directory
  dist/                   # Wheel files (built or provided, gitignored)
  .env.example            # Environment template
```

The container runs as a non-root `freq` user (UID 1000). The entrypoint starts as root to fix volume permissions, then drops privileges via `setpriv`. PID 1 is `tini` for proper signal handling.

## Documentation

Full documentation lives in the [pve-freq](https://github.com/Low-Freq-Labs/pve-freq) repo:

- [Configuration](https://github.com/Low-Freq-Labs/pve-freq/blob/main/docs/CONFIGURATION.md) — Every config key documented
- [Codebase Standard](https://github.com/Low-Freq-Labs/pve-freq/blob/main/docs/CODEBASE-STANDARD-2026.md) — Engineering standards
- [Changelog](https://github.com/Low-Freq-Labs/pve-freq/blob/main/CHANGELOG.md) — Version history

## License

See [pve-freq](https://github.com/Low-Freq-Labs/pve-freq) for license details.
