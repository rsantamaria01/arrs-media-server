#!/bin/sh

CONFIG_FILE=/config/config/config.yaml
APP='Bazarr'
BAZARR_PORT=6767
RADARR_HOST=radarr
RADARR_PORT=7878
SONARR_HOST=sonarr
SONARR_PORT=8989

# Only create if it doesn't exist yet
if [ -f "$CONFIG_FILE" ]; then
  echo "[init-bazarr] config.yaml already exists, skipping"
  exit 0
fi

mkdir -p /config/config

# Wait for Sonarr and Radarr config files to exist
echo "[init-bazarr] Waiting for Sonarr config..."
while [ ! -f /shared-config/sonarr/config.xml ]; do sleep 2; done
echo "[init-bazarr] Waiting for Radarr config..."
while [ ! -f /shared-config/radarr/config.xml ]; do sleep 2; done

SONARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/sonarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
RADARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/radarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')

PASSWORD_HASH=$(echo -n "${ADMIN_PASSWORD}" | md5sum | cut -d' ' -f1)
API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

echo "[init-bazarr] Sonarr key: ${SONARR_KEY}"
echo "[init-bazarr] Radarr key: ${RADARR_KEY}"
echo "[init-bazarr] Creating config.yaml..."

cat > "$CONFIG_FILE" << EOF
---
auth:
  apikey: ${API_KEY}
  password: ${PASSWORD_HASH}
  type: form
  username: ${ADMIN_USERNAME}
general:
  ip: '*'
  port: ${BAZARR_PORT}
  base_url: /
  branch: master
  auto_update: true
  debug: false
  chmod: '0640'
  chmod_enabled: false
  instance_name: ${APP}
  use_sonarr: true
  use_radarr: true
sonarr:
  apikey: ${SONARR_KEY}
  ip: ${SONARR_HOST}
  port: ${SONARR_PORT}
  ssl: false
  base_url: /
  http_timeout: 60
  only_monitored: false
  series_sync: 60
  series_sync_on_live: true
  full_update: Daily
  full_update_day: 6
  full_update_hour: 4
radarr:
  apikey: ${RADARR_KEY}
  ip: ${RADARR_HOST}
  port: ${RADARR_PORT}
  ssl: false
  base_url: /
  http_timeout: 60
  only_monitored: false
  movies_sync: 60
  movies_sync_on_live: true
  full_update: Daily
  full_update_day: 6
  full_update_hour: 4
EOF

chown -R 1000:1000 /config/config
echo "[init-bazarr] config.yaml created ✅"