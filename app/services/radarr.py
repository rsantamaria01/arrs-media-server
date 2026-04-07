from config.constants import Constants
from config.envs import envs
from utils.api_utils import get_arr_api_key, get_host, send_api_request, waiting_for_api

from services.base_service import BaseService


class RadarrService:
    def __init__(self) -> None:
        self.service = Constants.media_server.services.radarr
        self.volumes: list[dict[str, dict[str, str]]] = [
            {
                f"{envs.APP_DATA_ROOT_PATH}": {
                    "bind": "/shared-config",
                    "mode": "rw",
                },
                f"{envs.APP_DATA_ROOT_PATH}/{container.name}": {
                    "bind": "/config",
                    "mode": "rw",
                },
                f"{envs.MOUNT_ROOT_PATH}": {"bind": "/mnt/remote", "mode": "slave"},
                f"{envs.SYMLINKS_ROOT_PATH}": {
                    "bind": "/mnt/symlinks",
                    "mode": "slave",
                },
                f"{envs.MEDIA_ROOT_PATH}/{container.media_subpath}": {
                    "bind": f"/data/media/{container.media_subpath}",
                    "mode": "slave",
                },
            }
            for container in self.service.containers
        ]
        self.base = BaseService(service=self.service, volumes=self.volumes)

    def initialize(self) -> None:
        self.base.initialize_container()
        self.base.wait_for_containers()

        config_payload = []

        for container in self.service.containers:
            if container.external_port is not None:
                waiting_for_api(get_host(container.external_port))
                api_key = get_arr_api_key(container.name)
                config_payload.append(
                    {
                        "id": 1,
                        "bindAddress": "*",
                        "port": f"{container.external_port}",
                        "sslPort": 9898,
                        "enableSsl": False,
                        "launchBrowser": False,
                        "authenticationMethod": "forms",
                        "authenticationRequired": "enabled",
                        "analyticsEnabled": False,
                        "username": f"{envs.ADMIN_USERNAME}",
                        "password": f"{envs.ADMIN_PASSWORD}",
                        "passwordConfirmation": f"{envs.ADMIN_PASSWORD}",
                        "logLevel": "info",
                        "logSizeLimit": 1,
                        "consoleLogLevel": "",
                        "branch": "master",
                        "apiKey": f"{api_key}",
                        "sslCertPath": "",
                        "sslCertPassword": "",
                        "urlBase": "",
                        "instanceName": f"{self.service.name}",
                        "applicationUrl": "",
                        "updateAutomatically": False,
                        "updateMechanism": "docker",
                        "updateScriptPath": "",
                        "proxyEnabled": False,
                        "proxyType": "http",
                        "proxyHostname": "",
                        "proxyPort": 8080,
                        "proxyUsername": "",
                        "proxyPassword": "",
                        "proxyBypassFilter": "",
                        "proxyBypassLocalAddresses": True,
                        "certificateValidation": "enabled",
                        "backupFolder": "Backups",
                        "backupInterval": 7,
                        "backupRetention": 28,
                        "historyCleanupDays": 30,
                        "trustCgnatIpAddresses": False,
                    }
                )
                send_api_request(
                    get_host(container.external_port) + "/api/v3/config",
                    "PUT",
                    config_payload[0],
                )

    def update(self) -> None:
        self.base.remove_container()
        self.base.initialize_container()

    def remove(self) -> None:
        self.base.remove_container()

    def restart(self) -> None:
        self.base.restart_container()
