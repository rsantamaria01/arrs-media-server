#!/bin/bash

# ─── Load env vars ────────────────────────────────────────────────────────────
set -a
source /home/rs/arrs-media-server/.env
set +a

# ─── Down all services except cloudflare ─────────────────────────────────────
echo "Stopping services..."
docker compose stop decypharr prowlarr sonarr sonarr-anime radarr lidarr bazarr jellyfin seerr flaresolverr 2>/dev/null || true
echo "Services stopped ✅"

# ─── Unmount stale FUSE mounts ────────────────────────────────────────────────
echo "Unmounting stale mounts..."
sudo umount -l /mnt/arrs-media-server/mount/remote 2>/dev/null || true
sudo fusermount -uz /mnt/arrs-media-server/mount/remote 2>/dev/null || true
echo "Mounts cleared ✅"

# ─── Nuke fs ──────────────────────────────────────────────────────────────────
echo "Nuking fs..."
sudo rm -rf /mnt/arrs-media-server/
echo "FS nuked ✅"

# ─── Recreate directories ─────────────────────────────────────────────────────
echo "Creating directories..."
sudo mkdir -p /mnt/arrs-media-server/{config/{decypharr,prowlarr,sonarr,sonarr-anime,radarr,lidarr,bazarr,profilarr,jellyfin,seerr,flaresolverr},media/{movies,tv,tv-anime,music},mount/remote,symlinks}
sudo chown -R $(whoami):$(whoami) /mnt/arrs-media-server
echo "Directories created ✅"

# ─── Fix permissions ──────────────────────────────────────────────────────────
chmod +x /home/rs/arrs-media-server/scripts/*
echo "Permissions updated ✅"

# ─── Bring services back up ───────────────────────────────────────────────────
echo "Starting services..."
docker compose up -d --remove-orphans
echo "Services started ✅"