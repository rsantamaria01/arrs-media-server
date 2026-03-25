#!/bin/sh

# Load env vars saved by init script
. /config/.env

# Set app name for instanceName in config
CONFIG_FILE=/config/config.xml
APP='Radarr'

# Wait for arr to be up
echo "[setup] Waiting for ${APP} on port ${PORT}..."
while ! nc -z localhost "${PORT}" 2>/dev/null; do
  sleep 2
done
sleep 5
echo "[setup] ${APP} is up..."

# Get the API key app generated
API_KEY=$(grep -o '<ApiKey>[^<]*</ApiKey>' "$CONFIG_FILE" | sed 's/<ApiKey>//;s/<\/ApiKey>//')
echo "[setup] api key: ${API_KEY}"

# Set credentials and auth method with full config
echo "[setup] Setting credentials and auth method..."
RESPONSE=$(curl -s -o /tmp/response.txt -w "%{http_code}" -X PUT "http://localhost:${PORT}/api/v${API_VERSION}/config/host/1" \
  -H "X-Api-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"id\":1,\"bindAddress\":\"*\",\"port\":${PORT},\"sslPort\":9898,\"enableSsl\":false,\"launchBrowser\":false,\"authenticationMethod\":\"forms\",\"authenticationRequired\":\"enabled\",\"analyticsEnabled\":false,\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\",\"passwordConfirmation\":\"${ADMIN_PASSWORD}\",\"logLevel\":\"info\",\"logSizeLimit\":1,\"consoleLogLevel\":\"\",\"branch\":\"master\",\"apiKey\":\"${API_KEY}\",\"sslCertPath\":\"\",\"sslCertPassword\":\"\",\"urlBase\":\"\",\"instanceName\":\"${APP}\",\"applicationUrl\":\"\",\"updateAutomatically\":false,\"updateMechanism\":\"docker\",\"updateScriptPath\":\"\",\"proxyEnabled\":false,\"proxyType\":\"http\",\"proxyHostname\":\"\",\"proxyPort\":8080,\"proxyUsername\":\"\",\"proxyPassword\":\"\",\"proxyBypassFilter\":\"\",\"proxyBypassLocalAddresses\":true,\"certificateValidation\":\"enabled\",\"backupFolder\":\"Backups\",\"backupInterval\":7,\"backupRetention\":28,\"historyCleanupDays\":30,\"trustCgnatIpAddresses\":false}")

echo "[setup] response HTTP code: ${RESPONSE}"

if [ "$RESPONSE" = "202" ] || [ "$RESPONSE" = "200" ]; then
  echo "[setup] Credentials and auth set ✅"
else
  echo "[setup] Failed ❌: $(cat /tmp/response.txt)"
fi

echo "[setup] Done ✅"
sleep infinity