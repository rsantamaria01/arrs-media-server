#!/bin/bash

# Make all files in scripts directory executable
chmod +x /home/rs/arrs-media-server/scripts/*
chown -R 1000:1000 /opt/data/services/seerr

echo "Permissions updated for all files in scripts directory"