#!/bin/sh
echo "ADMIN_USERNAME=${ADMIN_USERNAME}" > /config/.env
echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> /config/.env
echo "PORT=${PORT}" >> /config/.env
echo "APP=${APP}" >> /config/.env

# Set API version based on port
case "${PORT}" in
  9696|8686) API_VERSION="v1" ;;
  8989|7878|6767) API_VERSION="v3" ;;
  *) API_VERSION="v1" ;;
esac

echo "API_VERSION=${API_VERSION}" >> /config/.env

echo "[init] admin username: ${ADMIN_USERNAME}"
echo "[init] port: ${PORT}"
echo "[init] api version: ${API_VERSION}"