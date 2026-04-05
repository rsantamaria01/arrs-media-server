import docker
from docker.errors import DockerException, NotFound, APIError

client = docker.from_env()

def create_network(network_name):
    try:
        network = client.networks.create(network_name, driver="bridge")
        print(f"Created network: {network.name}")
        return network
    except APIError as e:
        print(f"Error creating network {network_name}: {e}")
        return None

def remove_network(network_name):
    try:
        network = client.networks.get(network_name)
        network.remove()
        print(f"Removed network: {network_name}")
    except NotFound:
        print(f"Network not found: {network_name}")
    except APIError as e:
        print(f"Error removing network {network_name}: {e}")

def list_networks():
    networks = client.networks.list()
    for n in networks:
        print(f"{n.name:<30}")
    return networks


def pull_image(image_name):
    try:
        print(f"Pulling {image_name}...")
        client.images.pull(image_name)
        print(f"Pulled: {image_name}")
    except APIError as e:
        print(f"Error pulling {image_name}: {e}")



def create_container(
    image_name,
    command=None,
    name=None,
    detach=True,
    ports=None,
    volumes=None,
    environment=None,
    network=None,
):
    try:
        container = client.containers.run(
            image=image_name,
            command=command,
            name=name,
            detach=detach,
            ports=ports,
            volumes=volumes,
            environment=environment,
            network=network,
        )
        print(f"Created container: {container.name}")
        return container
    except APIError as e:
        print(f"Error creating container: {e}")
        return None


def start_container(name):
    try:
        container = client.containers.get(name)
        container.start()
        print(f"Started: {name}")
    except NotFound:
        print(f"Container not found: {name}")
    except APIError as e:
        print(f"Error starting {name}: {e}")


def stop_container(name):
    try:
        container = client.containers.get(name)
        container.stop()
        print(f"Stopped: {name}")
    except NotFound:
        print(f"Container not found: {name}")
    except APIError as e:
        print(f"Error stopping {name}: {e}")


def restart_container(name):
    try:
        container = client.containers.get(name)
        container.restart()
        print(f"Restarted: {name}")
    except NotFound:
        print(f"Container not found: {name}")
    except APIError as e:
        print(f"Error restarting {name}: {e}")


def remove_container(name, force=False):
    try:
        container = client.containers.get(name)
        container.remove(force=force)
        print(f"Removed: {name}")
    except NotFound:
        print(f"Container not found: {name}")
    except APIError as e:
        print(f"Error removing {name}: {e}")


def rebuild_container(image_name, name, build_path=None, **run_kwargs):
    """Pull or build a fresh image, remove old container, recreate it."""
    try:
        if build_path:
            print(f"Building image {image_name}...")
            image, logs = client.images.build(path=build_path, tag=image_name, rm=True)
            for chunk in logs:
                if "stream" in chunk:
                    print(chunk["stream"], end="")
        else:
            print(f"Pulling {image_name}...")
            client.images.pull(image_name)

        remove_container(name, force=True)
        return create_container(image_name, name=name, **run_kwargs)

    except (APIError, DockerException) as e:
        print(f"Error rebuilding {name}: {e}")
        return None


def list_containers(all_containers=True):
    containers = client.containers.list(all=all_containers)
    for c in containers:
        print(f"{c.name:<30} {c.status:<15}")
    return containers


def exec_in_container(name, command):
    try:
        container = client.containers.get(name)
        exit_code, output = container.exec_run(command)
        result = output.decode()
        print(result)
        return result
    except NotFound:
        print(f"Container not found: {name}")
    except APIError as e:
        print(f"Error exec in {name}: {e}")
