# Implementation Documentation

## Overview

This repository implements a Docker-based Minecraft server with Traefik reverse proxy and DuckDNS DNS-01 ACME certificate issuance.

The stack is designed for a home network with a Freebox router that blocks low external ports, so it uses high external ports for public access where required.

## Architecture

- `traefik`: reverse proxy, ACME TLS, HTTP/HTTPS ingress, TCP proxy for Minecraft, UDP proxy for Bedrock
- `minecraft`: Paper Minecraft server with built-in Geyser proxy for Bedrock Edition support
- `duckdns-test`: nginx static page used to verify DNS and HTTP routing

## Key Components

### Traefik

Traefik is configured in `compose.yml` with these entrypoints:

- `web` → `:80`
- `websecure` → `:16400`
- `minecraft` → `:25565` (TCP)
- `bedrock` → `:19132` (UDP)

Traefik also uses DuckDNS for the DNS-01 challenge:

- `--certificatesresolvers.myresolver.acme.dnschallenge.provider=duckdns`
- `--certificatesresolvers.myresolver.acme.email=${EMAIL}`
- `--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json`

### Minecraft service

The Minecraft container runs Paper server (1.21.1-133) with Geyser and Floodgate plugins:

- internal port `25565` (Java Edition)
- internal port `19132` (Bedrock Edition via Geyser UDP)
- Traefik TCP router on entrypoint `minecraft` for Java clients
- Traefik UDP router on entrypoint `bedrock` for Bedrock clients
- Geyser-Spigot (v2.10.0): translates Bedrock protocol to Java
- Floodgate (v2.2.5): manages Bedrock Edition player authentication
- Both plugins installed in `minecraft-data/plugins/` directory
- Cross-platform play enabled: Java and Bedrock players share the same world

#### Geyser and Floodgate Plugin Installation

The Minecraft container includes both Geyser and Floodgate plugins:

1. **Geyser-Spigot**: Acts as a proxy for Bedrock clients, translating the Bedrock protocol to Java Edition
2. **Floodgate**: Provides secure authentication for Bedrock players without requiring a Microsoft account

Both plugins are downloaded and placed in `minecraft-data/plugins/` where the container loads them on startup.

To manually add or update plugins:

```bash
# Download latest versions
wget https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot -O minecraft-data/plugins/geyser-spigot.jar
wget https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot -O minecraft-data/plugins/floodgate-spigot.jar

# Restart the server
docker compose restart minecraft
```

### DuckDNS test page

A simple Nginx service serves `/test` from `./docker/test-site`.
Its Traefik router matches:

- `Host(`${DOMAIN_TRAEFIK}`) && PathPrefix(`/test`)`

The middleware strips `/test` before forwarding to the nginx container.

## Environment variables

Store secrets in `.env` and do not commit it.

Required variables:

- `DOMAIN_ROOT=duckdns.org`
- `DOMAIN_TRAEFIK=fedecabre.duckdns.org`
- `EMAIL=your-email@example.com`
- `DUCKDNS_TOKEN=your-duckdns-token`
- `MCADMIN_SERVER_NAME` and other optional server values

## Ports and routing

### Container host ports

`compose.yml` maps:

- `80:80` for HTTP to Traefik
- `443:16400` to Traefik `websecure`
- `16400:16400` as an alternate HTTPS port inside the stack
- `25565:25565` for Minecraft TCP (Java)
- `19132:19132/udp` for Bedrock UDP (built into Minecraft container)

### Freebox limitations

Freebox restricts external port forwarding below `49152` in this setup. That means:

- You cannot use external `80` or `443` if the router blocks low ports
- You must use high external ports instead

Recommended public mappings for Freebox:

- `WAN 49152` → `LAN 80` (HTTP)
- `WAN 49153` → `LAN 16400` (HTTPS for Traefik websecure)
- `WAN 49154` → `LAN 25565` (Java Minecraft TCP)
- `WAN 49155` → `LAN 19132` (Bedrock Minecraft UDP)

If you need to access the test page externally, use:

- `https://fedecabre.duckdns.org:49153/test`

If HTTP forwarding is also configured, this will work as well:

- `http://fedecabre.duckdns.org:49152/test`

The HTTPS route uses the same DuckDNS hostname, but a non-standard port because Freebox blocks low ports.

## Deployment steps

1. Copy the example env file:

```bash
cp .env.example .env
```

2. Edit `.env` with your DuckDNS token, domain, and email.

3. Start the stack:

```bash
docker compose up -d
```

4. Confirm containers are running:

```bash
docker compose ps
```

5. Check Traefik logs for ACME activity:

```bash
docker compose logs traefik | grep -i "acme\|certificate"
```

## Verification

### Local verification

From the host:

```bash
curl -s -H "Host: fedecabre.duckdns.org" http://localhost:80/test | head -20
```

### DNS verification

Confirm the DuckDNS hostname resolves:

```bash
nslookup fedecabre.duckdns.org
```

### Automatic IP synchronization

The `verify-server.sh` script automatically checks if your public IP matches the DuckDNS record and updates it if necessary:

```bash
./verify-server.sh
```

This requires `DUCKDNS_TOKEN` to be set in `.env`.

### External port verification

If the Freebox forwarding is configured correctly:

```bash
curl -I -m 10 http://fedecabre.duckdns.org:49152/test
curl -I -m 10 https://fedecabre.duckdns.org:49153/test
```

For Minecraft-specific status, verify the server with mcsrvstat:

```bash
curl -I -m 10 https://mcsrvstat.us/server/fedecabre.duckdns.org:49154
```

### Minecraft access

If the router forwards external `49154` to internal `25565`, connect with:

```text
fedecabre.duckdns.org:49154
```

### Bedrock access

If the router forwards external `49155` (UDP) to internal `19132`, Bedrock players connect with:

```text
fedecabre.duckdns.org:49155
```

> Both Java and Bedrock clients connect to the same world through Geyser translation.

## Notes

- DuckDNS DNS-01 ACME means Let’s Encrypt certificate issuance does not require public `80` or `443`.
- However, standard browser access still needs port forwarding if you want `https://fedecabre.duckdns.org/test` without a port.
- If Freebox blocks standard ports, use high external ports and include them in the URL.

## Troubleshooting

1. If the test page returns `404` locally, check Traefik router labels and middleware.
2. If external access times out, verify Freebox port forwarding rules and public IP.
3. If your public IP is dynamic, refresh DuckDNS after the IP changes:
   ```bash
   curl "https://www.duckdns.org/update?domains=fedecabre&token=YOUR_TOKEN&ip="
   ```
4. If certificates fail, verify `DUCKDNS_TOKEN` and whether Traefik can write `/letsencrypt/acme.json`.

## Directory structure

```text
minecraft-server/
├── compose.yml
├── .env
├── .env.example
├── IMPLEMENTATION.md
├── README.md
├── verify-server.sh
├── docker/test-site/
│   └── index.html
├── minecraft-data/
└── letsencrypt/
```
