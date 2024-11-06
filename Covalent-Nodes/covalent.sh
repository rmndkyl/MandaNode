#!/bin/bash

# Display Animation
echo -e "${YELLOW}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

set -e

# Repository details
REPO_URL="https://github.com/covalenthq/ewm-das"
REPO_DIR="ewm-das"

# Function to prompt for private key input
prompt_private_key() {
    read -sp "Enter your PRIVATE_KEY: " PRIVATE_KEY
    echo
    if [ -z "$PRIVATE_KEY" ]; then
        echo "Private key cannot be empty."
        exit 1
    fi
}

# Check if Docker and Git are installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed or not in the PATH."
    exit 1
fi
if ! command -v git &> /dev/null; then
    echo "Git is not installed or not in the PATH."
    exit 1
fi

# Prompt for PRIVATE_KEY if not set as an environment variable
if [ -z "$PRIVATE_KEY" ]; then
    echo "PRIVATE_KEY not set. Please enter it now."
    prompt_private_key
fi

# Prompt user for the number of light-client containers to run
read -p "How many light-client containers do you want to run (1-10)? " NUM_LIGHT_CLIENTS

# Validate input
if ! [[ "$NUM_LIGHT_CLIENTS" =~ ^[1-9][0-9]?$ ]] || [ "$NUM_LIGHT_CLIENTS" -gt 10 ]; then
    echo "Please enter a valid number between 1 and 10."
    exit 1
fi

# Function to stop and remove existing containers
cleanup_containers() {
    for i in $(seq 1 10); do
        if docker ps -aq -f name=light-client-$i | grep -q .; then
            echo "Stopping and removing container: light-client-$i"
            docker stop light-client-$i && docker rm light-client-$i
        else
            echo "Container light-client-$i does not exist, skipping."
        fi
    done
}

# Cleanup existing containers
cleanup_containers

# Remove existing repository directory if it exists
if [ -d "$REPO_DIR" ]; then
    echo "Removing existing $REPO_DIR directory."
    rm -rf "$REPO_DIR"
else
    echo "$REPO_DIR directory does not exist, skipping removal."
fi

# Clone the latest version of the repository
echo "Cloning the latest version of $REPO_DIR from GitHub..."
if ! git clone "$REPO_URL"; then
    echo "Failed to clone repository."
    exit 1
fi

# Navigate to the cloned directory
cd "$REPO_DIR" || { echo "Failed to navigate to $REPO_DIR."; exit 1; }

# Build the Docker image using Dockerfile.lc
echo "Building the Docker image..."
if ! docker build -t covalent/light-client -f Dockerfile.lc .; then
    echo "Failed to build Docker image."
    exit 1
fi

# Run the specified number of Docker containers
for i in $(seq 1 "$NUM_LIGHT_CLIENTS"); do
    echo "Starting light-client-$i..."
    if docker run -d --restart always --name light-client-$i -e PRIVATE_KEY="$PRIVATE_KEY" covalent/light-client; then
        echo "Successfully started light-client-$i."
    else
        echo "Failed to start light-client-$i."
        exit 1
    fi
done

# List all Docker containers
echo "Listing all Docker containers:"
docker ps -a

# Unset sensitive variables after use
unset PRIVATE_KEY

wait
