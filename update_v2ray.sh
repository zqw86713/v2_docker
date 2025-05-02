#!/bin/bash

# Configuration
CONTAINER_NAME="v2ray"
IMAGE_NAME="v2fly/v2fly-core"
# Adjust this path if your config.json.template is not in the current directory
CONFIG_TEMPLATE_PATH="./config.json.template"
# Path for the final config file that V2Ray will use inside the container
FINAL_CONFIG_PATH="./config.json" # This file will be generated
# Include -format jsonv5 here if your config.json is in V5 format
V2RAY_RUN_ARGS="run -c /etc/v2ray/config.json"

# --- Script Execution ---

echo "### Updating ${IMAGE_NAME} image ###"

# Pull the latest image
docker pull ${IMAGE_NAME}

# Check if the container exists
if docker inspect ${CONTAINER_NAME} &>/dev/null; then
  echo "### Stopping existing container ${CONTAINER_NAME} ###"
  # Stop the existing container
  docker stop ${CONTAINER_NAME}

  echo "### Removing existing container ${CONTAINER_NAME} ###"
  # Remove the existing container
  docker rm ${CONTAINER_NAME}
else
  echo "### Container ${CONTAINER_NAME} does not exist, skipping stop/remove ###"
fi

echo "### Generating final config.json from template and environment variables ###"

# Perform the replacement using sed
# Read the template, replace placeholders with environment variable values, and save to FINAL_CONFIG_PATH
sed \
  -e "s|__ENV_PASSWORD_CLIENT_CAN_LAX__|$ENV_PASSWORD_CLIENT_CAN_LAX|g" \
  -e "s|__ENV_PASSWORD_FAMILY_CAN_LAX_HKG__|$ENV_PASSWORD_FAMILY_CAN_LAX_HKG|g" \
  -e "s|__ENV_PASSWORD_FAMILY_CAN_LAX__|$ENV_PASSWORD_FAMILY_CAN_LAX|g" \
  -e "s|__ENV_PASSWORD_CAN_LOCAL_IP_IN__|$ENV_PASSWORD_CAN_LOCAL_IP_IN|g" \
  -e "s|__ENV_PASSWORD_HK_OUTBOUND__|$ENV_PASSWORD_HK_OUTBOUND|g" \
  -e "s|__ENV_PASSWORD_JMS_LAX_OUT_1__|$ENV_PASSWORD_JMS_LAX_OUT_1|g" \
  -e "s|__ENV_PASSWORD_JMS_LAX_OUT_2__|$ENV_PASSWORD_JMS_LAX_OUT_2|g" \
  "${CONFIG_TEMPLATE_PATH}" > "${FINAL_CONFIG_PATH}"

# Check if the config file was generated successfully
if [ ! -f "${FINAL_CONFIG_PATH}" ]; then
  echo "Error: Failed to generate ${FINAL_CONFIG_PATH}"
  exit 1
fi

echo "### Creating and starting a new container ${CONTAINER_NAME} ###"

# Create and start a new container from the updated image
# Mount the generated FINAL_CONFIG_PATH into the container
# Make sure the port mappings (-p ...) match your config.json
docker run -d \
  --name ${CONTAINER_NAME} \
  -v ${FINAL_CONFIG_PATH}:/etc/v2ray/config.json \
  -p 1081:1081 \
  -p 3389:3389 \
  -p 3500:3500 \
  -p 3501:3501 \
  -p 3396:3396 \
  ${IMAGE_NAME} ${V2RAY_RUN_ARGS}

# Remove the generated config file after starting the container (optional, for extra security)
# sleep 5 # Give the container a few seconds to start and read the config
# rm "${FINAL_CONFIG_PATH}"


echo "### Script finished ###"
echo "Check container status with: docker ps"
echo "Check container logs for errors with: docker logs ${CONTAINER_NAME}"