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
   mkdir -p services/{prowlarr,sonarr,sonarr-anime,radarr,lidarr,mylar3,kavita,bazarr,jellyfin,npm/data,npm/letsencrypt}
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
| Kavita              | Self-hosted books, manga and comics reader   | 5000           |
| Mylar3              | Automated manga and comics download manager  | 8090           |
| Bazarr              | Automatic subtitle manager (EN + ES)         | 6767           |
| Jellyfin            | Media streaming server                       | 8096           |
| Nginx Proxy Manager | Reverse proxy with SSL termination           | 80, 443, 81    |

## CI/CD

Every push to the `main` branch automatically deploys to the DigitalOcean droplet via GitHub Actions (see `.github/workflows/deploy.yml`).

### Required GitHub Secrets

Add the following secrets in your repository under **Settings → Secrets and variables → Actions**:

| Secret        | Description                        |
|---------------|------------------------------------|
| `DO_HOST`     | Droplet IP address                 |
| `DO_USER`     | SSH username                       |
| `DO_PASSWORD` | SSH password                       |

### Environment File

The `.env` file is **not** committed to the repository. The deploy script automatically creates it with default values (`PUID=0`, `PGID=0`, `TZ=America/New_York`) on first run if it does not already exist. To customise, edit it on the droplet after the first deployment:

```bash
# On the droplet
nano /opt/mediastack/.env
```
