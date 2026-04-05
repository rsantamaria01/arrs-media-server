from app.utils import docker_utils

class DecypharrService:
    def __init__(self):
        self.network_name = "decypharr_network"
        self.image_name = "decypharr:latest"
        self.container_name = "decypharr_container"
        self.port = 8080

    def setup(self):
        # Create network
        docker_utils.create_network(self.network_name)

        # Pull image (if needed)
        docker_utils.pull_image(self.image_name)

        # Create and start container
        docker_utils.create_container(
            image_name=self.image_name,
            name=self.container_name,
            network=self.network_name,
            ports={"8080/tcp": 8080},
            detach=True
        )

    def teardown(self):
        # Remove container
        try:
            docker_utils.stop_container(self.container_name)
            docker_utils.remove_container(self.container_name)
        except Exception as e:
            print(f"Error removing container {self.container_name}: {e}")

        # Remove network
        docker_utils.remove_network(self.network_name)
