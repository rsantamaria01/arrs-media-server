connect_download_client() {
  local app_url=$1
  local app_api_key=$2
  local app_name=$3
  local category_field=$4
  local category=$5

  RESPONSE=$(curl -s -X POST "$app_url/api/v3/downloadclient" \
    -H "X-Api-Key: $app_api_key" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"RDTClient\",
      \"enable\": true,
      \"protocol\": \"torrent\",
      \"priority\": 1,
      \"implementation\": \"QBittorrent\",
      \"implementationName\": \"qBittorrent\",
      \"configContract\": \"QBittorrentSettings\",
      \"fields\": [
        { \"name\": \"host\", \"value\": \"rdtclient\" },
        { \"name\": \"port\", \"value\": 6500 },
        { \"name\": \"username\", \"value\": \"$RDTCLIENT_USER\" },
        { \"name\": \"password\", \"value\": \"$RDTCLIENT_PASSWORD\" },
        { \"name\": \"$category_field\", \"value\": \"$category\" },
        { \"name\": \"useSsl\", \"value\": false }
      ]
    }")

  if echo "$RESPONSE" | grep -q '"id"'; then
    log_info "✅ $app_name connected to RDTClient"
  else
    log_warn "⚠️  $app_name failed or already connected — skipping"
  fi
}

connect_download_client "http://sonarr:8989"       "$SONARR_API_KEY"       "Sonarr"       "tvCategory"    "sonarr"
connect_download_client "http://sonarr-anime:8989" "$SONARR_ANIME_API_KEY" "Sonarr Anime" "tvCategory"    "sonarr-anime"
connect_download_client "http://radarr:7878"       "$RADARR_API_KEY"       "Radarr"       "movieCategory" "radarr"
connect_download_client "http://lidarr:8686"       "$LIDARR_API_KEY"       "Lidarr"       "musicCategory" "lidarr"