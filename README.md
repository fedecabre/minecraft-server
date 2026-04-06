# Secure Minecraft Server with Traefik and Velocity

This repository contains a Docker-based Minecraft server setup that uses Traefik as a reverse proxy with TLS termination and Velocity as a proxy for the Minecraft protocol.

## Features

- **TLS Encryption** - Secure connections using Let's Encrypt certificates
- **Proxy Architecture** - Velocity proxy for improved security and performance
- **Modern Forwarding** - Secure player authentication and information forwarding
- **Docker Containerization** - Easy deployment and management
- **Traefik Dashboard** - Web interface for monitoring and managing routes (optional)

## Requirements

- Docker and Docker Compose
- A domain name (for production setup with TLS)
- Open ports 443 and 25565 on your firewall/router
- 4GB+ of RAM recommended

## Quick Start

### Local Testing

For local testing without TLS certificates:

1. Clone this repository
2. Create a `.env` file from `.env.example` (see below)
3. Run the local setup:

```bash
docker-compose -f docker-compose.local.yml up -d
```

Connect to the server at `localhost:25565` or your local IP address.

### Production Deployment

For a full production setup with TLS:

1. Clone this repository
2. Create a `.env` file from `.env.example`
3. Configure DNS records for your domain:
   - `minecraft.yourdomain.com` → Your server IP
   - `traefik.yourdomain.com` → Your server IP (for dashboard)
4. Run the production setup:

```bash
docker-compose up -d
```

Connect to the server at `minecraft.yourdomain.com`.

## Configuration

### Environment Variables

Copy the example environment file to create your own configuration:

```bash
cp .env.example .env
```

Then edit the `.env` file with your settings:

```
# Domain and hostname configuration
DOMAIN=yourdomain.com
MINECRAFT_HOST=minecraft
TRAEFIK_HOST=traefik

# Email for Let's Encrypt notifications
EMAIL=your-email@example.com

# Security - generate with: openssl rand -hex 16
VELOCITY_FORWARDING_SECRET=your_random_secret

# Minecraft server settings
MC_MEMORY=4G
MC_VERSION=LATEST
MC_SERVER_NAME="My Minecraft Server"
```

### Security

For additional security:

1. Enable Traefik Dashboard auth by uncommenting the auth middleware lines in `docker-compose.yml`
2. Generate credentials using: `htpasswd -nb username password` and add to `.env`

## Directory Structure

```
minecraft-server/
├── docker-compose.yml         # Production configuration
├── docker-compose.local.yml   # Local testing configuration
├── .env                       # Environment variables (create from example)
├── .env.example               # Example environment file
├── minecraft-data/            # Minecraft server data
├── traefik/                   # Traefik configuration
│   ├── letsencrypt/           # Let's Encrypt certificates
│   └── logs/                  # Traefik logs
└── velocity/                  # Velocity proxy configuration
    ├── velocity.toml          # Velocity settings
    └── forwarding.secret      # Velocity authentication secret
```

## Troubleshooting

### Common Issues

- **Connection Refused**: Check that ports 25565 and 443 are open on your firewall/router
- **Invalid Certificate**: Ensure your DNS records are correctly pointing to your server's IP
- **Velocity Errors**: Check logs with `docker-compose logs velocity`
- **Minecraft Errors**: Check logs with `docker-compose logs minecraft`

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
