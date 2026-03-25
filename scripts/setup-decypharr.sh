#!/bin/sh

CONFIG_FILE=/data/config.json
SONARR_HOST=http://sonarr
SONARR_PORT=8989
SONARR_ANIME_HOST=http://sonarr-anime
SONARR_ANIME_PORT=8989
RADARR_HOST=http://radarr
RADARR_PORT=7878
LIDARR_HOST=http://lidarr
LIDARR_PORT=8686

echo "[setup-decypharr] Waiting for Radarr..."
while ! nc -z "${RADARR_HOST#http://}" "${RADARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
RADARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/radarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup-decypharr] Radarr key: ${RADARR_KEY}"

echo "[setup-decypharr] Waiting for Lidarr..."
while ! nc -z "${LIDARR_HOST#http://}" "${LIDARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
LIDARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/lidarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup-decypharr] Lidarr key: ${LIDARR_KEY}"

echo "[setup-decypharr] Waiting for Sonarr Anime..."
while ! nc -z "${SONARR_ANIME_HOST#http://}" "${SONARR_ANIME_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
SONARR_ANIME_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/sonarr-anime/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup-decypharr] Sonarr Anime key: ${SONARR_ANIME_KEY}"

echo "[setup-decypharr] Waiting for Sonarr..."
while ! nc -z "${SONARR_HOST#http://}" "${SONARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
SONARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/sonarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup-decypharr] Sonarr key: ${SONARR_KEY}"

echo "[setup-decypharr] Creating config.json..."

cat > "$CONFIG_FILE" <<EOF
{
  "auth": {
    "username": "${ADMIN_USERNAME}",
    "password": "${ADMIN_PASSWORD}"
  },
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
  "arrs": [
    {
      "name": "Sonarr",
      "host": "${SONARR_HOST}:${SONARR_PORT}",
      "token": "${SONARR_KEY}",
      "download_uncached": false
    },
    {
      "name": "Sonarr Anime",
      "host": "${SONARR_ANIME_HOST}:${SONARR_ANIME_PORT}",
      "token": "${SONARR_ANIME_KEY}",
      "download_uncached": false
    },
    {
      "name": "Radarr",
      "host": "${RADARR_HOST}:${RADARR_PORT}",
      "token": "${RADARR_KEY}",
      "download_uncached": false
    },
    {
      "name": "Lidarr",
      "host": "${LIDARR_HOST}:${LIDARR_PORT}",
      "token": "${LIDARR_KEY}",
      "download_uncached": false
    }
  ],
  "rclone": {
    "enabled": true,
    "mount_path": "/mnt/remote",
    "uid": ${PUID},
    "gid": ${PGID}
  }
}
EOF

echo "[setup-decypharr] config.json created ✅"