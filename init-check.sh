#!/bin/sh

SERVICE=radarr

clear && \
docker logs ${SERVICE} 2>&1 | grep -E "${SERVICE}|init|setup|user|auth|api key|waiting|done"