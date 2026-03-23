#!/bin/bash
# =============================================================================
# create-rclone-conf.sh - Generate rclone.conf for TorBox WebDAV
# Called by init.sh — assumes env vars and paths are already loaded
# =============================================================================

TEMPLATE="$REPO_DIR/services/rclone/templates/rclone.conf.template"
CONFIG_DIR="$DATA_DIR/services/rclone/rclone"
CONFIG_FILE="$CONFIG_DIR/rclone.conf"

if [ ! -f "$TEMPLATE" ]; then
  log_error "Template not found: $TEMPLATE"
  exit 1
fi

if [ -f "$CONFIG_FILE" ]; then
  log_warn "[rclone] rclone.conf already exists, skipping"
  return 0
fi

log_info "[rclone] Generating rclone.conf..."

mkdir -p "$CONFIG_DIR"

# Obscure password using rclone Docker image
TORBOX_PASSWORD_OBSCURED=$(docker run --rm rclone/rclone:latest obscure "${TORBOX_PASSWORD}")

sed \
  -e "s|\${TORBOX_USERNAME}|${TORBOX_USERNAME}|g" \
  -e "s|\${TORBOX_PASSWORD_OBSCURED}|${TORBOX_PASSWORD_OBSCURED}|g" \
  "$TEMPLATE" > "$CONFIG_FILE"

log_info "[rclone] rclone.conf created ✅"