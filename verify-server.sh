#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$root"

# Load .env if present
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
fi

DUCKDNS_DOMAIN=${DUCKDNS_DOMAIN:-}
DOMAIN="${DUCKDNS_DOMAIN:+${DUCKDNS_DOMAIN}.duckdns.org}"

# Function to get current public IP
get_public_ip() {
  curl -s -m 10 https://api.ipify.org || curl -s -m 10 https://ipv4.icanhazip.com || echo ""
}

# Function to get DuckDNS current IP
get_duckdns_ip() {
  nslookup "$1" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}' || echo ""
}

echo "== DuckDNS IP Check =="
if [[ -n "${DUCKDNS_TOKEN:-}" && -n "$DOMAIN" ]]; then
  current_ip=$(get_public_ip)
  duckdns_ip=$(get_duckdns_ip "$DOMAIN")

  if [[ -z "$current_ip" ]]; then
    echo "Warning: Could not determine current public IP"
  elif [[ -z "$duckdns_ip" ]]; then
    echo "Warning: Could not resolve DuckDNS IP for $DOMAIN"
  elif [[ "$current_ip" != "$duckdns_ip" ]]; then
    echo "IP mismatch detected:"
    echo "  Current public IP: $current_ip"
    echo "  DuckDNS IP: $duckdns_ip"
    echo "  Updating DuckDNS..."
    update_result=$(curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${current_ip}")
    if [[ "$update_result" == "OK" ]]; then
      echo "  DuckDNS updated successfully"
    else
      echo "  Warning: DuckDNS update failed: $update_result"
    fi
  else
    echo "DuckDNS IP is current: $duckdns_ip"
  fi
else
  echo "Skipping DuckDNS check (DUCKDNS_TOKEN or DUCKDNS_DOMAIN not set)"
fi

echo ""
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
for port in 25565 19132; do
  if bash -c "</dev/tcp/localhost/$port" >/dev/null 2>&1; then
    echo "localhost:$port is open"
  else
    echo "localhost:$port is closed"
  fi
done

echo ""
echo "Verification complete."
