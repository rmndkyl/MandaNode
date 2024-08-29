#!/bin/bash

# Display a logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to handle errors
function error_exit {
    echo "$1" >&2
    exit 1
}

# Step 1: Update the system and install prerequisites
echo "1. Updating system and installing prerequisites..."
sudo apt update && sudo apt upgrade -y || error_exit "System update failed!"
sudo apt install apt-transport-https ca-certificates curl software-properties-common jq -y || error_exit "Failed to install prerequisites!"

# Step 2: Add Docker GPG key and repository
echo "2. Adding Docker GPG key and repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || error_exit "Failed to add Docker GPG key!"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repository!"

# Step 3: Install Docker
echo "3. Installing Docker..."
sudo apt update || error_exit "Failed to update package list after adding Docker repository!"
sudo apt install docker-ce docker-ce-cli containerd.io -y || error_exit "Failed to install Docker!"

# Step 4: Verify Docker installation
echo "4. Verifying Docker installation..."
docker --version || error_exit "Docker installation verification failed!"
sudo docker run hello-world || error_exit "Failed to run hello-world Docker container!"

# Step 5: Create directory for nillion/accuser and pull the image
echo "5. Creating directory for nillion/accuser and pulling the image..."
mkdir -p nillion/accuser || error_exit "Failed to create directory for nillion/accuser!"
docker pull nillion/retailtoken-accuser:v1.0.0 || error_exit "Failed to pull nillion/retailtoken-accuser image!"

# Step 6: Run the container to initialize accuser
echo "6. Running the container to initialize accuser..."
docker run -v $(pwd)/nillion/accuser:/var/tmp nillion/retailtoken-accuser:v1.0.0 initialise || error_exit "Failed to initialize accuser!"

# Step 7: Extract address and public key from credentials.json
echo "7. Extracting address, public key, and backing up private key from credentials.json..."
CREDENTIALS_FILE="./nillion/accuser/credentials.json"
if [[ -f $CREDENTIALS_FILE ]]; then
    ACCOUNT_ID=$(jq -r '.address' $CREDENTIALS_FILE)
    PUBLIC_KEY=$(jq -r '.pub_key' $CREDENTIALS_FILE)
    PRIVATE_KEY=$(jq -r '.priv_key' $CREDENTIALS_FILE)
    echo "Account ID: $ACCOUNT_ID"
    echo "Public Key: $PUBLIC_KEY"
    echo "Private Key (Backup): $PRIVATE_KEY"
    echo "Backing up credentials..."
    sudo cp $CREDENTIALS_FILE /root/nillion/accuser/credentials_backup.json || error_exit "Failed to back up credentials!"
else
    echo "Credentials file not found!" >&2
    exit 1
fi

# Step 8: Install PM2 and set up Docker container to run under PM2
echo "8. Installing PM2..."
sudo npm install pm2 -g || error_exit "Failed to install PM2!"

# Step 9: Run the Docker container with the latest block
echo "9. Running the Docker container with the latest block..."
LATEST_BLOCK=$(curl -s https://testnet-nillion-rpc.lavenderfive.com/status | jq -r .result.sync_info.latest_block_height) || error_exit "Failed to fetch the latest block height!"
pm2 start docker --name retailtoken-accuser -- run -d -v $(pwd)/nillion/accuser:/var/tmp nillion/retailtoken-accuser:v1.0.0 accuse --rpc-endpoint "https://testnet-nillion-rpc.lavenderfive.com" --block-start "$LATEST_BLOCK" || error_exit "Failed to run Docker container under PM2!"

# Step 10: Save PM2 process list and enable startup on system boot
echo "10. Saving PM2 process list and enabling startup..."
pm2 save || error_exit "Failed to save PM2 process list!"
pm2 startup || error_exit "Failed to enable PM2 startup on boot!"

echo "Setup and operations completed successfully!"
echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
echo "============================ Nillion Verifier Installation ===================================="
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi
