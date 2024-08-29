#!/bin/bash

# Display a logo or banner (optional step, fetched from an external source)
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to handle errors and exit the script
function error_exit {
    echo "$1" >&2
    exit 1
}

# Step 1: Update the system and install prerequisites
echo "1. Updating system and installing prerequisites..."
sudo apt update && sudo apt upgrade -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common jq -y

# Step 2: Add Docker GPG key and repository
echo "2. Adding Docker GPG key and repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 3: Install Docker
echo "3. Installing Docker..."
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y

# Step 4: Verify Docker installation
echo "4. Verifying Docker installation..."
docker --version
sudo docker run hello-world

# Step 5: Create a directory for the Nillion accuser and pull the Docker image
echo "5. Creating directory for nillion/accuser and pulling the image..."
mkdir -p nillion/accuser
docker pull nillion/retailtoken-accuser:v1.0.0

# Step 6: Run the container to initialize the accuser
echo "6. Running the container to initialize accuser..."
docker run -v $(pwd)/nillion/accuser:/var/tmp nillion/retailtoken-accuser:v1.0.0 initialise

# Step 7: Extract address and pub_key from credentials.json
echo "7. Extracting address and public key from credentials.json..."
CREDENTIALS_FILE="./nillion/accuser/credentials.json"
if [[ -f $CREDENTIALS_FILE ]]; then
    ACCOUNT_ID=$(jq -r '.address' $CREDENTIALS_FILE)
    PUBLIC_KEY=$(jq -r '.pub_key' $CREDENTIALS_FILE)
    echo "Account ID: $ACCOUNT_ID"
    echo "Public Key: $PUBLIC_KEY"
else
    echo "Credentials file not found!"
fi

echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
echo "============================ Nillion Verifier Installation ===================================="
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
