# Copilot Instructions for this Repository

This repository is a Dockerized Minecraft server setup with Traefik and DuckDNS.

## Key details
- Docker Compose file is `compose.yml`.
- Traefik is configured to use Let's Encrypt ACME DNS-01 challenge via DuckDNS.
- Minecraft traffic is expected to be forwarded from external port `16384` to internal port `25565` on Freebox routers.
- `.env` contains secrets and must never be committed.
- `.env.example` is the safe template for users.
- `minecraft-data/` contains generated server runtime files, libraries, worlds, and should be kept out of git.
- `letsencrypt/acme.json` is ACME state and should not be committed.

## Guidance for Copilot
- Prefer updating documentation, `.env.example`, and `compose.yml` when changes are needed.
- Avoid modifying generated runtime files under `minecraft-data/` unless the user explicitly asks for cleanup.
- Use `docker compose` commands in docs and instructions, not `docker-compose`.
- When the user asks to update setup or troubleshooting instructions, sync the README with the active Traefik/DuckDNS DNS-01 workflow.
- Keep explanations concise and practical.

## Current status
- `README.md` now uses generic `myserver.duckdns.org` examples.
- The Docker Compose stack is using DuckDNS DNS-01 challenge and `acme.dnschallenge.provider=duckdns`.
- Port forwarding instructions should mention that ports `80` and `443` are not required for certificate issuance.

## Useful checks for future changes
- `git status --short`
- `docker compose logs traefik | grep -i "acme\|certificate"`
- `nslookup myserver.duckdns.org`
- `nc -zv myserver.duckdns.org 16384`
