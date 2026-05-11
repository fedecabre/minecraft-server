# Implementation Notes

## Architecture

Single Docker container running `itzg/minecraft-server` (Paper) with:

- Java Edition on port `25565` (TCP)
- Bedrock Edition on port `19132` (UDP) via integrated Geyser/Floodgate

No reverse proxy — Minecraft uses raw TCP/UDP, not HTTP. Direct port exposure is simpler and adds no latency.

## Container Configuration

Key environment variables in `compose.yml`:

- `TYPE=PAPER` — Paper server for performance
- `VERSION=1.21.1` — Minecraft version
- `MEMORY=4G` — JVM heap allocation
- `ONLINE_MODE=TRUE` — Mojang auth enforced
- `ENABLE_GEYSER=true` — Auto-installs Geyser proxy (Bedrock→Java translation)
- `ENABLE_FLOODGATE=true` — Auto-installs Floodgate (Bedrock player authentication)

Resource limits: 4GB RAM, 2 CPU cores. Health check via `mc-health` every 30s.

## DuckDNS Integration

`verify-server.sh` compares current public IP (via ipify) against DuckDNS record and auto-updates if mismatched. Requires `DUCKDNS_DOMAIN` and `DUCKDNS_TOKEN` in `.env`.

## Networking (Freebox)

Freebox blocks external ports below 49152. Port forwarding:

- WAN `49154` → LAN `25565` (Java TCP)
- WAN `49155` → LAN `19132` (Bedrock UDP)

## Backup

`backup.sh` compresses `world/`, `world_nether/`, `world_the_end/` into `docker/backups/`. Uses `find`-based cleanup to keep last 7 backups.

## World Data

All server runtime data lives in `minecraft-data/` (gitignored). The `itzg/minecraft-server` image manages Paper downloads, plugin installation, and server configuration automatically.
