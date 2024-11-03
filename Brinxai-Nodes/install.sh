#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update package list and install dependencies
echo "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl gnupg lsb-release wget

# Check if GPU is available
echo "Checking GPU availability..."
GPU_AVAILABLE=false
if command -v nvidia-smi &> /dev/null
then
    echo "GPU detected. NVIDIA driver is installed."
    GPU_AVAILABLE=true
else
    echo "No GPU detected or NVIDIA driver not installed."
fi

# Prompt user for WORKER_PORT
read -p "Enter the port number for WORKER_PORT (default is 5011): " USER_PORT
USER_PORT=${USER_PORT:-5011}

# Create .env file with user-defined WORKER_PORT
echo "Creating .env file..."
cat <<EOF > .env
WORKER_PORT=$USER_PORT
EOF

# Create docker-compose.yml file
echo "Creating docker-compose.yml..."
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

# Try `docker compose up -d` first
if sudo docker compose up -d; then
    log "INFO" "Started Docker containers with 'docker compose up -d'."
else
    log "WARN" "'docker compose up -d' failed. Trying 'docker-compose up -d'..."
    
    # Fallback to `docker-compose up -d` if the first command fails
    if sudo docker-compose up -d; then
        log "INFO" "Started Docker containers with 'docker-compose up -d'."
    else
        log "ERROR" "Failed to start Docker containers with both 'docker compose up -d' and 'docker-compose up -d'. Please check your Docker setup."
    fi
fi

echo "Installation and setup completed successfully."
