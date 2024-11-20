#!/bin/bash

# Define colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

# Display a logo
echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Update and upgrade system packages
echo -e "${YELLOW}Updating and upgrading system packages...${NC}"
apt update && apt upgrade -y || { echo -e "${RED}Error updating system packages. Exiting.${NC}"; exit 1; }

# Clean up old files
echo -e "${YELLOW}Cleaning up old files...${NC}"
rm -rf blockmesh-cli.tar.gz target

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io || {
        echo -e "${RED}Error installing Docker. Exiting.${NC}"; exit 1;
    }
else
    echo -e "${GREEN}Docker is already installed, skipping installation...${NC}"
fi

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${NC}"
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose || {
    echo -e "${RED}Error installing Docker Compose. Exiting.${NC}"; exit 1;
}

# Create a target directory for extraction
echo -e "${YELLOW}Creating target directory for extraction...${NC}"
mkdir -p target/release

# Download and extract the latest BlockMesh CLI
echo -e "${YELLOW}Downloading and extracting BlockMesh CLI...${NC}"
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.390/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release || {
    echo -e "${RED}Error extracting BlockMesh CLI. Exiting.${NC}"; exit 1;
}

# Verify extraction results
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo -e "${RED}Error: blockmesh-cli executable not found in target/release. Exiting.${NC}"
    exit 1
fi

# Prompt for email and password
echo -e "${BLUE}Please provide your BlockMesh credentials.${NC}"
read -p "Enter your BlockMesh email: " email
read -s -p "Enter your BlockMesh password: " password
echo

# Create a Docker container for BlockMesh CLI
echo -e "${YELLOW}Creating Docker container for BlockMesh CLI...${NC}"
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password" || {
        echo -e "${RED}Error running BlockMesh CLI in Docker. Exiting.${NC}"; exit 1;
    }

echo -e "${GREEN}BlockMesh CLI setup completed successfully!${NC}"
