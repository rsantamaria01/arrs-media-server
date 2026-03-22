#!/bin/bash

# =============================================================================
# configure-nginx.sh - Replace ${DOMAIN} in config.template.json
# and place it where NPM can read it
# =============================================================================

MEDIASTACK_DIR="/opt/mediastack"

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -----------------------------------------------------------------------------
# Load .env
# -----------------------------------------------------------------------------
log_info "Loading environment variables..."
set -a
source "$MEDIASTACK_DIR/.env"
set +a

# -----------------------------------------------------------------------------
# Check required vars
# -----------------------------------------------------------------------------
if [ -z "$DOMAIN" ]; then
  log_error "DOMAIN is not set in your .env file"
  exit 1
fi

# -----------------------------------------------------------------------------
# Check template exists
# -----------------------------------------------------------------------------
TEMPLATE="$MEDIASTACK_DIR/services/nginx/config.template.json"

if [ ! -f "$TEMPLATE" ]; then
  log_error "config.template.json not found at $TEMPLATE"
  exit 1
fi

# -----------------------------------------------------------------------------
# Replace ${DOMAIN} and output to config.json
# -----------------------------------------------------------------------------
log_info "Generating config.json for domain: $DOMAIN"

sed "s/\${DOMAIN}/$DOMAIN/g" "$TEMPLATE" > "$MEDIASTACK_DIR/services/nginx/config.json"

log_info "✅ config.json generated at $MEDIASTACK_DIR/services/nginx/config.json"
```

---

# Make sure `config.json` is in your `.gitignore`: services/nginx/config.json