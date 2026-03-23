#!/bin/bash

# =============================================================================
# configure-prowlarr.sh
# 1. Reads API keys directly from each app's config.xml
# 2. Makes API calls to Prowlarr to connect all apps
# =============================================================================

MEDIASTACK_DIR="/opt/mediastack"
PROWLARR_URL="http://localhost:9696"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Loading environment variables..."
set -a; source "$MEDIASTACK_DIR/.env"; set +a

get_api_key() {
  grep -oP '(?<=<ApiKey>)[^<]+' "$1" | tr -d '\r\n'
}

connect_download_client() {
  local app_url=$1
  local app_api_key=$2
  local app_name=$3
  local category_field=$4
  local category=$5

  RESPONSE=$(curl -s -X POST "$app_url/downloadclient" \
    -H "X-Api-Key: $app_api_key" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"RDTClient\",
      \"enable\": true,
      \"protocol\": \"torrent\",
      \"priority\": 1,
      \"implementation\": \"QBittorrent\",
      \"implementationName\": \"qBittorrent\",
      \"configContract\": \"QBittorrentSettings\",
      \"fields\": [
        { \"name\": \"host\", \"value\": \"rdtclient\" },
        { \"name\": \"port\", \"value\": 6500 },
        { \"name\": \"username\", \"value\": \"$RDTCLIENT_USER\" },
        { \"name\": \"password\", \"value\": \"$RDTCLIENT_PASSWORD\" },
        { \"name\": \"$category_field\", \"value\": \"$category\" },
        { \"name\": \"useSsl\", \"value\": false }
      ]
    }")

  if echo "$RESPONSE" | grep -q '"id"'; then
    log_info "✅ $app_name connected to RDTClient"
  else
    log_warn "⚠️  $app_name failed or already connected — skipping"
  fi
}

log_info "Reading API keys..."
PROWLARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/prowlarr/config.xml")
SONARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr/config.xml")
SONARR_ANIME_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/sonarr-anime/config.xml")
RADARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/radarr/config.xml")
LIDARR_API_KEY=$(get_api_key "$MEDIASTACK_DIR/services/lidarr/config.xml")
log_info "All API keys found"

log_info "Connecting apps to Prowlarr..."
connect_download_client "http://localhost:8989/api/v3" "$SONARR_API_KEY"       "Sonarr"       "tvCategory"    "sonarr"
connect_download_client "http://localhost:8990/api/v3" "$SONARR_ANIME_API_KEY" "Sonarr Anime" "tvCategory"    "sonarr-anime"
connect_download_client "http://localhost:7878/api/v3" "$RADARR_API_KEY"       "Radarr"       "movieCategory" "radarr"
connect_download_client "http://localhost:8686/api/v1" "$LIDARR_API_KEY"       "Lidarr"       "musicCategory" "lidarr"

log_info "✅ Prowlarr configuration complete!"