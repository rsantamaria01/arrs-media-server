#!/bin/bash
# =============================================================================
# setup-prowlarr.sh - Configure Prowlarr via API
# Connects Radarr, Sonarr, Lidarr and Sonarr-Anime as applications
# Called by init.sh after containers are running
# Assumes: REPO_DIR, DATA_DIR, ADMIN_USERNAME, ADMIN_PASSWORD are set
# =============================================================================

API_KEY=$(grep -oP '(?<=<ApiKey>).*(?=</ApiKey>)' "$DATA_DIR/services/prowlarr/config.xml")
BASE_URL="http://localhost:9696/api/v1"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

get_arr_api_key() {
  local SERVICE=$1
  grep -oP '(?<=<ApiKey>).*(?=</ApiKey>)' "$DATA_DIR/services/$SERVICE/config.xml"
}

wait_for_service() {
  local MAX=60
  local ELAPSED=0
  log_info "[prowlarr] Waiting for service to be ready..."
  until curl -s -o /dev/null "http://localhost:9696/api/v1/system/status"; do
    sleep 3
    ELAPSED=$((ELAPSED + 3))
    [ $ELAPSED -ge $MAX ] && log_error "[prowlarr] Timed out waiting" && exit 1
  done
  log_info "[prowlarr] Ready ✅"
}

add_application() {
  local NAME=$1
  local PORT=$2
  local IMPL=$3
  local ARR_API_KEY=$(get_arr_api_key "${NAME,,}")

  # Check if already exists
  EXISTING=$(curl -s "$BASE_URL/applications" \
    -H "X-Api-Key: $API_KEY" | grep -c "\"name\":\"$NAME\"" || true)

  if [ "$EXISTING" -gt 0 ]; then
    log_warn "[prowlarr] $NAME already connected, skipping"
    return 0
  fi

  curl -s "$BASE_URL/applications" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$NAME\",
      \"syncLevel\": \"fullSync\",
      \"implementation\": \"$IMPL\",
      \"configContract\": \"${IMPL}Settings\",
      \"fields\": [
        {\"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\"},
        {\"name\": \"baseUrl\", \"value\": \"http://${NAME,,}:$PORT\"},
        {\"name\": \"apiKey\", \"value\": \"$ARR_API_KEY\"},
        {\"name\": \"syncCategories\", \"value\": [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060]}
      ]
    }" > /dev/null

  log_info "[prowlarr] $NAME connected ✅"
}

# -----------------------------------------------------------------------------
# Configure
# -----------------------------------------------------------------------------
log_info "Configuring Prowlarr..."

wait_for_service

add_application "Radarr"       7878 "Radarr"
add_application "Sonarr"       8989 "Sonarr"
add_application "Sonarr-Anime" 8990 "Sonarr"
add_application "Lidarr"       8686 "Lidarr"

log_info "✅ Prowlarr configured"