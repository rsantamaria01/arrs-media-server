#!/bin/sh
echo "ADMIN_USERNAME=${ADMIN_USERNAME}" > /config/.env
echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> /config/.env

echo "[init] admin username: ${ADMIN_USERNAME}"