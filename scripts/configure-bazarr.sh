#!/bin/bash

# =============================================================================
# configure-bazarr.sh
# 1. Reads API keys directly from each app's config.xml
# 2. Makes API calls to Bazarr to connect Sonarr, Sonarr Anime and Radarr
# =============================================================================

MEDIASTACK_DIR="/opt/mediastack"
BAZARR_URL="http://localhost:6767"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Loading environment variables..."
set -a; source "$MEDIASTACK_DIR/.env"; set +a

get_api_key() {
  grep -oP '(?<=<ApiKey>)[^<]+' "$1" | tr -d '\r\n'
}

get_bazarr_api_key() {
  grep -oP '(?<=apikey: )[^\s]+' "$MEDIASTACK_DIR/services/bazarr/config/config.yaml" | head -1 | tr -d '\r\n'
}

connect_sonarr() {
  local name=$1 base_url=$2 api_key=$3

  RESPONSE=$(curl -s -X POST "$BAZARR_URL/api/sonarr" \
    -H "X-API-KEY: $BAZARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$name\",
      \"ip\": \"$(echo $base_url | sed 's|http://||' | cut -d: -f1)\",
      \"port\": $(echo $base_url | sed 's|.*:||'),
      \"apikey\": \"$api_key\",
      \"ssl\": false,
      \"base_url\": \"\"
    }")

  if echo "$RESPONSE" | grep -q '"id"'; then
    log_info "✅ $name connected to Bazarr"
  else
    log_warn "⚠️  $name failed or already connected — skipping"
  fi
}

connect_radarr() {
  local name=$1 base_url=$2 api_key=$3

  RESPONSE=$(curl -s -X POST "$BAZARR_URL/api/radarr" \
    -H "X-API-KEY: $BAZARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$name\",
      \"ip\": \"$(echo $base_url | sed 's|http://||' | cut -d: -f1)\",
      \"port\": $(echo $base_url | sed 's|.*:||'),
      \"apikey\": \"$api_key\",
      \"ssl\": false,
      \"base_url\": \"\"
    }")

  if echo "$RESPONSE" | grep -q '"id"'; then
    log_info "✅ $name connected to Bazarr"
  else
    log_warn "⚠️  $name failed or already connected — skipping"
  fi
}

log_info "Reading API keys..."
BAZARR_API_KEY=$(get_bazarr_api_key)
SONARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr/config.xml")
SONARR_ANIME_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr-anime/config.xml")
RADARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/radarr/config.xml")
log_info "All API keys found"

log_info "Connecting apps to Bazarr..."
connect_sonarr "Sonarr"       "http://sonarr:8989"       "$SONARR_API_KEY"
connect_sonarr "Sonarr Anime" "http://sonarr-anime:8989" "$SONARR_ANIME_API_KEY"
connect_radarr "Radarr"       "http://radarr:7878"       "$RADARR_API_KEY"

log_info "✅ Bazarr configuration complete!"