#!/bin/bash
# =============================================================================
# init.sh - First time setup for arrs-media-server
# =============================================================================
set -e

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
REPO_DIR="/root/arrs-media-server"
DATA_DIR="/opt/data"
RCLONE_DIR="/mnt/rclone"

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Load and validate .env
# -----------------------------------------------------------------------------
if [ ! -f "$REPO_DIR/.env" ]; then
  log_error ".env not found! Run: cp .env.template .env and fill in your values"
  exit 1
fi

set -a; source "$REPO_DIR/.env"; set +a

log_info "Validating .env against .env.template..."
MISSING=0
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
  VAR_NAME=$(echo "$line" | cut -d'=' -f1 | tr -d ' ')
  [ -z "$VAR_NAME" ] && continue
  VAR_VALUE=$(eval echo "\${$VAR_NAME}")
  TEMPLATE_VALUE=$(echo "$line" | cut -d'=' -f2- | tr -d ' ')
  if [ -z "$VAR_VALUE" ] || [ "$VAR_VALUE" = "$TEMPLATE_VALUE" ]; then
    log_error "$VAR_NAME is not set or still has template default value"
    MISSING=1
  else
    log_info "$VAR_NAME=✅"
  fi
done < <(cat "$REPO_DIR/.env.template"; echo)
[ "$MISSING" -eq 1 ] && log_error "Fix missing .env values and re-run" && exit 1
log_info "All .env variables validated ✅"

# -----------------------------------------------------------------------------
# Create base directories
# -----------------------------------------------------------------------------
log_info "Creating base directories..."
mkdir -p "$RCLONE_DIR"
mkdir -p "$DATA_DIR"
log_info "Done: $RCLONE_DIR and $DATA_DIR created"

# -----------------------------------------------------------------------------
# Run service configuration scripts
# -----------------------------------------------------------------------------
log_info "Running service configuration scripts..."

source "$REPO_DIR/services/arrs/scripts/create-config-xml.sh"
source "$REPO_DIR/services/rclone/scripts/create-rclone-conf.sh"

# -----------------------------------------------------------------------------
# Start stack
# -----------------------------------------------------------------------------
log_info "Starting stack..."
cd "$REPO_DIR" && docker compose up -d

# Wait for containers to be healthy
log_info "Waiting for containers to be ready..."
TIMEOUT=120
ELAPSED=0
INTERVAL=5

while [ $ELAPSED -lt $TIMEOUT ]; do
  RUNNING=$(docker compose ps --status running --format json | grep -c '"Name"' || true)
  TOTAL=$(docker compose ps --format json | grep -c '"Name"' || true)

  if [ "$RUNNING" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    log_info "All $TOTAL containers are running ✅"
    break
  fi

  log_info "Waiting... ($RUNNING/$TOTAL running, ${ELAPSED}s elapsed)"
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  log_error "Timed out waiting for containers. Check: docker compose ps"
  exit 1
fi

# -----------------------------------------------------------------------------
# Run service setup scripts
# -----------------------------------------------------------------------------
log_info "Running service setup scripts..."
source "$REPO_DIR/services/arrs/scripts/setup-arrs.sh"
source "$REPO_DIR/services/arrs/scripts/setup-prowlarr.sh"

log_info "✅ Init complete!"
log_warn "⚠️  Manual steps still required:"
log_warn "   1. Go to jellyseerr.$DOMAIN and complete setup wizard"
log_warn "   2. Go to rdtclient.$DOMAIN and configure TorBox"
log_warn "   3. Go to bazarr.$DOMAIN and configure subtitle languages"