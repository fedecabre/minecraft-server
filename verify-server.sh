#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$root"

# Load .env safely
if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

DUCKDNS_DOMAIN="${DUCKDNS_DOMAIN:-}"
DUCKDNS_TOKEN="${DUCKDNS_TOKEN:-}"
DOMAIN="${DOMAIN_TRAEFIK:-${DUCKDNS_DOMAIN:+${DUCKDNS_DOMAIN}.duckdns.org}}"

# ------------------------
# Helpers
# ------------------------

get_public_ip() {
  curl -s --max-time 10 https://api.ipify.org \
    || curl -s --max-time 10 https://ipv4.icanhazip.com \
    || echo ""
}

get_dns_ip() {
  dig +short "$1" | tail -n1 || echo ""
}


# ------------------------
# network safety check
# ------------------------

# Your fixed Freebox IP
FREEBOX_IP="82.66.6.94"

echo "== Network Safety Check =="
current_ip=$(get_public_ip)

if [[ "$current_ip" != "$FREEBOX_IP" ]]; then
  echo "⚠️  CAUTION: You are not connected via your Freebox!"
  echo "   Current IP: $current_ip (expected $FREEBOX_IP)"
  echo "   Aborting DuckDNS update to prevent service disruption."
  
  # Optional: skip only DuckDNS or exit the whole script
  # exit 1 
  DUCKDNS_DOMAIN="" # This will trigger the 'Skipping DuckDNS check' later
else
  echo "✅ Confirmed: Connected to Freebox network."
fi


# ------------------------
# DuckDNS Check
# ------------------------

echo "== DuckDNS IP Check =="

if [[ -n "$DUCKDNS_DOMAIN" && -n "$DUCKDNS_TOKEN" ]]; then
  current_ip=$(get_public_ip)
  dns_ip=$(get_dns_ip "$DOMAIN")

  if [[ -z "$current_ip" ]]; then
    echo "❌ Could not determine current public IP"
  elif [[ -z "$dns_ip" ]]; then
    echo "❌ Could not resolve $DOMAIN"
  elif [[ "$current_ip" != "$dns_ip" ]]; then
    echo "IP mismatch detected:"
    echo "  Public IP : $current_ip"
    echo "  DNS IP    : $dns_ip"
    echo "Updating DuckDNS..."

    update_result=$(curl -s \
      "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${current_ip}")

    if [[ "$update_result" == "OK" ]]; then
      echo "✅ DuckDNS updated successfully"
    else
      echo "❌ DuckDNS update failed: $update_result"
    fi
  else
    echo "✅ DuckDNS is up-to-date ($dns_ip)"
  fi
else
  echo "Skipping DuckDNS check (missing DUCKDNS_DOMAIN or DUCKDNS_TOKEN)"
fi

# ------------------------
# Docker Status
# ------------------------

echo ""
echo "== Docker status =="
docker compose ps

# ------------------------
# Minecraft Health
# ------------------------

echo ""
echo "== Minecraft container health =="
if docker compose ps | grep -q minecraft; then
  docker compose exec -T minecraft mc-health \
    || echo "⚠ mc-health failed. Check logs."
else
  echo "Minecraft container not running."
fi

# ------------------------
# Local Port Check
# ------------------------

echo ""
echo "== Local TCP port check =="

for port in 25565; do
  if nc -z -w 2 localhost "$port" >/dev/null 2>&1; then
    echo "✅ localhost:$port open"
  else
    echo "❌ localhost:$port closed"
  fi
done

echo ""
echo "ℹ UDP (19132) cannot be reliably tested locally without a Bedrock handshake."

# ------------------------
# External Connectivity
# ------------------------

echo ""
echo "== External Connectivity Test =="

if [[ -n "$DOMAIN" ]]; then
  echo "1. DNS resolution"
  resolved_ip=$(get_dns_ip "$DOMAIN")

  if [[ -n "$resolved_ip" ]]; then
    echo "   ✅ $DOMAIN → $resolved_ip"
  else
    echo "   ❌ DNS resolution failed"
  fi

  echo ""
  echo "2. Java Edition (TCP 25565)"
  if nc -z -w 3 "$DOMAIN" 25565 >/dev/null 2>&1; then
    echo "   ✅ Port 25565 reachable"
  else
    echo "   ❌ Port 25565 NOT reachable"
  fi

  echo ""
  echo "3. Bedrock Edition (UDP 19132)"
  echo "   ℹ UDP reachability cannot be confirmed via netcat."
  echo "   ℹ Test from a real Bedrock client (4G network)."
else
  echo "Skipping external test (DOMAIN not defined)"
fi

echo ""
echo "== External Validation (via API) =="

# On utilise || true pour éviter que le script crash si curl ou grep échouent
check_api=$(curl -s "https://api.mcsrvstat.us/bedrock/2/${DOMAIN}" || echo "error")

# Extraction plus robuste avec grep -q (quiet)
if echo "$check_api" | grep -q '"online":true'; then
  echo "✅ Server is VISIBLE from internet (via mcsrvstat.us)"
  
  # Extraction du nombre de joueurs (optionnel)
  players=$(echo "$check_api" | grep -oP '"online":\s*\K\d+' || echo "0")
  echo "   Players online: $players"
else
  echo "❌ Server is OFFLINE or API is slow"
  echo "   (Note: Check https://mcsrvstat.us/bedrock/${DOMAIN} manually)"
fi

echo ""
echo "Verification complete."