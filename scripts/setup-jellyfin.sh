#!/bin/sh

. /config/.env

APP='Jellyfin'
JELLYFIN_HOST=http://jellyfin
JELLYFIN_PORT=8096

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