#!/bin/bash

# Stop and remove existing nillion containers
docker ps -a | grep nillion | awk '{print $1}' | xargs -I {} docker stop {} && \
docker ps -a | grep nillion | awk '{print $1}' | xargs -I {} docker rm {}

# Get the latest block height
LATEST_BLOCK=$(curl -s https://testnet-nillion-rpc.lavenderfive.com/status | jq -r .result.sync_info.latest_block_height)

# Check if LATEST_BLOCK is a valid number
if ! [[ "$LATEST_BLOCK" =~ ^[0-9]+$ ]]; then
    echo "Failed to retrieve the latest block height."
    exit 1
fi

# Run the docker container with the retrieved block height
docker run -d -v ./nillion/accuser:/var/tmp nillion/retailtoken-accuser:v1.0.0 accuse --rpc-endpoint "https://testnet-nillion-rpc.lavenderfive.com" --block-start "$LATEST_BLOCK"

# Follow the logs of the running container
docker logs -f $(docker ps | grep nillion | awk '{print $NF}')
