#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to prompt for private key input
prompt_private_key() {
    read -sp "Enter your PRIVATE_KEY: " PRIVATE_KEY
    echo
}

# Check if PRIVATE_KEY is provided as an environment variable
if [ -z "$PRIVATE_KEY" ]; then
    echo "PRIVATE_KEY not set. Please enter it now."
    prompt_private_key
fi

# Stop and remove the existing light-client container
docker stop light-client 2>/dev/null
docker rm light-client 2>/dev/null

# Remove the existing ewm-das directory if it exists
rm -rf ewm-das

# Clone the latest version of ewm-das from GitHub
git clone https://github.com/covalenthq/ewm-das

# Navigate to the ewm-das directory
cd ewm-das

# Build the Docker image using Dockerfile.lc
docker build -t covalent/light-client -f Dockerfile.lc .

# Run the Docker container with the specified environment variable
docker run -d --restart always --name light-client -e PRIVATE_KEY="$PRIVATE_KEY" covalent/light-client

echo "The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version"
echo "============================ Covalent Light Node ============================"
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"

# Show the logs of the running container
docker logs -f light-client