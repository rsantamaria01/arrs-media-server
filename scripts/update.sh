#!/bin/bash
# =============================================================================
# update.sh - Update arrs-media-server
# =============================================================================
set -e

FLAG_FILE="/opt/mediastack/services/.initialized"
MEDIASTACK_DIR="/opt/mediastack"
DATA_DIR="/opt/data"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Check initialized
# -----------------------------------------------------------------------------
if [ ! -f "$FLAG_FILE" ]; then
  log_warn "Not initialized yet. Running init.sh..."
  bash "$MEDIASTACK_DIR/scripts/init.sh"
  exit 0
fi

log_info "$(cat $FLAG_FILE)"

# -----------------------------------------------------------------------------
# Check .env
# -----------------------------------------------------------------------------
if [ ! -f "$MEDIASTACK_DIR/.env" ]; then
  log_error ".env not found! Recreate it from .env.template"
  exit 1
fi

set -a; source "$MEDIASTACK_DIR/.env"; set +a

[ -z "$TZ" ]            && log_error "TZ is not set in .env"            && exit 1
[ -z "$PUID" ]          && log_error "PUID is not set in .env"          && exit 1
[ -z "$PGID" ]          && log_error "PGID is not set in .env"          && exit 1
[ -z "$HOMARR_SECRET" ] && log_error "HOMARR_SECRET is not set in .env" && exit 1
[ -z "$DOMAIN" ]        && log_error "DOMAIN is not set in .env"        && exit 1

# -----------------------------------------------------------------------------
# Check Docker
# -----------------------------------------------------------------------------
systemctl is-active --quiet docker || systemctl start docker
log_info "Docker is running"

# -----------------------------------------------------------------------------
# Pull latest code
# -----------------------------------------------------------------------------
log_info "Pulling latest code..."
cd "$MEDIASTACK_DIR"
git pull origin main

# -----------------------------------------------------------------------------
# Ensure media directories exist
# -----------------------------------------------------------------------------
mkdir -p "$DATA_DIR/media/"{movies,tv,music}

# -----------------------------------------------------------------------------
# Set permissions
# -----------------------------------------------------------------------------
log_info "Verifying permissions..."

chmod -R 775 "$DATA_DIR"
chown -R $PUID:$PGID "$DATA_DIR"

chmod -R 775 "$MEDIASTACK_DIR/services"
chown -R $PUID:$PGID "$MEDIASTACK_DIR/services"

chown -R prowlarr:mediastack   "$MEDIASTACK_DIR/services/prowlarr"
chown -R sonarr:mediastack     "$MEDIASTACK_DIR/services/sonarr"
chown -R sonarr:mediastack     "$MEDIASTACK_DIR/services/sonarr-anime"
chown -R radarr:mediastack     "$MEDIASTACK_DIR/services/radarr"
chown -R lidarr:mediastack     "$MEDIASTACK_DIR/services/lidarr"
chown -R bazarr:mediastack     "$MEDIASTACK_DIR/services/bazarr"
chown -R jellyfin:mediastack   "$MEDIASTACK_DIR/services/jellyfin"
chown -R jellyseerr:mediastack "$MEDIASTACK_DIR/services/jellyseerr"
chown -R homarr:mediastack     "$MEDIASTACK_DIR/services/homarr"

# -----------------------------------------------------------------------------
# Pull images and restart
# -----------------------------------------------------------------------------
log_info "Updating stack..."
docker-compose pull
docker-compose up -d --remove-orphans
docker image prune -f
docker-compose ps

# -----------------------------------------------------------------------------
# Update flag file
# -----------------------------------------------------------------------------
INIT_DATE=$(grep "Initialized on" "$FLAG_FILE" | head -1)
echo "$INIT_DATE
Last updated on $(date)" > "$FLAG_FILE"

log_info "✅ Update complete!"