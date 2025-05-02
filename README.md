# V2Ray Docker Update & Restart Script

This script automates the process of updating your V2Ray Docker container to the latest `v2fly/v2fly-core` image. It pulls the newest image, stops and removes the currently running container (if it exists), and starts a new container using the updated image and your specified configuration file.

## Prerequisites

* **Docker:** Docker must be installed and running on your system.
* **Bash:** A bash environment (common on Linux and macOS).
* **`config.json`:** Your V2Ray configuration file (`config.json`) must be prepared and accessible at the path specified in the script.

## Configuration

Open the script in a text editor and adjust the following variables at the beginning:

* `CONTAINER_NAME`: The desired name for your V2Ray Docker container. Default is `v2ray`.
* `IMAGE_NAME`: The name of the V2Ray Docker image to use. Default is `v2fly/v2fly-core`.
* `CONFIG_PATH`: **Crucially, set this to the absolute or relative path on your *host machine* where your `config.json` file is located.** The script mounts this file into the container at `/etc/v2ray/config.json`.
* `V2RAY_RUN_ARGS`: Additional arguments passed to the `v2ray run` command inside the container. The script defaults to `run -c /etc/v2ray/config.json`. **If your `config.json` is in V5 format, you should change this to `run -format jsonv5 -c /etc/v2ray/config.json`**.


## Usage

1.  Save the script: Copy the code and save it to a file (e.g., `update_v2ray.sh`) on your host machine.
2.  Make the script executable: Open a terminal and run:
    ```bash
    chmod +x update_v2ray.sh
    ```
3.  Run the script: Execute the script from your terminal:
    ```bash
    ./update_v2ray.sh
    ```

The script will output messages indicating the progress, including pulling the image, stopping/removing the old container, and starting the new one.

## Verification

After running the script, you can verify the container status and check for errors:

* **Check Container Status:** See if the container is running:
    ```bash
    docker ps
    ```
* **Check Container Logs:** View the V2Ray logs for any errors or status messages:
    ```bash
    docker logs v2ray # Replace 'v2ray' if you changed CONTAINER_NAME
    ```

## Notes

* This script assumes you want to use the `v2fly/v2fly-core` image. If you use a different image, change `IMAGE_NAME`.
* Ensure the path specified in `CONFIG_PATH` on your host machine correctly points to your `config.json` file.
* Always back up your `config.json` before making changes.
* If you encounter issues, check the `docker logs` for the container for detailed error messages from V2Ray.