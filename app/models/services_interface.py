from abc import ABC, abstractmethod


class IService(ABC):
    image_name: str
    container_name: str
    network_name: str
    port: int | None
    volumes: dict[str, dict[str, str]]
    environment: dict[str, str]

    @abstractmethod
    def __init__(self, name: str, port: int | None) -> None: ...

    @abstractmethod
    def setup(self) -> None:
        """Pull image and create the container."""
        ...

    @abstractmethod
    def configure(self) -> None:
        """Post-startup configuration (API keys, credentials, download clients)."""
        ...

    @abstractmethod
    def update(self) -> None:
        """Pull latest image and recreate the container."""
        ...

    @abstractmethod
    def reset(self) -> None:
        """Remove and recreate the container from scratch."""
        ...

    @abstractmethod
    def restart(self) -> None:
        """Restart the container."""
        ...
