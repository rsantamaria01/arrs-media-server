#!/bin/sh

. /config/.env

APP='Jellyfin'

echo "[setup] Waiting for ${APP} on port ${PORT}..."
while ! nc -z localhost "${PORT}" 2>/dev/null; do
  sleep 2
done
sleep 5
echo "[setup] ${APP} is up..."

# Complete startup wizard
echo "[setup] Completing startup wizard..."

# Set admin user
curl -s -X POST "http://localhost:${PORT}/Startup/User" \
  -H "Content-Type: application/json" \
  -d "{\"Name\": \"${ADMIN_USERNAME}\", \"Password\": \"${ADMIN_PASSWORD}\"}"

# Complete wizard
curl -s -X POST "http://localhost:${PORT}/Startup/Complete"

echo "[setup] Jellyfin setup complete ✅"
sleep infinity