import docker
from config.constants import Constants, ServiceConfig
from config.envs import envs
from docker.errors import APIError
from docker.models.containers import Container


class BaseService:
    _client: docker.DockerClient = docker.from_env()

    def __init__(
        self, service: ServiceConfig, volumes: list[dict[str, dict[str, str]]]
    ) -> None:
        self.service: ServiceConfig = service
        self.network = Constants.media_server.network
        self.volumes: list[dict[str, dict[str, str]]] = volumes
        self.environment: dict[str, str] = {
            "PUID": str(envs.PUID),
            "PGID": str(envs.PGID),
            "TZ": envs.TZ,
        }
        self.containers: list[Container] = []

    def initialize_container(self) -> None:
        image_name = self.service.image_name

        for container in self.service.containers:
            try:
                print(
                    f"Creating container {container.name} for service from image {image_name}..."
                )
                self._client.images.pull(image_name)
                self._client.containers.run(
                    image=image_name,
                    name=container.name,
                    network=self.network.name,
                    ports={container.internal_port: container.external_port},
                    volumes=self.volumes,
                    environment=self.environment,
                    detach=True,
                    restart_policy={"Name": "unless-stopped"},
                )
                self.containers.append(self._client.containers.get(container.name))
                print(f"Container {container.name} created successfully ✅")
            except APIError as e:
                print(f"Error creating container {container.name}: {e.explanation}")

    def restart_container(self) -> None:
        for container in self.containers:
            try:
                print(f"Restarting container {container.name}...")
                container.restart()
                print(f"Container {container.name} restarted successfully ✅")
            except APIError as e:
                print(f"Error restarting container {container.name}: {e.explanation}")

    def remove_container(self) -> None:
        for container in self.containers:
            try:
                print(f"Removing container {container.name}...")
                container.remove(force=True)
                print(f"Container {container.name} removed successfully ✅")
            except APIError as e:
                print(f"Error removing container {container.name}: {e.explanation}")

    def status(self) -> list[str]:
        statuses = []
        for container in self.containers:
            try:
                container.reload()
                print(f"Container {container.name} status: {container.status}")
                statuses.append(container.status)
            except APIError as e:
                print(
                    f"Error checking status of container {container.name}: {e.explanation}"
                )
        return statuses

    def wait_for_containers(self) -> None:
        import time

        status = self.status()
        while not all(s == "running" for s in status):
            print("Waiting for containers to be running...")
            time.sleep(5)
            status = self.status()
