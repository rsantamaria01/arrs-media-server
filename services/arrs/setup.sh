#!/bin/sh
set -e

CONFIG_FILE=/config/config.xml

mkdir -p /config

API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

cat > "$CONFIG_FILE" <<EOF
<Config>
  <AuthenticationMethod>None</AuthenticationMethod>
  <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  <Username>${ADMIN_USERNAME}</Username>
  <Password>${ADMIN_PASSWORD}</Password>
  <ApiKey>${API_KEY}</ApiKey>
  <LogLevel>info</LogLevel>
  <BindAddress>*</BindAddress>
  <Port>${PORT}</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <UpdateMechanism>Docker</UpdateMechanism>
</Config>
EOF


echo "[setup] config.xml written ✅"