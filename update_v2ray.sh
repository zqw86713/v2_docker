#!/bin/bash

# Configuration
CONTAINER_NAME="v2ray"
IMAGE_NAME="v2fly/v2fly-core"
# Adjust this path if your config.json is not in /usr/local/etc/v2ray/
CONFIG_PATH="/root/v2_docker/config.json"
# Include -format jsonv5 here if your config.json is in V5 format
V2RAY_RUN_ARGS="run -c /etc/v2ray/config.json "

# --- Script Execution ---

# print the current date and time
echo "### Script started at $(date) ###"

echo "### Updating ${IMAGE_NAME} image ###"

# Pull the latest image
docker pull ${IMAGE_NAME}

# Check if the container exists
if docker inspect ${CONTAINER_NAME} &>/dev/null; then
  echo "### Container ${CONTAINER_NAME} exists. Checking status and potentially recreating. ###"
  # Stop the existing container if it's running
  if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
    echo "### Stopping running container ${CONTAINER_NAME} ###"
    docker stop ${CONTAINER_NAME}
  fi

  echo "### Removing existing container ${CONTAINER_NAME} ###"
  # Remove the existing container
  docker rm ${CONTAINER_NAME}
else
  echo "### Container ${CONTAINER_NAME} does not exist, proceeding with creation. ###"
fi

echo "### Creating and starting a new container ${CONTAINER_NAME} with --restart always ###"

# Create and start a new container from the updated image
# Key change: Added --restart always
# Make sure the port mappings (-p ...) match your config.json
docker run -d \
  --name "${CONTAINER_NAME}" \
  --network host \
  -v "${CONFIG_PATH}":/etc/v2ray/config.json \
  --restart always \
  "${IMAGE_NAME}" ${V2RAY_RUN_ARGS}

echo "### Script finished ###"
echo "Check container status with: docker ps"
echo "Check container logs for errors with: docker logs ${CONTAINER_NAME}"