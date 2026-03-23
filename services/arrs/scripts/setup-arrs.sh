#!/bin/bash
# =============================================================================
# setup-arrs.sh - Configure *arr services via API
# Sets root folders and download client for Radarr, Sonarr, Lidarr
# Called by init.sh after containers are running
# Assumes: REPO_DIR, DATA_DIR, ADMIN_USERNAME, ADMIN_PASSWORD are set
# =============================================================================

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

# Get API key from config.xml for a service
get_api_key() {
  local SERVICE=$1
  grep -oP '(?<=<ApiKey>).*(?=</ApiKey>)' "$DATA_DIR/services/$SERVICE/config.xml" || true
}

# Wait for a service to be reachable
wait_for_service() {
  local SERVICE=$1
  local URL=$2
  local MAX=120
  local ELAPSED=0

  log_info "[$SERVICE] Waiting for service to be ready..."
  sleep 10  # give service time to initialize before polling
  until curl -s -o /dev/null "$URL"; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    [ $ELAPSED -ge $MAX ] && log_error "[$SERVICE] Timed out waiting" && return 1
  done
  log_info "[$SERVICE] Ready ✅"
}

# Add root folder to a service
add_root_folder() {
  local SERVICE=$1
  local PORT=$2
  local PATH_VAL=$3
  local API_KEY=$(get_api_key "$SERVICE") || true

  if [ -z "$API_KEY" ]; then
    log_error "[$SERVICE] Could not get API key"
    return 1
  fi

  local BASE_URL="http://localhost:$PORT/api/v3"

  # Check if root folder already exists
  EXISTING=$(curl -sf "$BASE_URL/rootfolder" \
    -H "X-Api-Key: $API_KEY" | grep -c "$PATH_VAL" || true)

  if [ "$EXISTING" -gt 0 ]; then
    log_warn "[$SERVICE] Root folder $PATH_VAL already exists, skipping"
    return 0
  fi

  curl -sf "$BASE_URL/rootfolder" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"path\": \"$PATH_VAL\"}" > /dev/null

  log_info "[$SERVICE] Root folder $PATH_VAL added ✅"
}

# Add rdtclient as download client
add_download_client() {
  local SERVICE=$1
  local PORT=$2
  local API_KEY=$(get_api_key "$SERVICE")
  local BASE_URL="http://localhost:$PORT/api/v3"

  # Check if download client already exists
  EXISTING=$(curl -sf "$BASE_URL/downloadclient" \
    -H "X-Api-Key: $API_KEY" | grep -c "rdtclient" || true)

  if [ "$EXISTING" -gt 0 ]; then
    log_warn "[$SERVICE] Download client already exists, skipping"
    return 0
  fi

  curl -sf "$BASE_URL/downloadclient" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "rdtclient",
      "enable": true,
      "protocol": "torrent",
      "priority": 1,
      "implementation": "QBittorrent",
      "configContract": "QBittorrentSettings",
      "fields": [
        {"name": "host", "value": "rdtclient"},
        {"name": "port", "value": 6500},
        {"name": "username", "value": "'"$ADMIN_USERNAME"'"},
        {"name": "password", "value": "'"$ADMIN_PASSWORD"'"}
      ]
    }' > /dev/null

  log_info "[$SERVICE] Download client added ✅"
}

# -----------------------------------------------------------------------------
# Configure each service
# -----------------------------------------------------------------------------
log_info "Configuring *arr services..."

# Radarr
wait_for_service "radarr" "http://localhost:7878/api/v3/system/status"
add_root_folder    "radarr" 7878 "/data/media/movies"
add_download_client "radarr" 7878

# Sonarr
wait_for_service "sonarr" "http://localhost:8989/api/v3/system/status"
add_root_folder    "sonarr" 8989 "/data/media/shows"
add_download_client "sonarr" 8989

# Sonarr Anime
wait_for_service "sonarr-anime" "http://localhost:8990/api/v3/system/status"
add_root_folder    "sonarr-anime" 8990 "/data/media/anime"
add_download_client "sonarr-anime" 8990

# Lidarr
wait_for_service "lidarr" "http://localhost:8686/api/v3/system/status"
add_root_folder    "lidarr" 8686 "/data/media/music"
add_download_client "lidarr" 8686

log_info "✅ All *arr services configured"