output container_id {
  description = "Id of Docker container"
  value = docker_container.nginx.id
}

output image_id {
  description = "Id of Docker image"
  value = docker_image.nginx.id
}