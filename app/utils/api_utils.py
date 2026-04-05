import xml.etree.ElementTree as ET

import requests
from config.constants import Constants
from config.envs import envs


def get_arr_api_key(service_name: str) -> str:
    config_path = f"{envs.APP_DATA_ROOT_PATH}/{service_name}/config.xml"
    tree = ET.parse(config_path)
    root = tree.getroot()
    api_key = root.findtext("ApiKey")
    if not api_key:
        raise ValueError(f"Could not find ApiKey for {service_name}")
    return api_key


def get_host(
    service_port: int, service_name: str = Constants.media_server.network.default_host
) -> str:
    return f"http://{service_name}:{service_port}"


def waiting_for_api(service_host: str) -> None:
    import time

    print(f"Waiting for {service_host} to be available...")
    while True:
        try:
            response = requests.get(service_host, timeout=5)
            if response.status_code < 500:
                print(f"{service_host} is available ✅")
                break
        except (requests.ConnectionError, requests.Timeout):
            pass
        time.sleep(5)


def send_api_request(
    service_host: str, query_method: str, payload: dict | None = None
) -> None:
    try:
        response = requests.request(
            query_method, service_host, json=payload, timeout=10
        )
        response.raise_for_status()
        print(f"Payload sent to {service_host} successfully ✅")
    except requests.RequestException as e:
        print(f"Error sending payload to {service_host}: {e}")
