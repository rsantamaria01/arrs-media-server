import json

from config.constants import Constants
from config.envs import envs
from utils.api_utils import get_arr_api_key, waiting_for_api

from services.base_service import BaseService


class DecypharrService:
    def __init__(self, name: str, port: int) -> None:
        self.service = Constants.media_server.services.decypharr
        self.volumes: dict[str, dict[str, str]] = {
            f"{envs.APP_DATA_ROOT_PATH}": {"bind": "/shared-config", "mode": "rw"},
            f"{envs.APP_DATA_ROOT_PATH}/{name}": {"bind": "/data", "mode": "rw"},
            f"{envs.MOUNT_ROOT_PATH}": {"bind": "/mnt/remote", "mode": "shared"},
            f"{envs.SYMLINKS_ROOT_PATH}": {"bind": "/mnt/symlinks", "mode": "shared"},
        }
        self.base = BaseService(service=self.service, volumes=self.volumes)

    def initialize(self) -> None:
        self.base.initialize_container()
        self.base.wait_for_containers()

        for container in (
            Constants.media_server.services.sonarr.containers
            + Constants.media_server.services.radarr.containers
            + Constants.media_server.services.lidarr.containers
        ):
            waiting_for_api(f"http://{container.name}:{container.internal_port}")

        tags = [
            container.media_subpath.replace("/", "-")
            if container.media_subpath
            else container.name
            for container in (
                Constants.media_server.services.sonarr.containers
                + Constants.media_server.services.radarr.containers
                + Constants.media_server.services.lidarr.containers
            )
        ]
        arrs_config = [
            {
                "name": container.name,
                "host": f"http://{container.name}:{container.internal_port}",
                "token": get_arr_api_key(container.name),
                "download_uncached": False,
            }
            for container in (
                Constants.media_server.services.sonarr.containers
                + Constants.media_server.services.radarr.containers
                + Constants.media_server.services.lidarr.containers
            )
        ]
        config = {
            "use_auth": False,
            "debrids": [
                {
                    "name": "torbox",
                    "api_key": envs.TORBOX_APIKEY,
                    "folder": f"{envs.MOUNT_ROOT_PATH}/torbox/__all__/",
                    "use_webdav": True,
                    "download_uncached": True,
                    "rate_limit": "250/minute",
                    "minimum_free_slot": 1,
                    "torrents_refresh_interval": "45s",
                    "download_links_refresh_interval": "15m",
                    "auto_expire_links_after": "1h",
                    "workers": 400,
                    "folder_naming": "original_no_ext",
                }
            ],
            "qbittorrent": {
                "host": "0.0.0.0",
                "port": "8282",
                "download_folder": envs.SYMLINKS_ROOT_PATH,
                "categories": tags,
                "refresh_interval": 300,
            },
            "arrs": arrs_config,
            "rclone": {
                "enabled": True,
                "mount_path": "/mnt/remote",
                "uid": envs.PUID,
                "gid": envs.PGID,
            },
        }
        config_path = [
            f"{envs.APP_DATA_ROOT_PATH}/{container.name}/config.json"
            for container in self.service.containers
        ]

        for path in config_path:
            with open(path, "w") as config_file:
                json.dump(config, config_file, indent=4)
            print(f"Decypharr configuration written to {path} ✅")

        self.base.restart_container()

    def update(self) -> None:
        self.base.remove_container()
        self.base.initialize_container()

    def remove(self) -> None:
        self.base.remove_container()
        

    def restart(self) -> None:
        self.base.restart_container()
