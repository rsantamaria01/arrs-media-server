#!/bin/bash
# =============================================================================
# reset.sh - Tear down and clean up arrs-media-server
# WARNING: Stops all containers and removes service users
# Your media in /opt/data will NOT be deleted
# =============================================================================
set -e

FLAG_FILE="/opt/mediastack/services/.initialized"
MEDIASTACK_DIR="/opt/mediastack"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Confirm
# -----------------------------------------------------------------------------
log_warn "⚠️  This will stop all containers and remove all service users."
log_warn "Your media files in /opt/data will NOT be deleted."
read -p "Are you sure? (yes/no): " CONFIRM
[ "$CONFIRM" != "yes" ] && log_info "Aborted." && exit 0

# -----------------------------------------------------------------------------
# Stop containers
# -----------------------------------------------------------------------------
log_info "Stopping containers..."
cd "$MEDIASTACK_DIR"
docker-compose down
log_info "Containers stopped"

# -----------------------------------------------------------------------------
# Remove service users
# -----------------------------------------------------------------------------
log_info "Removing service users..."

remove_user() {
  local u=$1
  id "$u" &> /dev/null && userdel "$u" && log_info "User $u removed" \
    || log_warn "User $u not found, skipping"
}

remove_user prowlarr
remove_user sonarr
remove_user radarr
remove_user lidarr
remove_user bazarr
remove_user jellyfin
remove_user jellyseerr
remove_user homarr

# -----------------------------------------------------------------------------
# Remove group
# -----------------------------------------------------------------------------
getent group mediastack > /dev/null \
  && groupdel mediastack && log_info "Group mediastack removed" \
  || log_warn "Group mediastack not found, skipping"

# -----------------------------------------------------------------------------
# Remove flag file and clean Docker
# -----------------------------------------------------------------------------
[ -f "$FLAG_FILE" ] && rm "$FLAG_FILE" && log_info "Flag file removed"
docker image prune -af
log_info "Docker images cleaned"

log_info "✅ Reset complete! Run init.sh to start fresh."
log_warn "Your media files in /opt/data are untouched."