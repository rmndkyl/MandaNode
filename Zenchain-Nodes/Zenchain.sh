#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 2

# Define constants
ZCHAIN_IMAGE="ghcr.io/zenchain-protocol/zenchain-testnet:latest"
DATA_DIR="$HOME/zenchain-data"
CONTAINER_NAME="zenchain"
BOOTNODES="/dns4/node-7242611732906999808-0.p2p.onfinality.io/tcp/26266/p2p/12D3KooWLAH3GejHmmchsvJpwDYkvacrBeAQbJrip5oZSymx5yrE"
CHAIN_NAME="zenchain_testnet"

# Function to pull Zenchain Docker image
pull_docker_image() {
    echo "Pulling Zenchain Docker image..."
    docker pull $ZCHAIN_IMAGE
    echo "Docker image pulled successfully!"
}

# Function to create a directory for chain data
create_data_directory() {
    echo "Creating directory for Zenchain data..."
    mkdir -p $DATA_DIR
    echo "Directory created at $DATA_DIR"
}

# Function to run the Zenchain node
run_zenchain_node() {
    echo "Checking if the Zenchain Docker image is available..."
    if [[ "$(docker images -q $ZCHAIN_IMAGE 2> /dev/null)" == "" ]]; then
        pull_docker_image
    fi

    create_data_directory

    read -p "Enter a name for your Zenchain node: " NODE_NAME
    echo "Choose mode: 1) Development 2) Production"
    read -p "Enter mode number: " mode

    if [[ $mode -eq 1 ]]; then
        echo "Running Zenchain node '$NODE_NAME' in development mode..."
        docker run -d \
          --name $CONTAINER_NAME \
          -p 9944:9944 \
          -v $DATA_DIR:/chain-data \
          $ZCHAIN_IMAGE \
          ./usr/bin/zenchain-node \
          --dev
    elif [[ $mode -eq 2 ]]; then
        echo "Running Zenchain node '$NODE_NAME' in production mode..."
        docker run -d \
          --name $CONTAINER_NAME \
          -p 9944:9944 \
          -v $DATA_DIR:/chain-data \
          $ZCHAIN_IMAGE \
          ./usr/bin/zenchain-node \
          --base-path=/chain-data \
          --rpc-cors=all \
          --unsafe-rpc-external \
          --validator \
          --name="$NODE_NAME" \
          --bootnodes="$BOOTNODES" \
          --chain=$CHAIN_NAME
    else
        echo "Invalid mode selected!"
    fi

    echo "Zenchain node '$NODE_NAME' is now running."
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Function to monitor Zenchain node logs
monitor_node_logs() {
    echo "Monitoring Zenchain node logs..."
    docker logs -f $CONTAINER_NAME
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Function to restart the Zenchain node
restart_zenchain_node() {
    echo "Restarting Zenchain node..."
    docker restart $CONTAINER_NAME
    echo "Zenchain node restarted successfully."
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Function to delete the Zenchain node
delete_zenchain_node() {
    echo "Stopping and removing the Zenchain node..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
    echo "Zenchain node deleted successfully."
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Function to generate and configure session keys
generate_session_keys() {
    echo "To generate session keys, you need to make an RPC call to 'author_rotateKeys'."
    echo "Use the output of this call to configure session keys for your Ethereum account."
    echo "Refer to the documentation for instructions on using polkadotjs-apps with MetaMask."
    echo "After configuring, restart the node with a secure setup."
}

# Main menu
show_menu() {
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ ZenChain Node Management Tool ===================================="
    echo "Node community Telegram channel: https://t.me/layerairdrop"
    echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "To exit the script, press ctrl + C on the keyboard."
    echo "Please select an action:"
    echo "1) Run Zenchain Node"
    echo "2) Monitor Node Logs"
    echo "3) Restart Zenchain Node"
    echo "4) Delete Zenchain Node"
    echo "5) Generate Session Keys"
    echo "6) Exit"
    echo "----------------------------------------"
    read -p "Enter your choice: " choice
    case $choice in
        1) run_zenchain_node ;;
        2) monitor_node_logs ;;
        3) restart_zenchain_node ;;
        4) delete_zenchain_node ;;
        5) generate_session_keys ;;
        6) exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
}

# Loop the menu
while true; do
    show_menu
done
