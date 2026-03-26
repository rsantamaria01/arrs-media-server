#!/bin/sh

. /config/.env

CONFIG_FILE=/config/config.xml
APP='Radarr'
API_VERSION=v3
RADARR_HOST=http://radarr
RADARR_PORT=7878
RADARR_CATEGORY=radarr
DECYPHARR_HOST=http://decypharr
DECYPHARR_PORT=8282
MOUNT_NAME=torbox
REMOTE_PATH=/mnt/symlinks/
LOCAL_PATH=${REMOTE_PATH}
ROOT_PATH=/data/media/movies

# Wait for Radarr
echo "[setup] Waiting for ${APP} on port ${RADARR_PORT}..."
while ! nc -z "${RADARR_HOST#http://}" "${RADARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 5
echo "[setup] ${APP} is up..."

# Get Radarr API key
API_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' "$CONFIG_FILE" | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] API key: ${API_KEY}"

# Set credentials and auth
echo "[setup] Setting credentials and auth method..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X PUT "${RADARR_HOST}:${RADARR_PORT}/api/${API_VERSION}/config/host/1" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"id\":1,\"bindAddress\":\"*\",\"port\":${RADARR_PORT},\"sslPort\":9898,\"enableSsl\":false,\"launchBrowser\":false,\"authenticationMethod\":\"forms\",\"authenticationRequired\":\"enabled\",\"analyticsEnabled\":false,\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\",\"passwordConfirmation\":\"${ADMIN_PASSWORD}\",\"logLevel\":\"info\",\"logSizeLimit\":1,\"consoleLogLevel\":\"\",\"branch\":\"master\",\"apiKey\":\"${API_KEY}\",\"sslCertPath\":\"\",\"sslCertPassword\":\"\",\"urlBase\":\"\",\"instanceName\":\"${APP}\",\"applicationUrl\":\"\",\"updateAutomatically\":false,\"updateMechanism\":\"docker\",\"updateScriptPath\":\"\",\"proxyEnabled\":false,\"proxyType\":\"http\",\"proxyHostname\":\"\",\"proxyPort\":8080,\"proxyUsername\":\"\",\"proxyPassword\":\"\",\"proxyBypassFilter\":\"\",\"proxyBypassLocalAddresses\":true,\"certificateValidation\":\"enabled\",\"backupFolder\":\"Backups\",\"backupInterval\":7,\"backupRetention\":28,\"historyCleanupDays\":30,\"trustCgnatIpAddresses\":false}")

echo "[setup] response HTTP code: ${RESPONSE}"
if [ "$RESPONSE" = "202" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Credentials and auth set ✅"
else
  echo "[setup] Failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Decypharr as download client ─────────────────────────────────────────
echo "[setup] Waiting for Decypharr..."
while ! nc -z "${DECYPHARR_HOST#http://}" "${DECYPHARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
echo "[setup] Decypharr is up..."

echo "[setup] Adding Decypharr as download client..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${RADARR_HOST}:${RADARR_PORT}/api/${API_VERSION}/downloadclient" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"removeCompletedDownloads\":true,\"removeFailedDownloads\":true,\"name\":\"Decypharr\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\",\"fields\":[{\"name\":\"host\",\"value\":\"${DECYPHARR_HOST#http://}\"},{\"name\":\"port\",\"value\":${DECYPHARR_PORT}},{\"name\":\"useSsl\",\"value\":false},{\"name\":\"urlBase\",\"value\":\"/\"},{\"name\":\"username\",\"value\":\"\"},{\"name\":\"password\",\"value\":\"\"},{\"name\":\"category\",\"value\":\"${RADARR_CATEGORY}\"},{\"name\":\"recentMoviePriority\",\"value\":0},{\"name\":\"olderMoviePriority\",\"value\":0},{\"name\":\"initialState\",\"value\":0},{\"name\":\"sequentialOrder\",\"value\":false},{\"name\":\"firstAndLast\",\"value\":false}]}")

echo "[setup] Decypharr response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Decypharr added as download client ✅"
else
  echo "[setup] Decypharr failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Wait for mount to be available ───────────────────────────────────────────
echo "[setup] Waiting for rclone mount at ${LOCAL_PATH}..."
RETRIES=0
while [ ! -d "${LOCAL_PATH}" ] && [ $RETRIES -lt 30 ]; do
  sleep 2
  RETRIES=$((RETRIES + 1))
done

if [ ! -d "${LOCAL_PATH}" ]; then
  echo "[setup] Mount never appeared ❌, continuing anyway..."
else
  echo "[setup] Mount is up ✅"
fi

# ─── Add remote path mapping ──────────────────────────────────────────────────
echo "[setup] Adding remote path mapping..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${RADARR_HOST}:${RADARR_PORT}/api/${API_VERSION}/remotepathmapping" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"host\":\"decypharr\",\"remotePath\":\"${REMOTE_PATH}\",\"localPath\":\"${LOCAL_PATH}\"}")

echo "[setup] Remote path mapping response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Remote path mapping added ✅"
else
  echo "[setup] Remote path mapping failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add root folder ──────────────────────────────────────────────────────────
echo "[setup] Waiting for root folder at ${ROOT_PATH}..."
RETRIES=0
while [ ! -d "${ROOT_PATH}" ] && [ $RETRIES -lt 15 ]; do
  sleep 2
  RETRIES=$((RETRIES + 1))
done

if [ ! -d "${ROOT_PATH}" ]; then
  echo "[setup] Root folder not found, creating ${ROOT_PATH}..."
  mkdir -p "${ROOT_PATH}" || echo "[setup] mkdir failed ❌"
else
  echo "[setup] Root folder exists ✅"
fi

echo "[setup] Adding root folder to ${APP}..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${RADARR_HOST}:${RADARR_PORT}/api/${API_VERSION}/rootfolder" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"path\":\"${ROOT_PATH}\"}")

if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Root folder added ✅"
else
  echo "[setup] Root folder failed ❌: $(cat /tmp/response.txt)"
fi

echo "[setup] Done ✅"
sleep infinity