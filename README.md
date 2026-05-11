# Minecraft Server (Docker)

Personal Minecraft server running Paper with cross-platform Bedrock support via Geyser/Floodgate.

## Features

- **Paper Server** — Optimized Minecraft 1.21.1
- **Cross-Platform** — Java + Bedrock players on the same world (Geyser & Floodgate)
- **DuckDNS** — Free dynamic DNS with automatic IP updates
- **Docker** — Single container, easy deployment
- **Backup** — Automated world backups with 7-day retention
- **Health Checks** — Auto-restart on failure
- **Resource Limits** — 4GB RAM, 2 CPU cores

## Requirements

- Docker and Docker Compose
- DuckDNS account ([duckdns.org](https://www.duckdns.org/))
- Port forwarding on your router
- 4GB+ RAM
- Linux or WSL2

## Quick Setup

```bash
git clone https://github.com/fedecabre/minecraft-server.git
cd minecraft-server
cp .env.example .env
# Edit .env with your DuckDNS domain and token
docker compose up -d
```

## Port Forwarding

Forward these ports on your router to the host machine:

| External Port | Internal Port | Protocol | Service |
|---|---|---|---|
| `49154` | `25565` | TCP | Java Minecraft |
| `49155` | `19132` | UDP | Bedrock Minecraft |

> Freebox users: access router at `http://192.168.1.254/` → Paramètres → Réseau → Redirection de ports

### Connecting

- **Java Edition**: `mysubdomain.duckdns.org:49154`
- **Bedrock Edition**: `mysubdomain.duckdns.org:49155` (UDP)

## Backup & Recovery

```bash
# Manual backup
./backup.sh

# Automated (crontab)
crontab -e
# Add: 0 2 * * * /path/to/minecraft-server/backup.sh
```

Backups saved to `docker/backups/`, keeps last 7.

## Server Verification

```bash
./verify-server.sh
```

Checks: DuckDNS IP sync, container health, port availability.

## DuckDNS Auto-Update

`verify-server.sh` automatically updates your DuckDNS IP when it detects a mismatch. For continuous updates:

```bash
crontab -e
# Add: 0 * * * * /path/to/minecraft-server/verify-server.sh > /dev/null 2>&1
```

## Directory Structure

```
minecraft-server/
├── compose.yml          # Docker Compose (single Minecraft container)
├── .env                 # ❌ Private credentials (gitignored)
├── .env.example         # ✓ Template (safe to share)
├── backup.sh            # World backup script
├── verify-server.sh     # Health check & DuckDNS IP sync
└── minecraft-data/      # Server runtime data (gitignored)
```

## Commands

```bash
docker compose up -d          # Start
docker compose down           # Stop
docker compose logs minecraft # View logs
docker compose restart        # Restart
docker compose pull && docker compose up -d  # Update image
```

## Security

- `.env` is gitignored — never commit secrets
- `ONLINE_MODE=TRUE` — Mojang authentication enforced
- Only ports 25565 (TCP) and 19132 (UDP) exposed
