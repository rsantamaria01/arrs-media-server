#!/bin/sh
# entrypoint.sh - runs at container startup, has access to runtime env vars

set -e

CONFIG_FILE=/config/rclone.conf
MOUNT_DIR=/mnt/rclone

# Create mount dir if it doesn't exist
mkdir -p "$MOUNT_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[rclone] Generating config..."
  TORBOX_PASSWORD_OBSCURED=$(rclone obscure "$TORBOX_PASSWORD")

  mkdir -p "$(dirname "$CONFIG_FILE")"

  cat > "$CONFIG_FILE" <<EOF
[torbox]
type = webdav
url = https://webdav.torbox.app
vendor = other
user = ${TORBOX_USERNAME}
pass = ${TORBOX_PASSWORD_OBSCURED}
EOF
  echo "[rclone] Config written ✅"
fi

# Run in foreground (no --daemon)
exec rclone mount torbox: /mnt/rclone \
  --config "$CONFIG_FILE" \
  --allow-other \
  --allow-non-empty \
  --dir-cache-time=0 \
  --vfs-cache-mode=minimal \
  --log-level=INFO