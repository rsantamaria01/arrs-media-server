from dataclasses import dataclass


@dataclass(frozen=True)
class ContainerConfig:
    name: str
    external_port: int | None
    internal_port: int | None
    media_subpath: str | None = None


@dataclass(frozen=True)
class ServiceConfig:
    image_name: str
    name: str
    containers: list[ContainerConfig]


@dataclass(frozen=True)
class ServicesConfig:
    decypharr: ServiceConfig
    sonarr: ServiceConfig
    radarr: ServiceConfig
    lidarr: ServiceConfig
    prowlarr: ServiceConfig
    bazarr: ServiceConfig
    profilarr: ServiceConfig
    jellyfin: ServiceConfig
    seerr: ServiceConfig
    flaresolverr: ServiceConfig


@dataclass(frozen=True)
class NetworkConfig:
    name: str
    mode: str
    default_host: str = "localhost"


@dataclass(frozen=True)
class MediaServerConfig:
    network: NetworkConfig
    services: ServicesConfig


class Constants:
    media_server = MediaServerConfig(
        network=NetworkConfig(name="media-server-network", mode="bridge"),
        services=ServicesConfig(
            decypharr=ServiceConfig(
                image_name="ghcr.io/akhanalcs/decypharr:latest",
                name="decypharr",
                containers=[
                    ContainerConfig(
                        name="decypharr",
                        external_port=8282,
                        internal_port=8282,
                    ),
                ],
            ),
            sonarr=ServiceConfig(
                image_name="lscr.io/linuxserver/sonarr:latest",
                name="sonarr",
                containers=[
                    ContainerConfig(
                        name="sonarr",
                        external_port=8989,
                        internal_port=8989,
                        media_subpath="tv",
                    ),
                    ContainerConfig(
                        name="sonarr-anime",
                        external_port=8990,
                        internal_port=8990,
                        media_subpath="tv/anime",
                    ),
                    ContainerConfig(
                        name="sonarr-kids",
                        external_port=8991,
                        internal_port=8991,
                        media_subpath="tv/kids",
                    ),
                ],
            ),
            radarr=ServiceConfig(
                image_name="lscr.io/linuxserver/radarr:latest",
                name="radarr",
                containers=[
                    ContainerConfig(
                        name="radarr",
                        external_port=7878,
                        internal_port=7878,
                        media_subpath="movies",
                    ),
                    ContainerConfig(
                        name="radarr-4k",
                        external_port=7879,
                        internal_port=7879,
                        media_subpath="movies/4k",
                    ),
                    ContainerConfig(
                        name="radarr-kids",
                        external_port=7880,
                        internal_port=7880,
                        media_subpath="movies/kids",
                    ),
                ],
            ),
            lidarr=ServiceConfig(
                image_name="lscr.io/linuxserver/lidarr:latest",
                name="lidarr",
                containers=[
                    ContainerConfig(
                        name="lidarr",
                        external_port=8686,
                        internal_port=8686,
                        media_subpath="music",
                    ),
                ],
            ),
            prowlarr=ServiceConfig(
                image_name="lscr.io/linuxserver/prowlarr:latest",
                name="prowlarr",
                containers=[
                    ContainerConfig(
                        name="prowlarr",
                        external_port=9696,
                        internal_port=9696,
                    ),
                ],
            ),
            bazarr=ServiceConfig(
                image_name="lscr.io/linuxserver/bazarr:latest",
                name="bazarr",
                containers=[
                    ContainerConfig(
                        name="bazarr",
                        external_port=6767,
                        internal_port=6767,
                    ),
                ],
            ),
            profilarr=ServiceConfig(
                image_name="santiagosayshey/profilarr:latest",
                name="profilarr",
                containers=[
                    ContainerConfig(
                        name="profilarr",
                        external_port=7877,
                        internal_port=7877,
                    ),
                ],
            ),
            jellyfin=ServiceConfig(
                image_name="lscr.io/linuxserver/jellyfin:latest",
                name="jellyfin",
                containers=[
                    ContainerConfig(
                        name="jellyfin",
                        external_port=8096,
                        internal_port=8096,
                    ),
                ],
            ),
            seerr=ServiceConfig(
                image_name="ghcr.io/seerr-team/seerr:latest",
                name="seerr",
                containers=[
                    ContainerConfig(
                        name="seerr",
                        external_port=5055,
                        internal_port=5055,
                    ),
                ],
            ),
            flaresolverr=ServiceConfig(
                image_name="ghcr.io/flaresolverr/flaresolverr:latest",
                name="flaresolverr",
                containers=[
                    ContainerConfig(
                        name="flaresolverr",
                        external_port=8191,
                        internal_port=8191,
                    ),
                ],
            ),
        ),
    )
