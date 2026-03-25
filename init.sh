#!/bin/bash

# ─── Down all services except cloudflare ─────────────────────────────────────
echo "Stopping services..."
docker compose stop postgres debridav rclone prowlarr sonarr sonarr-anime radarr lidarr bazarr jellyfin seerr flaresolverr
echo "Services stopped ✅"

# ─── Nuke configs ─────────────────────────────────────────────────────────────
echo "Nuking configs..."
sudo rm -rf /mnt/arrs-media-server/config/{postgres,debridav,rclone,prowlarr,sonarr,sonarr-anime,radarr,lidarr,bazarr,jellyfin,seerr,flaresolverr}
sudo rm -rf /mnt/arrs-media-server/mount/debrid
echo "Configs nuked ✅"

# ─── Recreate directories ─────────────────────────────────────────────────────
echo "Creating directories..."
sudo mkdir -p /mnt/arrs-media-server/{config/{rclone,debridav,postgres,prowlarr,sonarr,sonarr-anime,radarr,lidarr,bazarr,jellyfin,seerr,flaresolverr},media/{movies,tv,tv-anime,music},mount/debrid}
echo "Directories created ✅"

# ─── Fix permissions ──────────────────────────────────────────────────────────
chmod +x /home/rs/arrs-media-server/scripts/*
echo "Permissions updated ✅"

# ─── Bring services back up ───────────────────────────────────────────────────
echo "Starting services..."
docker compose up jellyfin bazarr -d
echo "Services started ✅"