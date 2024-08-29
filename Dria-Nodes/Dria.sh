#!/bin/bash

# Check Internet connection
if ! ping -c 1 google.com &> /dev/null; then
    echo "No internet connection detected. Please check your connection and try again." >&2
    exit 1
fi

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to display an error message and exit
function error_exit {
    echo "$1" >&2
    exit 1
}

# Check if Docker is installed
if command -v docker &> /dev/null; then
    echo "Docker is already installed."
else
    echo "Docker is not installed. Starting Docker installation..."
    sudo apt-get update || error_exit "Failed to update package list."
    sudo apt-get install -y docker.io || error_exit "Failed to install Docker."

    # Recheck if Docker was successfully installed
    if ! command -v docker &> /dev/null; then
        error_exit "Docker not found after installation."
    else
        echo "Docker was successfully installed."
    fi
fi

# Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4) || error_exit "Failed to get Docker Compose version."
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /tmp/docker-compose || error_exit "Failed to download Docker Compose."
sudo mv /tmp/docker-compose /usr/local/bin/docker-compose || error_exit "Failed to move Docker Compose to /usr/local/bin."
sudo chmod +x /usr/local/bin/docker-compose || error_exit "Failed to set execute permission for Docker Compose."

# Check if Docker Compose was successfully installed
if ! command -v docker-compose &> /dev/null; then
    error_exit "Docker Compose not found after installation."
else
    echo "Docker Compose was successfully installed."
fi

# Check Docker status and display logs
echo "Checking Docker status and displaying logs..."
sudo systemctl status docker || error_exit "Failed to check Docker status."
sudo journalctl -u docker --no-pager -n 100 || error_exit "Failed to display Docker logs."

# Clone the repository if it doesn't already exist
REPO_DIR="dkn-compute-node"
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning the dkn-compute-node repository..."
    git clone https://github.com/Winnode/dkn-compute-node || error_exit "Failed to clone the repository."
else
    echo "Directory $REPO_DIR already exists. Pulling the latest changes..."
    cd "$REPO_DIR" || error_exit "Failed to enter the directory."
    git pull || error_exit "Failed to update the repository."
fi
cd dkn-compute-node || error_exit "Failed to enter the dkn-compute-node directory."

# Copy the environment file
cp .env.example .env || error_exit "Failed to copy the .env.example file."

# Prompt for private key and OpenAI API key
while [ -z "$PRIVATE_KEY" ]; do
    read -sp "Enter YOUR_PRIVATE_KEY: " PRIVATE_KEY
    echo
    if [ -z "$PRIVATE_KEY" ]; then
        echo "Private key cannot be empty. Please try again."
    fi
done

while [ -z "$OPENAI_API_KEY" ]; do
    read -sp "Enter YOUR_OPENAI_API_KEY: " OPENAI_API_KEY
    echo
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "OpenAI API key cannot be empty. Please try again."
    fi
done

# Add keys to the .env file
{
    echo "DKN_WALLET_SECRET_KEY=$PRIVATE_KEY"
    echo "OPENAI_API_KEY=$OPENAI_API_KEY"
} >> .env || error_exit "Failed to add keys to the .env file."

# Make start.sh executable
chmod +x start.sh || error_exit "Failed to set execute permission for start.sh."

# Display help for start.sh
./start.sh --help || error_exit "Failed to run ./start.sh --help."

# Run the compute node with the specified mode
./start.sh -m=gpt-4o-mini || error_exit "Failed to run ./start.sh with mode gpt-4o-mini."

echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
echo "============================ Dria Node Installation ===================================="
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"