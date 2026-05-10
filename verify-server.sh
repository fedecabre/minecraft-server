#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$root"

# Load .env if present
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
fi

DOMAIN_TRAEFIK=${DOMAIN_TRAEFIK:-fedecabre.duckdns.org}
DOMAIN_MINECRAFT=${DOMAIN_MINECRAFT:-$DOMAIN_TRAEFIK}

# Function to get current public IP
get_public_ip() {
  curl -s -m 10 https://api.ipify.org || curl -s -m 10 https://ipv4.icanhazip.com || echo ""
}

# Function to get DuckDNS current IP
get_duckdns_ip() {
  nslookup "$DOMAIN_TRAEFIK" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}' || echo ""
}

# Function to update DuckDNS IP
update_duckdns() {
  local token="$1"
  local domain="$2"
  local ip="$3"
  curl -s "https://www.duckdns.org/update?domains=${domain}&token=${token}&ip=${ip}"
}

echo "== DuckDNS IP Check =="
if [[ -n "${DUCKDNS_TOKEN:-}" ]]; then
  current_ip=$(get_public_ip)
  duckdns_ip=$(get_duckdns_ip)

  if [[ -z "$current_ip" ]]; then
    echo "Warning: Could not determine current public IP"
  elif [[ -z "$duckdns_ip" ]]; then
    echo "Warning: Could not resolve DuckDNS IP for $DOMAIN_TRAEFIK"
  elif [[ "$current_ip" != "$duckdns_ip" ]]; then
    echo "IP mismatch detected:"
    echo "  Current public IP: $current_ip"
    echo "  DuckDNS IP: $duckdns_ip"
    echo "  Updating DuckDNS..."
    update_result=$(update_duckdns "$DUCKDNS_TOKEN" "${DOMAIN_TRAEFIK%.duckdns.org}" "$current_ip")
    if [[ "$update_result" == "OK" ]]; then
      echo "  DuckDNS updated successfully"
    else
      echo "  Warning: DuckDNS update failed: $update_result"
    fi
  else
    echo "DuckDNS IP is current: $duckdns_ip"
  fi
else
  echo "Skipping DuckDNS check (DUCKDNS_TOKEN not set)"
fi

echo "== Docker status =="
docker compose ps

echo ""
echo "== Minecraft container health =="
if docker compose ps | grep -q minecraft; then
  docker compose exec -T minecraft mc-health || echo "Warning: mc-health failed. Check container logs."
else
  echo "Minecraft container is not running."
fi

echo ""
echo "== Local port check =="
if command -v nc >/dev/null 2>&1; then
  nc -zv localhost 25565
else
  if bash -c '</dev/tcp/localhost/25565' >/dev/null 2>&1; then
    echo "localhost:25565 is open"
  else
    echo "localhost:25565 is closed or unreachable"
    exit 1
  fi
fi

echo ""
echo "== External HTTP test =="
set +e
curl -I -m 10 "http://${DOMAIN_TRAEFIK}:49152/test"
curl -Ik -m 10 "https://${DOMAIN_TRAEFIK}:49153/test"

echo ""
echo "== External Minecraft TCP test =="
if command -v nc >/dev/null 2>&1; then
  nc -zv "${DOMAIN_MINECRAFT}" 49154
else
  if bash -c ">/dev/tcp/${DOMAIN_MINECRAFT}/49154" >/dev/null 2>&1; then
    echo "${DOMAIN_MINECRAFT}:49154 is open"
  else
    echo "${DOMAIN_MINECRAFT}:49154 is closed or unreachable"
    exit 1
  fi
fi
set -e

echo ""
echo "Verification complete."
