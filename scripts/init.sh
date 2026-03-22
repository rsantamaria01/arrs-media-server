#!/bin/bash

# =============================================================================
# init.sh - First time setup for arrs-media-server
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
# Check if already initialized
# -----------------------------------------------------------------------------
if [ -f "$FLAG_FILE" ]; then
  log_warn "Server already initialized. Run update.sh instead."
  exit 0
fi

# -----------------------------------------------------------------------------
# Check .env file exists
# -----------------------------------------------------------------------------
log_info "Checking .env file..."

if [ ! -f "$MEDIASTACK_DIR/.env" ]; then
  log_error ".env file not found!"
  log_error "Please create one first: cp .env.template .env and fill in your values"
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
  log_error "Generate one with: openssl rand -hex 16"
  exit 1
fi

log_info "TZ=$TZ | PUID=$PUID | PGID=$PGID"

# -----------------------------------------------------------------------------
# Install Docker
# -----------------------------------------------------------------------------
log_info "Checking Docker installation..."

if ! command -v docker &> /dev/null; then
  log_info "Installing Docker..."
  apt-get update -y
  apt-get install -y docker.io
  systemctl enable docker
  systemctl start docker
  log_info "Docker installed successfully"
else
  log_info "Docker already installed: $(docker --version)"
fi

# -----------------------------------------------------------------------------
# Install docker-compose
# -----------------------------------------------------------------------------
log_info "Checking docker-compose installation..."

if ! command -v docker-compose &> /dev/null; then
  log_info "Installing docker-compose..."
  apt-get install -y docker-compose
  log_info "docker-compose installed successfully"
else
  log_info "docker-compose already installed: $(docker-compose --version)"
fi

# -----------------------------------------------------------------------------
# Create system group for media access
# -----------------------------------------------------------------------------
log_info "Setting up mediastack group..."

if ! getent group mediastack > /dev/null; then
  groupadd -g $PGID mediastack
  log_info "Group mediastack created with GID=$PGID"
else
  log_warn "Group mediastack already exists, skipping"
fi

# -----------------------------------------------------------------------------
# Create service users
# -----------------------------------------------------------------------------
log_info "Creating service users..."

create_user() {
  local username=$1
  if ! id "$username" &> /dev/null; then
    useradd -r -s /sbin/nologin "$username"
    usermod -a -G mediastack "$username"
    log_info "User $username created and added to mediastack group"
  else
    log_warn "User $username already exists, skipping"
  fi
}

create_user prowlarr
create_user sonarr
create_user radarr
create_user lidarr
create_user mylar
create_user bazarr
create_user jellyfin
create_user jellyseerr
create_user kavita
create_user homarr

# -----------------------------------------------------------------------------
# Create service config directories
# -----------------------------------------------------------------------------
log_info "Creating service config directories..."

mkdir -p "$MEDIASTACK_DIR/services/"{prowlarr,sonarr,sonarr-anime,radarr,lidarr,mylar,kavita,bazarr,jellyfin,jellyseerr,homarr,npm/data,npm/letsencrypt}

log_info "Service config directories created"

# -----------------------------------------------------------------------------
# Create media data directories
# -----------------------------------------------------------------------------
log_info "Creating media data directories..."

mkdir -p "$DATA_DIR/media/"{movies,tv,music,books}

log_info "Media data directories created"

# -----------------------------------------------------------------------------
# Set permissions
# -----------------------------------------------------------------------------
log_info "Setting permissions..."

# Data directory — all service users need read/write
chmod -R 775 "$DATA_DIR"
chown -R $PUID:$PGID "$DATA_DIR"

# Mediastack config directory — owned by root, group access for services
chmod -R 775 "$MEDIASTACK_DIR/services"
chown -R $PUID:$PGID "$MEDIASTACK_DIR/services"

# Per service config ownership
chown -R prowlarr:mediastack  "$MEDIASTACK_DIR/services/prowlarr"
chown -R sonarr:mediastack    "$MEDIASTACK_DIR/services/sonarr"
chown -R sonarr:mediastack    "$MEDIASTACK_DIR/services/sonarr-anime"
chown -R radarr:mediastack    "$MEDIASTACK_DIR/services/radarr"
chown -R lidarr:mediastack    "$MEDIASTACK_DIR/services/lidarr"
chown -R mylar:mediastack     "$MEDIASTACK_DIR/services/mylar"
chown -R kavita:mediastack    "$MEDIASTACK_DIR/services/kavita"
chown -R bazarr:mediastack    "$MEDIASTACK_DIR/services/bazarr"
chown -R jellyfin:mediastack  "$MEDIASTACK_DIR/services/jellyfin"
chown -R jellyseerr:mediastack "$MEDIASTACK_DIR/services/jellyseerr"
chown -R homarr:mediastack    "$MEDIASTACK_DIR/services/homarr"

log_info "Permissions set"

# -----------------------------------------------------------------------------
# Start the stack
# -----------------------------------------------------------------------------
log_info "Pulling Docker images..."
cd "$MEDIASTACK_DIR"
docker-compose pull

log_info "Starting the stack..."
docker-compose up -d --remove-orphans

# -----------------------------------------------------------------------------
# Verify containers are running
# -----------------------------------------------------------------------------
log_info "Verifying containers..."
docker-compose ps

# -----------------------------------------------------------------------------
# Create flag file
# -----------------------------------------------------------------------------
touch "$FLAG_FILE"
echo "Initialized on $(date)" > "$FLAG_FILE"

log_info "✅ Initialization complete! Flag file created at $FLAG_FILE"
log_info "Next deployments will automatically run update.sh instead"