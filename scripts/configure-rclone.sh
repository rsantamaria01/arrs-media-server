#!/bin/bash

# Load env variables
set -a
source /opt/mediastack/.env
set +a

# Create mount point
mkdir -p /mnt/torbox

# Obscure the password using rclone
OBSCURED_PASSWORD=$(docker run --rm rclone/rclone:latest obscure "${TORBOX_PASSWORD}")

# Generate rclone.conf from env variables
mkdir -p /opt/mediastack/services/rclone/rclone
cat > /opt/mediastack/services/rclone/rclone/rclone.conf << CONF
[torbox]
type = webdav
url = https://webdav.torbox.app
vendor = other
user = ${TORBOX_USERNAME}
pass = ${OBSCURED_PASSWORD}
CONF

echo "rclone.conf generated successfully"
cat /opt/mediastack/services/rclone/rclone/rclone.conf