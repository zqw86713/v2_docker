#!/bin/bash

# Configuration
CONTAINER_NAME="v2ray"
IMAGE_NAME="v2fly/v2fly-core"
# Adjust this path if your config.json is not in the same directory as the script
CONFIG_PATH="./config.json"
TEMP_CONFIG_PATH="./config.json.tmp" # Create a temporary file for injecting secrets
# Adjust this path to where you store your secrets.json file
SECRET_FILE="./secrets.json"
# Include -format jsonv5 here if your config.json is in V5 format
V2RAY_RUN_ARGS="run -c /etc/v2ray/config.json"

# --- Script Execution ---

# Check if the secret file exists
if [ ! -f "$SECRET_FILE" ]; then
  echo "Error: Secret file ${SECRET_FILE} not found!"
  echo "Please create ${SECRET_FILE} with your passwords and ensure it's not in your git repository."
  exit 1
fi

# Read passwords from secrets.json using jq
# Ensure jq is installed on your system
echo "### Reading passwords from ${SECRET_FILE} ###"
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to use this script."
    exit 1
fi

# Read passwords - adjust jq paths based on your secrets.json structure
CLIENT_CAN_LAX_PASSWORD=$(jq -r '.client_can_lax_password' "$SECRET_FILE")
FAMILY_CAN_LAX_HKG_PASSWORD=$(jq -r '.family_can_lax_hkg_password' "$SECRET_FILE")
FAMILY_CAN_LAX_PASSWORD=$(jq -r '.family_can_lax_password' "$SECRET_FILE") # Assuming same password
CAN_LOCAL_IP_IN_PASSWORD=$(jq -r '.CAN_local_ip_in_password' "$SECRET_FILE")
OTTAWA_OUTBOUND_PASSWORD=$(jq -r '.ottawa_outbound_password' "$SECRET_FILE")
JMS_LAX_OUT_PASSWORD=$(jq -r '.jms_lax_out_password' "$SECRET_FILE") # Assuming same password for all jms_lax_out servers

# Check if passwords were read successfully (basic check for non-empty)
if [ -z "$CLIENT_CAN_LAX_PASSWORD" ] || [ -z "$FAMILY_CAN_LAX_HKG_PASSWORD" ] || [ -z "$CAN_LOCAL_IP_IN_PASSWORD" ] || [ -z "$OTTAWA_OUTBOUND_PASSWORD" ] || [ -z "$JMS_LAX_OUT_PASSWORD" ]; then
    echo "Warning: One or more passwords read from ${SECRET_FILE} are empty. Please check the file content and jq paths."
    # Decide if you want to exit here or continue with empty passwords
    # exit 1
fi

echo "### Injecting passwords into temporary config file ###"
# Use jq to inject passwords into the config.json and save to a temporary file
# Using --arg and separate filter parts to avoid quoting issues
jq --arg client_pass "$CLIENT_CAN_LAX_PASSWORD" \
   --arg family_hkg_pass "$FAMILY_CAN_LAX_HKG_PASSWORD" \
   --arg family_lax_pass "$FAMILY_CAN_LAX_PASSWORD" \
   --arg can_local_pass "$CAN_LOCAL_IP_IN_PASSWORD" \
   --arg ottawa_pass "$OTTAWA_OUTBOUND_PASSWORD" \
   --arg jms_pass "$JMS_LAX_OUT_PASSWORD" \
   '.inboundDetour |= map(
     if .tag == "client_can_lax" then .settings.password = $client_pass
     elif .tag == "family_can_lax_hkg" then .settings.password = $family_hkg_pass
     elif .tag == "family_can_lax" then .settings.password = $family_lax_pass
     elif .tag == "CAN_local_ip_in" then .settings.password = $can_local_pass
     else . end
   ) | .outbounds |= map(
     if .tag == "hk" then .settings.servers[0].password = $ottawa_pass
     elif .tag == "jms_lax_out" then (.settings.servers[] |= .password = $jms_pass)
     else . end
   )' "$CONFIG_PATH" > "$TEMP_CONFIG_PATH"

# Check if the temporary config file was created successfully
if [ ! -f "$TEMP_CONFIG_PATH" ]; then
    echo "Error: Failed to create temporary config file with injected passwords. Check jq command and config.json structure."
    exit 1
fi

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

echo "### Creating and starting a new container ${CONTAINER_NAME} ###"

# Create and start a new container from the updated image
# Mount the temporary config file instead of the original config.json
docker run -d \
  --name ${CONTAINER_NAME} \
  -v ${TEMP_CONFIG_PATH}:/etc/v2ray/config.json \
  -p 1081:1081 \
  -p 3389:3389 \
  -p 3500:3500 \
  -p 3501:3501 \
  -p 3396:3396 \
  ${IMAGE_NAME} ${V2RAY_RUN_ARGS}

# Clean up the temporary config file after starting the container
echo "### Cleaning up temporary config file ###"
rm "$TEMP_CONFIG_PATH"

echo "### Script finished ###"
echo "Check container status with: docker ps"
echo "Check container logs for errors with: docker logs ${CONTAINER_NAME}"