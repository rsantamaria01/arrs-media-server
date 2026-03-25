#!/bin/sh

. /config/.env

CONFIG_FILE=/config/config.xml
APP='Prowlarr'
API_VERSION=v1
PROWLARR_HOST=http://prowlarr
PROWLARR_PORT=9696
SONARR_HOST=http://sonarr
SONARR_PORT=8989
SONARR_ANIME_HOST=http://sonarr-anime
SONARR_ANIME_PORT=8989
RADARR_HOST=http://radarr
RADARR_PORT=7878
LIDARR_HOST=http://lidarr
LIDARR_PORT=8686
FLARESOLVER_HOST=http://flaresolverr
FLARESOLVER_PORT=8191
FLARESOLVER_TAG=flaresolverr

# Wait for Prowlarr
echo "[setup] Waiting for ${APP} on port ${PROWLARR_PORT}..."
while ! nc -z "${PROWLARR_HOST#http://}" "${PROWLARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 5
echo "[setup] ${APP} is up..."

# Get Prowlarr API key
API_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' "$CONFIG_FILE" | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] API key: ${API_KEY}"

# Set credentials and auth
echo "[setup] Setting credentials and auth method..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X PUT "${PROWLARR_HOST}:${PROWLARR_PORT}/api/${API_VERSION}/config/host/1" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"id\":1,\"bindAddress\":\"*\",\"port\":${PROWLARR_PORT},\"sslPort\":9898,\"enableSsl\":false,\"launchBrowser\":false,\"authenticationMethod\":\"forms\",\"authenticationRequired\":\"enabled\",\"analyticsEnabled\":false,\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\",\"passwordConfirmation\":\"${ADMIN_PASSWORD}\",\"logLevel\":\"info\",\"logSizeLimit\":1,\"consoleLogLevel\":\"\",\"branch\":\"master\",\"apiKey\":\"${API_KEY}\",\"sslCertPath\":\"\",\"sslCertPassword\":\"\",\"urlBase\":\"\",\"instanceName\":\"${APP}\",\"applicationUrl\":\"\",\"updateAutomatically\":false,\"updateMechanism\":\"docker\",\"updateScriptPath\":\"\",\"proxyEnabled\":false,\"proxyType\":\"http\",\"proxyHostname\":\"\",\"proxyPort\":8080,\"proxyUsername\":\"\",\"proxyPassword\":\"\",\"proxyBypassFilter\":\"\",\"proxyBypassLocalAddresses\":true,\"certificateValidation\":\"enabled\",\"backupFolder\":\"Backups\",\"backupInterval\":7,\"backupRetention\":28,\"historyCleanupDays\":30,\"trustCgnatIpAddresses\":false}")

echo "[setup] response HTTP code: ${RESPONSE}"
if [ "$RESPONSE" = "202" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Credentials and auth set ✅"
else
  echo "[setup] Failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Sonarr ───────────────────────────────────────────────────────────────
echo "[setup] Waiting for Sonarr..."
while ! nc -z "${SONARR_HOST#http://}" "${SONARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
SONARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/sonarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Sonarr key: ${SONARR_KEY}"

RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${PROWLARR_HOST}:${PROWLARR_PORT}/api/${API_VERSION}/applications" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"syncLevel\":\"fullSync\",\"name\":\"Sonarr\",\"implementation\":\"Sonarr\",\"configContract\":\"SonarrSettings\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"${PROWLARR_HOST}:${PROWLARR_PORT}\"},{\"name\":\"baseUrl\",\"value\":\"${SONARR_HOST}:${SONARR_PORT}\"},{\"name\":\"apiKey\",\"value\":\"${SONARR_KEY}\"},{\"name\":\"syncCategories\",\"value\":[5000,5010,5020,5030,5040,5045,5050]}]}")

echo "[setup] Sonarr app response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Sonarr added to Prowlarr ✅"
else
  echo "[setup] Sonarr failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Sonarr Anime ─────────────────────────────────────────────────────────
echo "[setup] Waiting for Sonarr Anime..."
while ! nc -z "${SONARR_ANIME_HOST#http://}" "${SONARR_ANIME_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
SONARR_ANIME_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/sonarr-anime/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Sonarr Anime key: ${SONARR_ANIME_KEY}"

RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${PROWLARR_HOST}:${PROWLARR_PORT}/api/${API_VERSION}/applications" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"syncLevel\":\"fullSync\",\"name\":\"Sonarr Anime\",\"implementation\":\"Sonarr\",\"configContract\":\"SonarrSettings\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"${PROWLARR_HOST}:${PROWLARR_PORT}\"},{\"name\":\"baseUrl\",\"value\":\"${SONARR_ANIME_HOST}:${SONARR_ANIME_PORT}\"},{\"name\":\"apiKey\",\"value\":\"${SONARR_ANIME_KEY}\"},{\"name\":\"syncCategories\",\"value\":[5000,5010,5020,5030,5040,5045,5050]}]}")

echo "[setup] Sonarr Anime app response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Sonarr Anime added to Prowlarr ✅"
else
  echo "[setup] Sonarr Anime failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Radarr ───────────────────────────────────────────────────────────────
echo "[setup] Waiting for Radarr..."
while ! nc -z "${RADARR_HOST#http://}" "${RADARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
RADARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/radarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Radarr key: ${RADARR_KEY}"

RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${PROWLARR_HOST}:${PROWLARR_PORT}/api/${API_VERSION}/applications" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"syncLevel\":\"fullSync\",\"name\":\"Radarr\",\"implementation\":\"Radarr\",\"configContract\":\"RadarrSettings\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"${PROWLARR_HOST}:${PROWLARR_PORT}\"},{\"name\":\"baseUrl\",\"value\":\"${RADARR_HOST}:${RADARR_PORT}\"},{\"name\":\"apiKey\",\"value\":\"${RADARR_KEY}\"},{\"name\":\"syncCategories\",\"value\":[2000,2010,2020,2030,2040,2045,2050,2060,2070,2080]}]}")

echo "[setup] Radarr app response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Radarr added to Prowlarr ✅"
else
  echo "[setup] Radarr failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add Lidarr ───────────────────────────────────────────────────────────────
echo "[setup] Waiting for Lidarr..."
while ! nc -z "${LIDARR_HOST#http://}" "${LIDARR_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
LIDARR_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' /shared-config/lidarr/config.xml | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] Lidarr key: ${LIDARR_KEY}"

RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${PROWLARR_HOST}:${PROWLARR_PORT}/api/${API_VERSION}/applications" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"syncLevel\":\"fullSync\",\"name\":\"Lidarr\",\"implementation\":\"Lidarr\",\"configContract\":\"LidarrSettings\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"${PROWLARR_HOST}:${PROWLARR_PORT}\"},{\"name\":\"baseUrl\",\"value\":\"${LIDARR_HOST}:${LIDARR_PORT}\"},{\"name\":\"apiKey\",\"value\":\"${LIDARR_KEY}\"},{\"name\":\"syncCategories\",\"value\":[3000,3010,3020,3030,3040,3050]}]}")

echo "[setup] Lidarr app response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Lidarr added to Prowlarr ✅"
else
  echo "[setup] Lidarr failed ❌: $(cat /tmp/response.txt)"
fi

# ─── Add FlareSolverr as indexer proxy ────────────────────────────────────────
echo "[setup] Waiting for FlareSolverr..."
while ! nc -z "${FLARESOLVER_HOST#http://}" "${FLARESOLVER_PORT}" 2>/dev/null; do sleep 2; done
sleep 3
echo "[setup] FlareSolverr is up..."

# Create tag first
echo "[setup] Creating tag '${FLARESOLVER_TAG}'..."
TAG_RESPONSE=$(curl -s -X POST "${PROWLARR_HOST}:${PROWLARR_PORT}/api/${API_VERSION}/tag" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"label\":\"${FLARESOLVER_TAG}\"}")
TAG_ID=$(echo "$TAG_RESPONSE" | grep -o '"id": *[0-9]*' | grep -o '[0-9]*')
echo "[setup] Tag ID: ${TAG_ID}"

# Add FlareSolverr with tag in one call
echo "[setup] Adding FlareSolverr as indexer proxy..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X POST "${PROWLARR_HOST}:${PROWLARR_PORT}/api/${API_VERSION}/indexerproxy" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"FlareSolverr\",\"implementation\":\"FlareSolverr\",\"configContract\":\"FlareSolverrSettings\",\"tags\":[${TAG_ID}],\"fields\":[{\"name\":\"host\",\"value\":\"${FLARESOLVER_HOST}:${FLARESOLVER_PORT}\"},{\"name\":\"requestTimeout\",\"value\":60}]}")

echo "[setup] FlareSolverr response: ${RESPONSE}"
if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] FlareSolverr added with tag '${FLARESOLVER_TAG}' ✅"
else
  echo "[setup] FlareSolverr failed ❌: $(cat /tmp/response.txt)"
fi


echo "[setup] Done ✅"
sleep infinity