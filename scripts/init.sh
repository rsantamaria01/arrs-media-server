#!/bin/bash
# =============================================================================
# init.sh - First time setup for arrs-media-server
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
# Check if already initialized
# -----------------------------------------------------------------------------
if [ -f "$FLAG_FILE" ]; then
  log_warn "Already initialized. Run update.sh instead."
  exit 0
fi

# -----------------------------------------------------------------------------
# Check .env
# -----------------------------------------------------------------------------
log_info "Checking .env file..."
if [ ! -f "$MEDIASTACK_DIR/.env" ]; then
  log_error ".env not found! Run: cp .env.template .env and fill in your values"
  exit 1
fi

set -a; source "$MEDIASTACK_DIR/.env"; set +a

[ -z "$TZ" ]               && log_error "TZ is not set in .env"               && exit 1
[ -z "$PUID" ]             && log_error "PUID is not set in .env"             && exit 1
[ -z "$PGID" ]             && log_error "PGID is not set in .env"             && exit 1
[ -z "$HOMARR_SECRET" ]    && log_error "HOMARR_SECRET is not set in .env"    && exit 1
[ -z "$DOMAIN" ]           && log_error "DOMAIN is not set in .env"           && exit 1
[ -z "$TORBOX_API_KEY" ]   && log_error "TORBOX_API_KEY is not set in .env"   && exit 1
[ -z "$RDTCLIENT_USER" ]   && log_error "RDTCLIENT_USER is not set in .env"   && exit 1
[ -z "$RDTCLIENT_PASSWORD" ] && log_error "RDTCLIENT_PASSWORD is not set in .env" && exit 1

log_info "TZ=$TZ | PUID=$PUID | PGID=$PGID | DOMAIN=$DOMAIN"

# -----------------------------------------------------------------------------
# Install Docker
# -----------------------------------------------------------------------------
log_info "Checking Docker..."
if ! command -v docker &> /dev/null; then
  apt-get update -y && apt-get install -y docker.io
  systemctl enable docker && systemctl start docker
  log_info "Docker installed"
else
  log_info "Docker already installed: $(docker --version)"
fi

# -----------------------------------------------------------------------------
# Install Docker Compose plugin
# -----------------------------------------------------------------------------
log_info "Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
  apt-get install -y docker-compose-plugin
  log_info "Docker Compose plugin installed"
else
  log_info "Docker Compose already installed: $(docker compose version)"
fi

# -----------------------------------------------------------------------------
# Create group and users
# -----------------------------------------------------------------------------
log_info "Setting up mediastack group and users..."

getent group mediastack > /dev/null || groupadd -g $PGID mediastack

create_user() {
  local u=$1
  if ! id "$u" &> /dev/null; then
    useradd -r -s /sbin/nologin "$u"
    usermod -a -G mediastack "$u"
    log_info "User $u created"
  else
    log_warn "User $u already exists, skipping"
  fi
}

create_user prowlarr
create_user sonarr
create_user radarr
create_user lidarr
create_user bazarr
create_user jellyfin
create_user jellyseerr
create_user homarr
create_user rdtclient

# -----------------------------------------------------------------------------
# Create media data directories
# -----------------------------------------------------------------------------
log_info "Creating media directories..."
mkdir -p "$DATA_DIR/media/"{movies,tv,music}
mkdir -p "$DATA_DIR/downloads"
log_info "Media directories created"

# -----------------------------------------------------------------------------
# Set permissions
# -----------------------------------------------------------------------------
log_info "Setting permissions..."

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
chown -R rdtclient:mediastack  "$MEDIASTACK_DIR/services/rdtclient"

log_info "Permissions set"

# -----------------------------------------------------------------------------
# Start the stack
# -----------------------------------------------------------------------------
log_info "Pulling images and starting stack..."
cd "$MEDIASTACK_DIR"
docker compose pull
docker compose up -d --remove-orphans
docker compose ps

# -----------------------------------------------------------------------------
# Configure
# -----------------------------------------------------------------------------
log_info "Running configuration scripts..."
bash "$MEDIASTACK_DIR/scripts/configure-prowlarr.sh"
bash "$MEDIASTACK_DIR/scripts/configure-rdtclient.sh"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo "Initialized on $(date)" > "$FLAG_FILE"
log_info "✅ Init complete!"
log_warn "⚠️  Manual steps still required:"
log_warn "   1. Go to rdtclient.$DOMAIN and complete Torbox setup"
log_warn "   2. Go to bazarr.$DOMAIN and configure subtitle languages"
log_warn "   3. Go to jellyseerr.$DOMAIN and connect to Jellyfin"