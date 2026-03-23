#!/bin/bash
# =============================================================================
# create-config-xml.sh - Generate config.xml for all *arr services
# Called by init.sh — assumes env vars and paths are already loaded
# =============================================================================

TEMPLATE="$REPO_DIR/services/arrs/templates/config.xml.template"

if [ ! -f "$TEMPLATE" ]; then
  log_error "Template not found: $TEMPLATE"
  exit 1
fi

generate_arr_config() {
  local SERVICE_NAME=$1
  local SERVICE_PORT=$2
  local CONFIG_DIR="$DATA_DIR/services/$SERVICE_NAME"
  local CONFIG_FILE="$CONFIG_DIR/config.xml"

  if [ -f "$CONFIG_FILE" ]; then
    log_warn "[$SERVICE_NAME] config.xml already exists, skipping"
    return 0
  fi

  log_info "[$SERVICE_NAME] Generating config.xml..."

  mkdir -p "$CONFIG_DIR"

  API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

  sed \
    -e "s|\${ADMIN_USERNAME}|${ADMIN_USERNAME}|g" \
    -e "s|\${ADMIN_PASSWORD}|${ADMIN_PASSWORD}|g" \
    -e "s|\${API_KEY}|${API_KEY}|g" \
    -e "s|\${PORT}|${SERVICE_PORT}|g" \
    "$TEMPLATE" > "$CONFIG_FILE"

  log_info "[$SERVICE_NAME] config.xml created ✅"
}

generate_arr_config "prowlarr"     9696
generate_arr_config "radarr"       7878
generate_arr_config "sonarr"       8989
generate_arr_config "sonarr-anime" 8989
generate_arr_config "lidarr"       8686