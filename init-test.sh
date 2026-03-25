#!/bin/sh

SERVICE=sonarr

clear && \
docker compose down ${SERVICE} && \
sudo rm -rf /mnt/arrs-media-server/config/${SERVICE} && \
docker compose up ${SERVICE} -d --force-recreate && \
sleep 30 && \
docker logs ${SERVICE} 2>&1 | grep -E "${SERVICE}|init|setup|user|auth|api key|waiting|done"