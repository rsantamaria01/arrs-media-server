#!/bin/bash

# =============================================================================
# configure-prowlarr.sh
# 1. Reads API keys directly from each app's config.xml
# 2. Makes API calls to Prowlarr to connect all apps
# =============================================================================

set -e

MEDIASTACK_DIR="/opt/mediastack"
PROWLARR_URL="http://localhost:9696"

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Load .env
# -----------------------------------------------------------------------------
log_info "Loading environment variables..."
set -a
source "$MEDIASTACK_DIR/.env"
set +a

# -----------------------------------------------------------------------------
# Helper: extract API key from config.xml
# -----------------------------------------------------------------------------
get_api_key() {
  local config_file=$1
  local timeout=60
  local elapsed=0

  log_info "Waiting for $config_file..."

  until [ -f "$config_file" ] && grep -q "<ApiKey>" "$config_file"; do
    if [ $elapsed -ge $timeout ]; then
      log_error "Timed out waiting for $config_file"
      exit 1
    fi
    echo -n "."
    sleep 3
    elapsed=$((elapsed + 3))
  done

  echo ""
  grep -oP '(?<=<ApiKey>)[^<]+' "$config_file"
}

# -----------------------------------------------------------------------------
# Helper: wait for Prowlarr to be ready
# -----------------------------------------------------------------------------
wait_for_prowlarr() {
  local timeout=120
  local elapsed=0

  log_info "Waiting for Prowlarr to be ready..."

  until curl -sf "$PROWLARR_URL/api/v1/health" \
    -H "X-Api-Key: $PROWLARR_API_KEY" > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
      log_error "Timed out waiting for Prowlarr"
      exit 1
    fi
    echo -n "."
    sleep 3
    elapsed=$((elapsed + 3))
  done

  echo ""
  log_info "Prowlarr is ready"
}

# -----------------------------------------------------------------------------
# Helper: connect app to Prowlarr
# -----------------------------------------------------------------------------
connect_app() {
  local name=$1
  local base_url=$2
  local api_key=$3
  local sync_categories=$4
  local implementation=$5

  RESPONSE=$(curl -sf -X POST "$PROWLARR_URL/api/v1/applications" \
    -H "X-Api-Key: $PROWLARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$name\",
      \"syncLevel\": \"fullSync\",
      \"implementationName\": \"$implementation\",
      \"implementation\": \"$implementation\",
      \"configContract\": \"${implementation}Settings\",
      \"fields\": [
        { \"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\" },
        { \"name\": \"baseUrl\", \"value\": \"$base_url\" },
        { \"name\": \"apiKey\", \"value\": \"$api_key\" },
        { \"name\": \"syncCategories\", \"value\": $sync_categories }
      ]
    }" 2>&1)

  if [ $? -eq 0 ]; then
    log_info "✅ $name connected"
  else
    log_warn "⚠️  $name failed or already connected — skipping"
  fi
}

# -----------------------------------------------------------------------------
# Step 1 — Read API keys directly from config.xml files
# -----------------------------------------------------------------------------
log_info "Reading API keys from config files..."

PROWLARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/prowlarr/config.xml")
SONARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr/config.xml")
SONARR_ANIME_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr-anime/config.xml")
RADARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/radarr/config.xml")
LIDARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/lidarr/config.xml")

log_info "All API keys found"

# -----------------------------------------------------------------------------
# Step 2 — Wait for Prowlarr then connect all apps
# -----------------------------------------------------------------------------
wait_for_prowlarr

log_info "Connecting apps to Prowlarr..."

connect_app "Sonarr"       "http://sonarr:8989"       "$SONARR_API_KEY"       "[5000,5010,5020,5030,5040]" "Sonarr"
connect_app "Sonarr Anime" "http://sonarr-anime:8990" "$SONARR_ANIME_API_KEY" "[5070]"                     "Sonarr"
connect_app "Radarr"       "http://radarr:7878"       "$RADARR_API_KEY"       "[2000,2010,2020,2030,2040]" "Radarr"
connect_app "Lidarr"       "http://lidarr:8686"       "$LIDARR_API_KEY"       "[3000,3010,3020,3030,3040]" "Lidarr"

log_info "✅ Prowlarr configuration complete!"