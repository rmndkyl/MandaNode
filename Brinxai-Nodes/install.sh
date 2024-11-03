#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define log function
log() {
    local level="$1"
    local message="$2"
    echo "[$level] $message"
}

# Update package list and install dependencies
log "INFO" "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl gnupg lsb-release wget

# Check if GPU is available
log "INFO" "Checking GPU availability..."
GPU_AVAILABLE=false
if command -v nvidia-smi &> /dev/null; then
    log "INFO" "GPU detected. NVIDIA driver is installed."
    GPU_AVAILABLE=true
else
    log "INFO" "No GPU detected or NVIDIA driver not installed."
fi

# Prompt user for WORKER_PORT
read -p "Enter the port number for WORKER_PORT (default is 5011): " USER_PORT
USER_PORT=${USER_PORT:-5011}

# Create .env file with user-defined WORKER_PORT
log "INFO" "Creating .env file..."
cat <<EOF > .env
WORKER_PORT=$USER_PORT
EOF

# Create docker-compose.yml file
log "INFO" "Creating docker-compose.yml..."
if [ "$GPU_AVAILABLE" = true ]; then
    cat <<EOF > docker-compose.yml
version: '3.8'

services:
  worker:
    image: admier/brinxai_nodes-worker:latest
    environment:
      - WORKER_PORT=\${WORKER_PORT:-5011}
    ports:
      - "\${WORKER_PORT:-5011}:\${WORKER_PORT:-5011}"
    volumes:
      - ./generated_images:/usr/src/app/generated_images
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - brinxai-network
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    runtime: nvidia

networks:
  brinxai-network:
    driver: bridge
    name: brinxai-network  # Explicitly set the network name
EOF
else
    cat <<EOF > docker-compose.yml
version: '3.8'

services:
  worker:
    image: admier/brinxai_nodes-worker:latest
    environment:
      - WORKER_PORT=\${WORKER_PORT:-5011}
    ports:
      - "\${WORKER_PORT:-5011}:\${WORKER_PORT:-5011}"
    volumes:
      - ./generated_images:/usr/src/app/generated_images
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - brinxai-network

networks:
  brinxai-network:
    driver: bridge
    name: brinxai-network  # Explicitly set the network name
EOF
fi

# Check if `docker compose` or `docker-compose` is available and run accordingly
if command -v docker-compose &> /dev/null; then
    if sudo docker-compose up -d; then
        log "INFO" "Started Docker containers with 'docker-compose up -d'."
    else
        log "ERROR" "Failed to start Docker containers with 'docker-compose up -d'. Please check your Docker setup."
    fi
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    if sudo docker compose up -d; then
        log "INFO" "Started Docker containers with 'docker compose up -d'."
    else
        log "ERROR" "Failed to start Docker containers with 'docker compose up -d'. Please check your Docker setup."
    fi
else
    log "ERROR" "Neither 'docker-compose' nor 'docker compose' is available. Please install Docker Compose."
fi

log "INFO" "Installation and setup completed successfully."
