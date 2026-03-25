#!/bin/sh

. /config/.env

APP='Jellyfin'
JELLYFIN_HOST=http://jellyfin
JELLYFIN_PORT=8096

echo "[setup] Waiting for ${APP} on port ${JELLYFIN_PORT}..."
while ! nc -z "${JELLYFIN_HOST#http://}" "${JELLYFIN_PORT}" 2>/dev/null; do
  sleep 2
done

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
SET_CONFIG_RESPONSE=$(curl -s -o /tmp/set_config_response.txt -w "%{http_code}" -X POST "${JELLYFIN_HOST}:${JELLYFIN_PORT}/Startup/Configuration" \
  -H "Content-Type: application/json" \
  -d "{\"ServerName\": \"${APP}\", \"UICulture\":\"en-US\",\"MetadataCountryCode\":\"US\",\"PreferredMetadataLanguage\":\"en\"}")
echo "[setup] set configuration response HTTP code: ${SET_CONFIG_RESPONSE}"

# Step 2 - Remote access
REMOTE_ACCESS_RESPONSE=$(curl -s -o /tmp/remote_access_response.txt -w "%{http_code}" -X POST "${JELLYFIN_HOST}:${JELLYFIN_PORT}/Startup/RemoteAccess" \
  -H "Content-Type: application/json" \
  -d "{\"AllowRemoteAccess\": true}")
echo "[setup] remote access response HTTP code: ${REMOTE_ACCESS_RESPONSE}"

# Step 3 - Create admin user
USER_RESPONSE=$(curl -s -o /tmp/user_response.txt -w "%{http_code}" -X POST "${JELLYFIN_HOST}:${JELLYFIN_PORT}/Startup/User" \
  -H "Content-Type: application/json" \
  -d "{\"Name\": \"${ADMIN_USERNAME}\", \"Password\": \"${ADMIN_PASSWORD}\"}")
echo "[setup] user response HTTP code: ${USER_RESPONSE}"
echo "[setup] user response: $(cat /tmp/user_response.txt)"

# Step 4 - Complete wizard
#COMPLETE_RESPONSE=$(curl -s -o /tmp/complete_response.txt -w "%{http_code}" -X POST "${JELLYFIN_HOST}:${JELLYFIN_PORT}/Startup/Complete")
#echo "[setup] complete response HTTP code: ${COMPLETE_RESPONSE}"

echo "[setup] Jellyfin setup complete ✅"
sleep infinity