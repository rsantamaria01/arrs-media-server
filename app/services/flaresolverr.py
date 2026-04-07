from config.constants import Constants
from config.envs import envs

from services.base_service import BaseService


class FlareSolverrService:
    def __init__(self) -> None:
        self.service = Constants.media_server.services.flaresolverr
        self.volumes: list[dict[str, dict[str, str]]] = [
            {
                f"{envs.APP_DATA_ROOT_PATH}": {
                    "bind": "/shared-config",
                    "mode": "rw",
                },
                f"{envs.APP_DATA_ROOT_PATH}/{container.name}": {
                    "bind": "/data",
                    "mode": "rw",
                },
            }
            for container in self.service.containers
        ]
        self.base = BaseService(service=self.service, volumes=self.volumes)

    def initialize(self) -> None:
        self.base.initialize_container()
        self.base.wait_for_containers()

    def update(self) -> None:
        self.base.remove_container()
        self.base.initialize_container()

    def remove(self) -> None:
        self.base.remove_container()

    def restart(self) -> None:
        self.base.restart_container()