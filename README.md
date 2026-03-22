# arrs-media-server

A production-ready, self-hosted media automation stack built with Docker Compose. It combines indexing, downloading, media management, subtitle automation, and streaming into a single cohesive setup behind an SSL-capable reverse proxy.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)

## Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/rsantamaria01/arrs-media-server.git
   cd arrs-media-server
   ```

2. **Create your environment file**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` to set your user/group IDs and timezone:

   ```env
   PUID=1000
   PGID=1000
   TZ=America/New_York
   ```

3. **Create the service config directories**

   Bind mounts require the host directories to exist before starting the stack:

   ```bash
   mkdir -p services/{prowlarr,sonarr,sonarr-anime,radarr,lidarr,readarr,bazarr,jellyfin,npm}
   ```

4. **Start the stack**

   ```bash
   docker compose up -d
   ```

## Services

| Service             | Purpose                                      | Port(s)        |
|---------------------|----------------------------------------------|----------------|
| Prowlarr            | Indexer manager for all *arr apps            | 9696           |
| Sonarr              | TV show download manager                     | 8989           |
| Sonarr Anime        | Dedicated Sonarr instance for anime          | 8990           |
| Radarr              | Movie download manager                       | 7878           |
| Lidarr              | Music download manager                       | 8686           |
| Readarr             | Books and manga download manager             | 8787           |
| Bazarr              | Automatic subtitle manager (EN + ES)         | 6767           |
| Jellyfin            | Media streaming server                       | 8096           |
| Nginx Proxy Manager | Reverse proxy with SSL termination           | 80, 443, 81    |
