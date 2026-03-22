#!/bin/bash

# =============================================================================
# update.sh - Update arrs-media-server stack
# =============================================================================

set -e  # Exit immediately if any command fails

FLAG_FILE="/opt/mediastack/services/.initialized"
MEDIASTACK_DIR="/opt/mediastack"
DATA_DIR="/opt/data"

# -----------------------------------------------------------------------------
# Colors for output
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Check if initialized — if not, redirect to init.sh
# -----------------------------------------------------------------------------
if [ ! -f "$FLAG_FILE" ]; then
  log_warn "Server not initialized yet. Running init.sh instead..."
  bash "$MEDIASTACK_DIR/scripts/init.sh"
  exit 0
fi

log_info "Server already initialized. Proceeding with update..."
log_info "$(cat $FLAG_FILE)"

# -----------------------------------------------------------------------------
# Check .env file exists
# -----------------------------------------------------------------------------
log_info "Checking .env file..."

if [ ! -f "$MEDIASTACK_DIR/.env" ]; then
  log_error ".env file not found!"
  log_error "Please recreate it from the template: cp .env.template .env"
  exit 1
fi

log_info ".env file found"

# -----------------------------------------------------------------------------
# Load and validate environment variables
# -----------------------------------------------------------------------------
log_info "Loading environment variables..."
set -a
source "$MEDIASTACK_DIR/.env"
set +a

if [ -z "$TZ" ]; then
  log_error "TZ is not set in your .env file"
  exit 1
fi

if [ -z "$PUID" ]; then
  log_error "PUID is not set in your .env file"
  exit 1
fi

if [ -z "$PGID" ]; then
  log_error "PGID is not set in your .env file"
  exit 1
fi

if [ -z "$HOMARR_SECRET" ]; then
  log_error "HOMARR_SECRET is not set in your .env file"
  exit 1
fi

log_info "TZ=$TZ | PUID=$PUID | PGID=$PGID"

# -----------------------------------------------------------------------------
# Check Docker is running
# -----------------------------------------------------------------------------
log_info "Checking Docker..."

if ! systemctl is-active --quiet docker; then
  log_warn "Docker is not running, starting it..."
  systemctl start docker
fi

log_info "Docker is running"

# -----------------------------------------------------------------------------
# Pull latest code
# -----------------------------------------------------------------------------
log_info "Pulling latest code from GitHub..."
cd "$MEDIASTACK_DIR"
git pull origin main
log_info "Code updated"

# -----------------------------------------------------------------------------
# Ensure all service directories exist
# (in case new services were added)
# -----------------------------------------------------------------------------
log_info "Ensuring service config directories exist..."

mkdir -p "$MEDIASTACK_DIR/services/"{prowlarr,sonarr,sonarr-anime,radarr,lidarr,mylar,kavita,bazarr,jellyfin,jellyseerr,homarr,npm/data,npm/letsencrypt}

log_info "Service config directories verified"

# -----------------------------------------------------------------------------
# Ensure media data directories exist
# (in case new categories were added)
# -----------------------------------------------------------------------------
log_info "Ensuring media data directories exist..."

mkdir -p "$DATA_DIR/media/"{movies,tv,music,books}

log_info "Media data directories verified"

# -----------------------------------------------------------------------------
# Ensure permissions are correct
# (in case new directories were created)
# -----------------------------------------------------------------------------
log_info "Verifying permissions..."

chmod -R 775 "$DATA_DIR"
chown -R $PUID:$PGID "$DATA_DIR"

chmod -R 775 "$MEDIASTACK_DIR/services"
chown -R $PUID:$PGID "$MEDIASTACK_DIR/services"

# Per service config ownership
chown -R prowlarr:mediastack   "$MEDIASTACK_DIR/services/prowlarr"
chown -R sonarr:mediastack     "$MEDIASTACK_DIR/services/sonarr"
chown -R sonarr:mediastack     "$MEDIASTACK_DIR/services/sonarr-anime"
chown -R radarr:mediastack     "$MEDIASTACK_DIR/services/radarr"
chown -R lidarr:mediastack     "$MEDIASTACK_DIR/services/lidarr"
chown -R mylar:mediastack      "$MEDIASTACK_DIR/services/mylar"
chown -R kavita:mediastack     "$MEDIASTACK_DIR/services/kavita"
chown -R bazarr:mediastack     "$MEDIASTACK_DIR/services/bazarr"
chown -R jellyfin:mediastack   "$MEDIASTACK_DIR/services/jellyfin"
chown -R jellyseerr:mediastack "$MEDIASTACK_DIR/services/jellyseerr"
chown -R homarr:mediastack     "$MEDIASTACK_DIR/services/homarr"

log_info "Permissions verified"

# -----------------------------------------------------------------------------
# Pull latest Docker images
# -----------------------------------------------------------------------------
log_info "Pulling latest Docker images..."
cd "$MEDIASTACK_DIR"
docker-compose pull
log_info "Images updated"

# -----------------------------------------------------------------------------
# Restart the stack
# -----------------------------------------------------------------------------
log_info "Restarting the stack..."
docker-compose up -d --remove-orphans
log_info "Stack restarted"

# -----------------------------------------------------------------------------
# Clean up unused images
# -----------------------------------------------------------------------------
log_info "Cleaning up unused Docker images..."
docker image prune -f
log_info "Cleanup complete"

# -----------------------------------------------------------------------------
# Verify containers are running
# -----------------------------------------------------------------------------
log_info "Verifying containers..."
docker-compose ps

# -----------------------------------------------------------------------------
# Update the flag file timestamp
# -----------------------------------------------------------------------------
INIT_DATE=$(grep "Initialized on" "$FLAG_FILE" | head -1)
echo "$INIT_DATE
Last updated on $(date)" > "$FLAG_FILE"

log_info "✅ Update complete!"