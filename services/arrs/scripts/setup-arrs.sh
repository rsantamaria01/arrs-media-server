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

get_api_key() {
  local SERVICE=$1
  grep -oP '(?<=<ApiKey>).*(?=</ApiKey>)' "$DATA_DIR/services/$SERVICE/config.xml" || true
}

wait_for_service() {
  local SERVICE=$1
  local PORT=$2
  local MAX=120
  local ELAPSED=0
  local API_KEY
  API_KEY=$(get_api_key "$SERVICE")

  log_info "[$SERVICE] Waiting for service to be ready..."
  until curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/api/v3/system/status" \
    -H "X-Api-Key: $API_KEY" | grep -qE "^(200|401)$"; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [ $ELAPSED -ge $MAX ]; then
      log_error "[$SERVICE] Timed out waiting"
      return 1
    fi
  done
  log_info "[$SERVICE] Ready ✅"
}

add_root_folder() {
  local SERVICE=$1
  local PORT=$2
  local PATH_VAL=$3
  local API_KEY
  API_KEY=$(get_api_key "$SERVICE")

  if [ -z "$API_KEY" ]; then
    log_error "[$SERVICE] Could not get API key"
    return 1
  fi

  local BASE_URL="http://localhost:$PORT/api/v3"

  # Check if root folder already exists
  local EXISTING
  EXISTING=$(curl -s "$BASE_URL/rootfolder" -H "X-Api-Key: $API_KEY")

  if echo "$EXISTING" | grep -q "$PATH_VAL"; then
    log_warn "[$SERVICE] Root folder $PATH_VAL already exists, skipping"
    return 0
  fi

  local RESPONSE
  RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/rootfolder" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"path\": \"$PATH_VAL\"}")

  local HTTP_CODE
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)

  if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    log_info "[$SERVICE] Root folder $PATH_VAL added ✅"
  else
    log_error "[$SERVICE] Failed to add root folder (HTTP $HTTP_CODE): $(echo "$RESPONSE" | head -1)"
    return 1
  fi
}

add_download_client() {
  local SERVICE=$1
  local PORT=$2
  local API_KEY
  API_KEY=$(get_api_key "$SERVICE")

  if [ -z "$API_KEY" ]; then
    log_error "[$SERVICE] Could not get API key"
    return 1
  fi

  local BASE_URL="http://localhost:$PORT/api/v3"

  # Check if download client already exists
  local EXISTING
  EXISTING=$(curl -s "$BASE_URL/downloadclient" -H "X-Api-Key: $API_KEY")

  if echo "$EXISTING" | grep -q "rdtclient"; then
    log_warn "[$SERVICE] Download client already exists, skipping"
    return 0
  fi

  local RESPONSE
  RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/downloadclient" \
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
    }')

  local HTTP_CODE
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)

  if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    log_info "[$SERVICE] Download client added ✅"
  else
    log_error "[$SERVICE] Failed to add download client (HTTP $HTTP_CODE): $(echo "$RESPONSE" | head -1)"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Configure each service
# -----------------------------------------------------------------------------
log_info "Configuring *arr services..."

wait_for_service "radarr"       7878
add_root_folder  "radarr"       7878 "/data/media/movies"
add_download_client "radarr"    7878

wait_for_service "sonarr"       8989
add_root_folder  "sonarr"       8989 "/data/media/shows"
add_download_client "sonarr"    8989

wait_for_service "sonarr-anime" 8990
add_root_folder  "sonarr-anime" 8990 "/data/media/anime"
add_download_client "sonarr-anime" 8990

wait_for_service "lidarr"       8686
add_root_folder  "lidarr"       8686 "/data/media/music"
add_download_client "lidarr"    8686

log_info "✅ All *arr services configured"