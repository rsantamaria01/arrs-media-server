#!/bin/bash

# =============================================================================
# configure.sh - Auto configure Prowlarr indexers and app connections
# Called automatically at the end of init.sh
# Reads API keys directly from each app's config.xml
# =============================================================================

set -e

MEDIASTACK_DIR="/opt/mediastack"
PROWLARR_URL="http://localhost:9696"
SONARR_URL="http://localhost:8989"
SONARR_ANIME_URL="http://localhost:8990"
RADARR_URL="http://localhost:7878"
LIDARR_URL="http://localhost:8686"

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
# Helper: extract API key from config.xml
# -----------------------------------------------------------------------------
get_api_key() {
  local config_file=$1
  local timeout=60
  local elapsed=0

  log_info "Waiting for $config_file to be generated..."

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
# Helper: wait for app to be ready
# -----------------------------------------------------------------------------
wait_for_app() {
  local name=$1
  local url=$2
  local api_key=$3
  local timeout=120
  local elapsed=0

  log_info "Waiting for $name to be ready..."

  until curl -sf "$url/api/v1/health" \
    -H "X-Api-Key: $api_key" > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
      log_error "Timed out waiting for $name at $url"
      exit 1
    fi
    echo -n "."
    sleep 3
    elapsed=$((elapsed + 3))
  done

  echo ""
  log_info "$name is ready"
}

# -----------------------------------------------------------------------------
# Read API keys from config files
# -----------------------------------------------------------------------------
log_info "Reading API keys from config files..."

PROWLARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/prowlarr/config.xml")
log_info "Prowlarr API key found"

SONARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr/config.xml")
log_info "Sonarr API key found"

SONARR_ANIME_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr-anime/config.xml")
log_info "Sonarr Anime API key found"

RADARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/radarr/config.xml")
log_info "Radarr API key found"

LIDARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/lidarr/config.xml")
log_info "Lidarr API key found"

# -----------------------------------------------------------------------------
# Wait for all apps to be ready
# -----------------------------------------------------------------------------
wait_for_app "Prowlarr"     "$PROWLARR_URL"     "$PROWLARR_API_KEY"
wait_for_app "Sonarr"       "$SONARR_URL"       "$SONARR_API_KEY"
wait_for_app "Sonarr Anime" "$SONARR_ANIME_URL" "$SONARR_ANIME_API_KEY"
wait_for_app "Radarr"       "$RADARR_URL"       "$RADARR_API_KEY"
wait_for_app "Lidarr"       "$LIDARR_URL"       "$LIDARR_API_KEY"

# -----------------------------------------------------------------------------
# Add indexers to Prowlarr
# -----------------------------------------------------------------------------
log_info "Adding indexers to Prowlarr..."

add_indexer() {
  local name=$1
  local payload=$2

  RESPONSE=$(curl -sf -X POST "$PROWLARR_URL/api/v1/indexer" \
    -H "X-Api-Key: $PROWLARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>&1)

  if [ $? -eq 0 ]; then
    log_info "Indexer $name added"
  else
    log_warn "Indexer $name failed or already exists — skipping"
  fi
}

# General
add_indexer "1337x" '{
  "name": "1337x",
  "enable": true,
  "protocol": "torrent",
  "implementationName": "1337x",
  "implementation": "1337x",
  "configContract": "1337xSettings",
  "fields": []
}'

add_indexer "RARBG" '{
  "name": "RARBG",
  "enable": true,
  "protocol": "torrent",
  "implementationName": "RARBG",
  "implementation": "RARBG",
  "configContract": "RARBGSettings",
  "fields": []
}'

add_indexer "YTS" '{
  "name": "YTS",
  "enable": true,
  "protocol": "torrent",
  "implementationName": "YTS",
  "implementation": "YTS",
  "configContract": "YTSSettings",
  "fields": []
}'

# Anime
add_indexer "Nyaa" '{
  "name": "Nyaa",
  "enable": true,
  "protocol": "torrent",
  "implementationName": "Nyaa",
  "implementation": "Nyaa",
  "configContract": "NyaaSettings",
  "fields": []
}'

# Spanish content
add_indexer "DivxTotal" '{
  "name": "DivxTotal",
  "enable": true,
  "protocol": "torrent",
  "implementationName": "DivxTotal",
  "implementation": "DivxTotal",
  "configContract": "DivxTotalSettings",
  "fields": []
}'

add_indexer "Elitetorrent" '{
  "name": "Elitetorrent",
  "enable": true,
  "protocol": "torrent",
  "implementationName": "Elitetorrent",
  "implementation": "Elitetorrent",
  "configContract": "ElitetorrentSettings",
  "fields": []
}'

# -----------------------------------------------------------------------------
# Connect apps to Prowlarr
# -----------------------------------------------------------------------------
log_info "Connecting apps to Prowlarr..."

connect_app() {
  local name=$1
  local payload=$2

  RESPONSE=$(curl -sf -X POST "$PROWLARR_URL/api/v1/applications" \
    -H "X-Api-Key: $PROWLARR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>&1)

  if [ $? -eq 0 ]; then
    log_info "App $name connected"
  else
    log_warn "App $name failed or already connected — skipping"
  fi
}

connect_app "Sonarr" "{
  \"name\": \"Sonarr\",
  \"syncLevel\": \"fullSync\",
  \"implementationName\": \"Sonarr\",
  \"implementation\": \"Sonarr\",
  \"configContract\": \"SonarrSettings\",
  \"fields\": [
    { \"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\" },
    { \"name\": \"baseUrl\", \"value\": \"http://sonarr:8989\" },
    { \"name\": \"apiKey\", \"value\": \"$SONARR_API_KEY\" },
    { \"name\": \"syncCategories\", \"value\": [5000, 5010, 5020, 5030, 5040] }
  ]
}"

connect_app "Sonarr Anime" "{
  \"name\": \"Sonarr Anime\",
  \"syncLevel\": \"fullSync\",
  \"implementationName\": \"Sonarr\",
  \"implementation\": \"Sonarr\",
  \"configContract\": \"SonarrSettings\",
  \"fields\": [
    { \"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\" },
    { \"name\": \"baseUrl\", \"value\": \"http://sonarr-anime:8990\" },
    { \"name\": \"apiKey\", \"value\": \"$SONARR_ANIME_API_KEY\" },
    { \"name\": \"syncCategories\", \"value\": [5070] }
  ]
}"

connect_app "Radarr" "{
  \"name\": \"Radarr\",
  \"syncLevel\": \"fullSync\",
  \"implementationName\": \"Radarr\",
  \"implementation\": \"Radarr\",
  \"configContract\": \"RadarrSettings\",
  \"fields\": [
    { \"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\" },
    { \"name\": \"baseUrl\", \"value\": \"http://radarr:7878\" },
    { \"name\": \"apiKey\", \"value\": \"$RADARR_API_KEY\" },
    { \"name\": \"syncCategories\", \"value\": [2000, 2010, 2020, 2030, 2040] }
  ]
}"

connect_app "Lidarr" "{
  \"name\": \"Lidarr\",
  \"syncLevel\": \"fullSync\",
  \"implementationName\": \"Lidarr\",
  \"implementation\": \"Lidarr\",
  \"configContract\": \"LidarrSettings\",
  \"fields\": [
    { \"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\" },
    { \"name\": \"baseUrl\", \"value\": \"http://lidarr:8686\" },
    { \"name\": \"apiKey\", \"value\": \"$LIDARR_API_KEY\" },
    { \"name\": \"syncCategories\", \"value\": [3000, 3010, 3020, 3030, 3040] }
  ]
}"

# -----------------------------------------------------------------------------
# Save API keys to .env for reference
# -----------------------------------------------------------------------------
log_info "Saving API keys to .env..."

update_env() {
  local key=$1
  local value=$2
  if grep -q "^$key=" "$MEDIASTACK_DIR/.env"; then
    sed -i "s|^$key=.*|$key=$value|" "$MEDIASTACK_DIR/.env"
  else
    echo "$key=$value" >> "$MEDIASTACK_DIR/.env"
  fi
}

update_env "PROWLARR_API_KEY"     "$PROWLARR_API_KEY"
update_env "SONARR_API_KEY"       "$SONARR_API_KEY"
update_env "SONARR_ANIME_API_KEY" "$SONARR_ANIME_API_KEY"
update_env "RADARR_API_KEY"       "$RADARR_API_KEY"
update_env "LIDARR_API_KEY"       "$LIDARR_API_KEY"

log_info "API keys saved to .env"

log_info "✅ Configuration complete!"
log_info "Prowlarr is now connected to Sonarr, Sonarr Anime, Radarr and Lidarr"
log_info "Indexers have been added including Spanish and Anime sources"