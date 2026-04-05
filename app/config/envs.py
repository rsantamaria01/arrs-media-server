from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    CLOUDFLARE_TUNNEL_TOKEN: str
    PUID: int = 1000
    PGID: int = 1000
    UMASK: str = "002"
    TZ: str = "America/Guayaquil"
    DOMAIN: str
    ADMIN_USERNAME: str
    ADMIN_PASSWORD: str
    TORBOX_APIKEY: str

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "frozen": True,
    }


envs = Settings()