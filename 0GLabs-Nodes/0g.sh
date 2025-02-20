#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function for error handling
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Function for successful messages
success_message() {
    echo -e "${GREEN}$1${NC}"
}

# Display a logo
clear
echo -e "${BLUE}========================================${NC}"
echo -e "${PURPLE}    0G DA Client Installation Script${NC}"
echo -e "${BLUE}========================================${NC}"

# Display loading animation
echo -e "${YELLOW}Preparing installation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -f loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -f logo.sh
sleep 4

# System Update
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y || error_exit "System update failed"

# Docker Installation
echo -e "${YELLOW}Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null
then
    echo -e "${BLUE}Installing Docker...${NC}"
    
    # Prerequisites
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

    # Docker repository and installation
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    success_message "Docker installed successfully"
else
    echo -e "${GREEN}Docker is already installed${NC}"
fi

# Install Git
echo -e "${YELLOW}Installing Git...${NC}"
sudo apt install git -y

# Clone Repository
echo -e "${BLUE}Cloning 0G DA Client repository...${NC}"
git clone https://github.com/0glabs/0g-da-client.git || error_exit "Repository cloning failed"

# Build Docker Image
cd 0g-da-client || error_exit "Cannot change directory"
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t 0g-da-client -f combined.Dockerfile . || error_exit "Docker image build failed"

# Private Key Input with validation
while true; do
    read -p "$(echo -e "${PURPLE}Enter your Metamask private key: ${NC}")" PRIVATE_KEY

    # Remove '0x' from private key if it exists
    PRIVATE_KEY=${PRIVATE_KEY#0x}

    # Validate private key format
    if [[ $PRIVATE_KEY =~ ^[a-fA-F0-9]{64}$ ]]; then
        break
    else
        echo -e "${RED}Invalid private key format. Please enter a valid 64-character hex key.${NC}"
    fi
done

# Generate environment file
echo -e "${YELLOW}Generating configuration file...${NC}"
cat <<EOF > ogda.env
# 0G DA Client Configuration
COMBINED_SERVER_CHAIN_RPC=https://evmrpc-testnet.0g.ai
COMBINED_SERVER_PRIVATE_KEY=$PRIVATE_KEY
ENTRANCE_CONTRACT_ADDR=0x857C0A28A8634614BB2C96039Cf4a20AFF709Aa9
COMBINED_SERVER_RECEIPT_POLLING_ROUNDS=180
COMBINED_SERVER_RECEIPT_POLLING_INTERVAL=1s
COMBINED_SERVER_TX_GAS_LIMIT=2000000
COMBINED_SERVER_USE_MEMORY_DB=true
COMBINED_SERVER_KV_DB_PATH=/runtime/
COMBINED_SERVER_TimeToExpire=2592000
DISPERSER_SERVER_GRPC_PORT=51001
BATCHER_DASIGNERS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000001000
BATCHER_FINALIZER_INTERVAL=20s
BATCHER_CONFIRMER_NUM=3
BATCHER_MAX_NUM_RETRIES_PER_BLOB=3
BATCHER_FINALIZED_BLOCK_COUNT=50
BATCHER_BATCH_SIZE_LIMIT=500
BATCHER_ENCODING_INTERVAL=3s
BATCHER_ENCODING_REQUEST_QUEUE_SIZE=1
BATCHER_PULL_INTERVAL=10s
BATCHER_SIGNING_INTERVAL=3s
BATCHER_SIGNED_PULL_INTERVAL=20s
BATCHER_EXPIRATION_POLL_INTERVAL=3600
BATCHER_ENCODER_ADDRESS=DA_ENCODER_SERVER
BATCHER_ENCODING_TIMEOUT=300s
BATCHER_SIGNING_TIMEOUT=60s
BATCHER_CHAIN_READ_TIMEOUT=12s
BATCHER_CHAIN_WRITE_TIMEOUT=13s
EOF

# Run Docker Container
echo -e "${BLUE}Starting 0G DA Client...${NC}"
docker run -d --env-file ogda.env --name 0g-da-client -v ./run:/runtime -p 51001:51001 0g-da-client combined || error_exit "Docker container startup failed"

# Final Success Message
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  0G DA Client Installation Complete!  ${NC}"
echo -e "${GREEN}========================================${NC}"
