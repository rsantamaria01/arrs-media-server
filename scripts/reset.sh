#!/bin/bash

# =============================================================================
# reset.sh - Tear down and clean up arrs-media-server
# WARNING: This will stop all containers and remove all service users
# Your media data in /opt/data will NOT be deleted
# =============================================================================

FLAG_FILE="/opt/mediastack/services/.initialized"
MEDIASTACK_DIR="/opt/mediastack"

# -----------------------------------------------------------------------------
# Colors for output
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Confirm before proceeding
# -----------------------------------------------------------------------------
log_warn "⚠️  WARNING: This will stop all containers and remove all service users."
log_warn "Your media files in /opt/data/media will NOT be deleted."
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  log_info "Aborted."
  exit 0
fi

# -----------------------------------------------------------------------------
# Stop and remove all containers
# -----------------------------------------------------------------------------
log_info "Stopping all containers..."
cd "$MEDIASTACK_DIR"
docker-compose down
log_info "Containers stopped"

# -----------------------------------------------------------------------------
# Remove service users
# -----------------------------------------------------------------------------
log_info "Removing service users..."

remove_user() {
  local username=$1
  if id "$username" &> /dev/null; then
    userdel "$username"
    log_info "User $username removed"
  else
    log_warn "User $username does not exist, skipping"
  fi
}

remove_user prowlarr
remove_user sonarr
remove_user radarr
remove_user lidarr
remove_user mylar
remove_user kavita
remove_user bazarr
remove_user jellyfin
remove_user jellyseerr
remove_user homarr

# -----------------------------------------------------------------------------
# Remove mediastack group
# -----------------------------------------------------------------------------
log_info "Removing mediastack group..."

if getent group mediastack > /dev/null; then
  groupdel mediastack
  log_info "Group mediastack removed"
else
  log_warn "Group mediastack does not exist, skipping"
fi

# -----------------------------------------------------------------------------
# Remove flag file so init.sh can run again
# -----------------------------------------------------------------------------
if [ -f "$FLAG_FILE" ]; then
  rm "$FLAG_FILE"
  log_info "Flag file removed"
fi

# -----------------------------------------------------------------------------
# Clean up unused Docker images
# -----------------------------------------------------------------------------
log_info "Cleaning up Docker images..."
docker image prune -af
log_info "Docker images cleaned"

log_info "✅ Reset complete!"
log_warn "Your media files in /opt/data/media are untouched."
log_info "You can now run init.sh to start fresh."