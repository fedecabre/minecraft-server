# Secure Minecraft Server with Traefik and DuckDNS

This repository contains a Docker-based Minecraft server setup that uses Traefik as a reverse proxy with TLS termination via Let's Encrypt and DuckDNS for free dynamic DNS hosting.

## Features

- **TLS Encryption** - Automatic HTTPS certificates from Let's Encrypt
- **Traefik Reverse Proxy** - Professional-grade reverse proxy and load balancer
- **DuckDNS Integration** - Free dynamic DNS with automatic IP updates
- **Paper Server** - Modern Minecraft server (1.21.11) with optimization
- **Docker Containerization** - Easy deployment and management
- **Health Checks** - Automated service monitoring and restart
- **Resource Limits** - Controlled CPU and memory allocation
- **Backup System** - Automated world data backups with retention

## Requirements

- Docker and Docker Compose installed
- Free DuckDNS account (or your own domain)
- DuckDNS token for DNS-01 challenge
- **Port forwarding configured on router** for Minecraft (high ports on Freebox)
- 4GB+ RAM recommended
- Linux or WSL2 environment

## Quick Setup

### 1. Clone and Configure

```bash
git clone https://github.com/fedecabre/minecraft-server.git
cd minecraft-server
cp .env.example .env
```

### 2. Set Up Free DuckDNS Domain

1. Visit [duckdns.org](https://www.duckdns.org/)
2. Login with Google/GitHub/Twitter
3. Create subdomain (e.g., `myserver`)
4. Get your token from the dashboard

### 3. Update Configuration

Edit `.env` file:

```bash
DOMAIN_ROOT=duckdns.org
DOMAIN_TRAEFIK=myserver.duckdns.org
DOMAIN_MINECRAFT=myserver.duckdns.org
EMAIL=your-email@example.com
DUCKDNS_TOKEN=your_duckdns_token_here
MCADMIN_PASS=your_secure_password
CRAFTY_PASS=your_secure_password
```

### 4. Launch Server

```bash
docker compose up -d
```

### 5. Verify Setup

```bash
docker compose logs minecraft     # Check Minecraft startup
docker compose ps                 # Verify containers running
```

Connect to server at `myserver.duckdns.org:16384`

## Port Forwarding

Port forwarding is **REQUIRED** for Minecraft traffic. With DuckDNS DNS challenge, Let's Encrypt validation no longer requires external port 80 or 443.

Forward this port on your router to your machine:
- **16384** → `25565` (Minecraft game server) for Freebox users with high-port restrictions

If you want external HTTPS web services behind Traefik, forward another allowed external port to the host port where that service is exposed.

### For Freebox Users (France)

1. **Access Freebox Admin Panel**
   - Open browser: `http://192.168.1.254/` or `mafreebox.free.fr`
   - Login: username `freebox`, password on back of router

2. **Navigate to Port Forwarding**
   - Go to **Paramètres** → **Réseau** → **NAT/UPnP** or **Redirection de ports**

3. **Add the Minecraft Port Forwarding Rule**
   - External Port: `16384`
   - Internal IP: `<your-machine-ip>` (e.g., `192.168.1.4`)
   - Internal Port: `25565`
   - Protocol: TCP

4. **Save and Wait**
   - Click "Appliquer" (Apply)
   - Wait 1-2 minutes for changes to take effect

5. **Verify Port Forwarding**
   ```bash
   nslookup fedecabre.duckdns.org
   
   docker compose down
   docker compose up -d
   
   docker compose logs traefik | grep -i "acme\|certificate"
   ```
   docker compose logs traefik | grep -i "acme\|certificate"
   ```

## Backup & Recovery

### Manual Backup

```bash
./backup.sh
```

Creates compressed backup in `./docker/backups/`

### Automated Backups (Linux/WSL)

```bash
crontab -e
# Add: 0 2 * * * cd /path/to/minecraft-server && ./backup.sh
```

Daily backup at 2 AM, keeps last 7 backups.

## Configuration Files

### `.env` (❌ Never commit!)
**IMPORTANT**: This file contains passwords and secrets. Keep it private!
- Already in `.gitignore`
- Never push to public repositories
- Rotate credentials if exposed

### `.env.example`
Template showing required variables. Safe to commit and share.

### `compose.yml`
Main Docker Compose configuration with Traefik, Minecraft, and resource limits.

## Troubleshooting

### Certificate Issues (ACME)
- **Port 80 must be accessible** - Let's Encrypt needs HTTP for validation
- **Port 443 must be accessible** - For HTTPS service
- Ensure router port forwarding is properly configured (see "Port Forwarding" section)
- Check DNS A record resolves to your public IP
- Wait 5 minutes for DNS propagation

```bash
# Test DNS resolution
nslookup fedecabre.duckdns.org

# Check certificate acquisition in logs
docker compose logs traefik | grep -i "acme\|certificate"

# If still failing, restart services after port forwarding configured
docker compose down
docker compose up -d
```

Error: `Timeout during connect (likely firewall problem)` = Port forwarding not working

### Connection Issues
```bash
# Test port accessibility
nc -zv myserver.duckdns.org 25565

# Check Docker logs
docker compose logs traefik     # Proxy logs
docker compose logs minecraft    # Server logs
```

### Update IP (if dynamic)
DuckDNS auto-updates your IP, but you can force it:
```bash
curl "https://www.duckdns.org/update?domains=myserver&token=YOUR_TOKEN&ip="
```

## Security Best Practices

1. **Never commit `.env`** - it contains passwords
2. **Strong passwords** - Use random generation:
   ```bash
   openssl rand -base64 12
   ```
3. **Rotate credentials** - Especially if accidentally exposed
4. **Firewall** - Only expose necessary ports
5. **Updates** - Keep Docker images updated:
   ```bash
   docker compose pull
   docker compose up -d
   ```

## Directory Structure

```
minecraft-server/
├── compose.yml                 # Production configuration
├── .env                        # ❌ Private credentials (gitignored)
├── .env.example                # ✓ Template (safe to share)
├── .gitignore                  # Prevents .env from being committed
├── backup.sh                   # Backup automation script
├── minecraft-data/             # World data & server files
├── docker/                     # Docker container configs
│   ├── backups/               # Backup archives
│   ├── config/                # Crafty controller config
│   └── logs/                  # Service logs
└── velocity-config/            # Velocity proxy config (optional)
```

## Minecraft Server Details

- **Version**: 1.21.11 (Paper - production optimized)
- **Memory**: 4GB allocated
- **Plugins**: bStats, Spark profiler built-in
- **Port**: 25565 (proxied through Traefik)
- **World Location**: `minecraft-data/world/`

## DuckDNS Auto-Update (Optional)

Keep IP current automatically:

```bash
# Create update script
cat > update-duckdns.sh << 'EOF'
#!/bin/bash
TOKEN="your_duckdns_token"
DOMAIN="myserver"
curl "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip="
EOF

chmod +x update-duckdns.sh

# Add to crontab for hourly updates
crontab -e
# Add: 0 * * * * /path/to/update-duckdns.sh
```

## License

This project is provided as-is. See LICENSE file for details.

## Support

- Check logs: `docker compose logs`
- View config: `cat .env.example`
- Restart services: `docker compose down && docker compose up -d`

### Checking Server Status

To verify the server is running correctly:

```bash
# Check container status
docker-compose ps

# Test port connectivity
nc -zv localhost 25565

# View logs
docker-compose logs -f
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) - Minecraft server image
- [itzg/mc-proxy](https://github.com/itzg/docker-mc-proxy) - Velocity proxy image
- [Traefik](https://traefik.io/) - Edge router and reverse proxy
- [Velocity](https://velocitypowered.com/) - Modern Minecraft proxy
