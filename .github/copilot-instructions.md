# Copilot Instructions for this Repository

Dockerized Minecraft server — single container (itzg/minecraft-server Paper) with DuckDNS dynamic DNS.

## Key details
- Docker Compose file is `compose.yml` — single `minecraft` service, no proxy.
- Ports exposed directly: `25565` (Java TCP), `19132` (Bedrock UDP).
- Geyser/Floodgate enabled via env vars (`ENABLE_GEYSER`, `ENABLE_FLOODGATE`).
- `.env` contains secrets and must never be committed.
- `.env.example` is the safe template.
- `minecraft-data/` is runtime data, gitignored.
- `verify-server.sh` handles DuckDNS IP sync and health checks.
- `backup.sh` backs up world data to `docker/backups/`.

## Guidance for Copilot
- **Use caveman mode by default.**
- Use `docker compose` commands, not `docker-compose`.
- Keep explanations concise and practical.

## Useful checks
- `docker compose ps`
- `docker compose logs minecraft`
- `./verify-server.sh`
