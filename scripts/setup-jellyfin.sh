#!/bin/sh

. /config/.env

APP='Jellyfin'
JELLYFIN_HOST=http://jellyfin
JELLYFIN_PORT=8096
DECYPHARR_HOST=http://decypharr
DECYPHARR_PORT=8282
SONARR_HOST=http://sonarr
SONARR_PORT=8989
SONARR_API_VERSION=v3
SONARR_ANIME_HOST=http://sonarr-anime
SONARR_ANIME_PORT=8989
SONARR_ANIME_API_VERSION=v3
RADARR_HOST=http://radarr
RADARR_PORT=7878
RADARR_API_VERSION=v3
LIDARR_HOST=http://lidarr
LIDARR_PORT=8686
LIDARR_API_VERSION=v1

# ─── Wait for Decypharr mount ─────────────────────────────────────────────────
echo "[setup] Waiting for Decypharr mount..."
while [ ! -d /mnt/remote/torbox/__all__ ]; do sleep 2; done
echo "[setup] Decypharr mount ready ✅"

# ─── Add Radarr root folder ───────────────────────────────────────────────────
RADARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/radarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Adding Radarr root folder..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${RADARR_HOST}:${RADARR_PORT}/api/${RADARR_API_VERSION}/rootfolder" \
  -H "X-Api-Key: ${RADARR_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"path\":\"/mnt/remote/torbox/__all__\"}")
echo "[setup] Radarr root folder response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Radarr root folder added ✅"
else
  echo "[setup] Radarr root folder failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Sonarr root folder ───────────────────────────────────────────────────
SONARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/sonarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Adding Sonarr root folder..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${SONARR_HOST}:${SONARR_PORT}/api/${SONARR_API_VERSION}/rootfolder" \
  -H "X-Api-Key: ${SONARR_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"path\":\"/mnt/remote/torbox/__all__\"}")
echo "[setup] Sonarr root folder response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Sonarr root folder added ✅"
else
  echo "[setup] Sonarr root folder failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Sonarr Anime root folder ─────────────────────────────────────────────
SONARR_ANIME_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/sonarr-anime/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Adding Sonarr Anime root folder..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${SONARR_ANIME_HOST}:${SONARR_ANIME_PORT}/api/${SONARR_ANIME_API_VERSION}/rootfolder" \
  -H "X-Api-Key: ${SONARR_ANIME_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"path\":\"/mnt/remote/torbox/__all__\"}")
echo "[setup] Sonarr Anime root folder response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Sonarr Anime root folder added ✅"
else
  echo "[setup] Sonarr Anime root folder failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Lidarr root folder ───────────────────────────────────────────────────
LIDARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/lidarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Adding Lidarr root folder..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${LIDARR_HOST}:${LIDARR_PORT}/api/${LIDARR_API_VERSION}/rootfolder" \
  -H "X-Api-Key: ${LIDARR_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"path\":\"/mnt/remote/torbox/__all__\",\"name\":\"Music\",\"defaultMetadataProfileId\":1,\"defaultQualityProfileId\":1}")
echo "[setup] Lidarr root folder response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Lidarr root folder added ✅"
else
  echo "[setup] Lidarr root folder failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Wait for Jellyfin ────────────────────────────────────────────────────────
echo "[setup] Waiting for ${APP} on port ${JELLYFIN_PORT}..."
while ! nc -z "${JELLYFIN_HOST#http://}" "${JELLYFIN_PORT}" 2>/dev/null; do sleep 2; done

echo "[setup] Waiting for startup wizard..."
while true; do
  WIZARD=$(curl -s "${JELLYFIN_HOST}:${JELLYFIN_PORT}/System/Info/Public" | grep -o '"StartupWizardCompleted":[^,}]*' | grep -o 'true\|false')
  if [ "$WIZARD" = "false" ]; then
    echo "[setup] Wizard is available ✅"
    break
  fi
  sleep 1
done

echo "[setup] Running wizard..."

# Step 1 - Set configuration
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${JELLYFIN_HOST}:${JELLYFIN_PORT}/Startup/Configuration" \
  -H "Content-Type: application/json" \
  -d "{\"ServerName\":\"${APP}\",\"UICulture\":\"en-US\",\"MetadataCountryCode\":\"US\",\"PreferredMetadataLanguage\":\"en\"}")
echo "[setup] Configuration response: ${RESPONSE}"

# Step 2 - Remote access
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${JELLYFIN_HOST}:${JELLYFIN_PORT}/Startup/RemoteAccess" \
  -H "Content-Type: application/json" \
  -d "{\"AllowRemoteAccess\":true}")
echo "[setup] Remote access response: ${RESPONSE}"

# Step 3 - Create admin user
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${JELLYFIN_HOST}:${JELLYFIN_PORT}/Startup/User" \
  -H "Content-Type: application/json" \
  -d "{\"Name\":\"${ADMIN_USERNAME}\",\"Password\":\"${ADMIN_PASSWORD}\"}")
echo "[setup] User response: ${RESPONSE}"
if [ "$RESPONSE" = "200" ]; then
  echo "[setup] Jellyfin user created ✅"
else
  echo "[setup] Jellyfin user failed ❌: $(cat /tmp/response.txt)"
fi

echo "[setup] Jellyfin setup complete ✅"
sleep infinity