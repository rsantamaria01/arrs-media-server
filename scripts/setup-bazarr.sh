#!/bin/sh

CONFIG_FILE=/config/config/config.yaml

# Only create if it doesn't exist yet
if [ -f "$CONFIG_FILE" ]; then
  echo "[init-bazarr] config.yaml already exists, skipping"
  exit 0
fi

mkdir -p /config/config

PASSWORD_HASH=$(echo -n "${ADMIN_PASSWORD}" | md5sum | cut -d' ' -f1)
API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

echo "[init-bazarr] Creating config.yaml..."

cat > "$CONFIG_FILE" << EOF
---
auth:
  apikey: ${API_KEY}
  password: ${PASSWORD_HASH}
  type: form
  username: ${ADMIN_USERNAME}
general:
  ip: '*'
  port: 6767
  base_url: /
  branch: master
  auto_update: true
  debug: false
  chmod: '0640'
  chmod_enabled: false
  instance_name: Bazarr
EOF

echo "[init-bazarr] config.yaml created ✅"