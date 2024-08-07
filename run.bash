#!/usr/bin/env bash
set -euo pipefail

# Global variables
AREA="planet"
FILENAME="${AREA}-$(date +%d-%m-%Y).mbtiles"
S3_PATH="ovh:kargo/data/MBTiles"



# Install rclone curl  wget and openjdk-21-jdk
sudo apt-get update
sudo apt-get install -y rclone curl wget openjdk-21-jdk

# Install sops
curl -LO https://github.com/getsops/sops/releases/download/v3.9.0/sops-v3.9.0.linux.amd64 && chmod +x sops-v3.9.0.linux.amd64 && sudo mv sops-v3.9.0.linux.amd64 /usr/local/bin/sops


# ask for the sops key of a worker
echo "Please enter the SOPS key of a worker to decrypt the rclone configuration file"
echo "Your SOPS key should be in "\$DEVELOPMENT_DIR/age/keys.txt" on your local machine"
echo "It begins with 'AGE-SECRET-KEY-XXXXX...'"
read -s -p "Enter a compatible SOPS key: " SOPS_AGE_KEY
echo

# Export the key so that it is available for the following commands
export SOPS_AGE_KEY

# Decrypt the rclone configuration file
sops --decrypt  --output "./rclone.dec.conf" "./rclone.enc.conf"
sops --decrypt  --output "./SLACK_WEBHOOK.dec.env" "./SLACK_WEBHOOK.enc.env"

# Load the environment variables
source ./SLACK_WEBHOOK.dec.env


# Function to send a message to Slack
notify_slack() {
    local message="$1"
    local color="$2"
    curl -X POST "$WEBHOOK_URL" \
        -H 'Content-type: application/json' \
        --data "{
            \"attachments\": [
                {
                    \"color\": \"$color\",
                    \"title\": \"Planetiler job\",
                    \"text\": \"(test)$message\"
                }
            ]
        }" || true
}

# Function to handle errors
error_exit() {
    local error_message="$1"
    echo "$error_message"
    notify_slack "$error_message" "danger"
    exit 1
}


# Install Planetiler
wget https://github.com/onthegomap/planetiler/releases/latest/download/planetiler.jar -O planetiler.jar || error_exit "Error downloading Planetiler."

# Get the amount of RAM in GB
RAM_GB=$(free -g | awk '/^Mem:/{print $2}') || error_exit "Error retrieving RAM amount."

notify_slack "The planetiler job has started for the region *${AREA}*." "good"

# Run Planetiler with the specified region
java -Xmx${RAM_GB}g -jar planetiler.jar --download  --output=${FILENAME} --area=${AREA} --force || error_exit "Error executing Planetiler."

# Copy the MBTiles file to the S3 storage
rclone copy --progress --stats-one-line --stats=5s  --config=./rclone.dec.conf ${FILENAME} ${S3_PATH} || error_exit "Error sending MBTiles file to object storage."

# Send a success notification
notify_slack "The planetiler job has completed for the region *${AREA}*." "good"
