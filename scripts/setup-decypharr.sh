#!/bin/sh

CONFIG_FILE=/data/config.json

if [ -f "$CONFIG_FILE" ]; then
  echo "[setup-decypharr] config.json already exists, skipping"
  exit 0
fi

echo "[setup-decypharr] Creating config.json..."

cat > "$CONFIG_FILE" <<EOF
{
  "debrids": [
    {
      "name": "torbox",
      "api_key": "${TORBOX_APIKEY}",
      "folder": "/mnt/remote/torbox/__all__/",
      "use_webdav": true,
      "download_uncached": false
    }
  ],
  "qbittorrent": {
    "host": "0.0.0.0",
    "port": "8282",
    "download_folder": "/mnt/remote/torbox/__all__/",
    "categories": ["radarr", "tv-sonarr", "tv-sonarr-anime", "lidarr"]
  },
  "rclone": {
    "enabled": true,
    "mount_path": "/mnt/remote",
    "uid": ${PUID},
    "gid": ${PGID}
  }
}
EOF

echo "[setup-decypharr] config.json created ✅"