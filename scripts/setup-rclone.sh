#!/bin/sh
set -e

CONFIG_FILE=/config/rclone.conf
MOUNT_DIR=/mnt/debrid
DEBRIDAV_HOST=http://debridav
DEBRIDAV_PORT=8080

mkdir -p "$MOUNT_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[rclone] Generating config..."
  mkdir -p "$(dirname "$CONFIG_FILE")"

  cat > "$CONFIG_FILE" <<EOF
[debridav]
type = webdav
url = ${DEBRIDAV_HOST}:${DEBRIDAV_PORT}
vendor = other
EOF

  echo "[rclone] Config written ✅"
fi

exec rclone mount debridav: "$MOUNT_DIR" \
  --config "$CONFIG_FILE" \
  --allow-other \
  --allow-non-empty \
  --dir-cache-time=10m \
  --vfs-cache-mode=minimal \
  --vfs-read-chunk-size=8M \
  --vfs-read-chunk-size-limit=64M \
  --buffer-size=16M \
  --poll-interval=15s \
  --log-level=INFO