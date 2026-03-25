#!/bin/sh
echo "ADMIN_USERNAME=${ADMIN_USERNAME}" > /config/.env
echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> /config/.env
echo "PORT=${PORT}" >> /config/.env
echo "API_VERSION=${API_VERSION}" >> /config/.env

echo "[init] admin username: ${ADMIN_USERNAME}"
echo "[init] port: ${PORT}"
echo "[init] api version: ${API_VERSION}"