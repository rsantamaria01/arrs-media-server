#!/bin/bash

# =============================================================================
# configure-rdtclient.sh
# Connects Sonarr, Sonarr Anime, Radarr and Lidarr to RDTClient
# =============================================================================

MEDIASTACK_DIR="/opt/mediastack"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Loading environment variables..."
set -a; source "$MEDIASTACK_DIR/.env"; set +a

connect_download_client() {
  local app_url=$1
  local app_api_key=$2
  local app_name=$3
  local category=$4

  RESPONSE=$(curl -s -X POST "$app_url/api/v3/downloadclient" \
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
        { \"name\": \"category\", \"value\": \"$category\" },
        { \"name\": \"useSsl\", \"value\": false }
      ]
    }")

  if echo "$RESPONSE" | grep -q '"id"'; then
    log_info "✅ $app_name connected to RDTClient"
  else
    log_warn "⚠️  $app_name failed or already connected — skipping"
  fi
}

SONARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$MEDIASTACK_DIR/services/sonarr/config.xml" | tr -d '\r\n')
SONARR_ANIME_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$MEDIASTACK_DIR/services/sonarr-anime/config.xml" | tr -d '\r\n')
RADARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$MEDIASTACK_DIR/services/radarr/config.xml" | tr -d '\r\n')
LIDARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$MEDIASTACK_DIR/services/lidarr/config.xml" | tr -d '\r\n')

log_info "Connecting apps to RDTClient..."
connect_download_client "http://sonarr:8989"       "$SONARR_API_KEY"       "Sonarr"       "sonarr"
connect_download_client "http://sonarr-anime:8989" "$SONARR_ANIME_API_KEY" "Sonarr Anime" "sonarr-anime"
connect_download_client "http://radarr:7878"       "$RADARR_API_KEY"       "Radarr"       "radarr"
connect_download_client "http://lidarr:8686"       "$LIDARR_API_KEY"       "Lidarr"       "lidarr"

log_info "✅ RDTClient configuration complete!"
log_info "Make sure you have completed the manual Torbox setup at rdtclient.rsantamaria.xyz first!"