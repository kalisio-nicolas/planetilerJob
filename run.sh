#!/usr/bin/env bash
set -euo pipefail

# This script should be run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo. (apt requires root privileges)"
    exit 1
fi


# Function to handle errors
error_exit() {
    local error_message="$1"
    echo "$error_message"
    notify_slack "$error_message" "danger"
    exit 1
}

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
                    \"text\": \"$message\"
                }
            ]
        }" || true
}


# Global variables
AREA="${AREA:-planet}"
SOPS_AGE_KEY="${SOPS_AGE_KEY:-}"
S3_PATH="${S3_PATH:-ovh:kargo/data/MBTiles}"
FILENAME="${AREA}-$(date +%d-%m-%Y).mbtiles"

# Install rclone, curl, wget, and openjdk-21-jdk
apt-get update
apt-get install -y rclone curl wget openjdk-21-jdk

# Install sops if the decrypted files don't exist
if [[ ! -f "./rclone.dec.conf" || ! -f "./SLACK_WEBHOOK.dec.env" ]]; then
    curl -LO https://github.com/getsops/sops/releases/download/v3.9.0/sops-v3.9.0.linux.amd64 && chmod +x sops-v3.9.0.linux.amd64 &&  mv sops-v3.9.0.linux.amd64 /usr/local/bin/sops

    # If the SOPS_AGE_KEY is not set, ask for it
    if [[ -z "${SOPS_AGE_KEY}" ]]; then
        echo "Please enter the SOPS key of a worker to decrypt the rclone configuration file"
        echo "Your SOPS key should be in \"\$DEVELOPMENT_DIR/age/keys.txt\" on your local machine"
        echo "It begins with 'AGE-SECRET-KEY-XXXXX...'"
        read -s -p "Enter a compatible SOPS key: " SOPS_AGE_KEY
        echo
    fi

    # Decrypt the rclone configuration file
    sops --decrypt --output "./rclone.dec.conf" "./rclone.enc.conf"
    sops --decrypt --output "./SLACK_WEBHOOK.dec.env" "./SLACK_WEBHOOK.enc.env"
fi

# Load the environment variables if WEBHOOK_URL is not set
WEBHOOK_URL="${WEBHOOK_URL:-}"
if [[ -z "${WEBHOOK_URL}" && -f "./SLACK_WEBHOOK.dec.env" ]]; then
    source ./SLACK_WEBHOOK.dec.env
fi

# Notify Slack that the job has started
notify_slack "The Planetiler job has started for the region *${AREA}*." "good"

# Install Planetiler
wget https://github.com/onthegomap/planetiler/releases/latest/download/planetiler.jar -O planetiler.jar || error_exit "Error downloading Planetiler."

# Get the amount of RAM in GB
RAM_GB=$(free -g | awk '/^Mem:/{print $2}') || error_exit "Error retrieving RAM amount."

# Run Planetiler with the specified region
java -Xmx${RAM_GB}g -jar planetiler.jar --download --output=${FILENAME} --area=${AREA} --force || error_exit "Error executing Planetiler."

# Copy the MBTiles file to the S3 storage
rclone copy --progress --stats-one-line --stats=5s --config=./rclone.dec.conf ${FILENAME} ${S3_PATH} || error_exit "Error sending MBTiles file to object storage."

# Send a success notification
notify_slack "The Planetiler job has completed for the region *${AREA}*." "good"
