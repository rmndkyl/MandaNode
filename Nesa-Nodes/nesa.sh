	#!/bin/bash

LOG_FILE="$HOME/nesa_install.log"

# Function for logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Function to check command status
check_status() {
    if [ $? -ne 0 ]; then
        log_message "Error: $1 failed."
        echo "$1 failed. Check the log file for details."
        exit 1
    else
        log_message "$1 succeeded."
    fi
}

# Showing Logo
log_message "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
check_status "Loader Animation Download"
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
check_status "Logo Download"
sleep 4

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "============================ Nesa Node Installation ===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source."
        echo "To exit the script, press ctrl+c on the keyboard."
        echo "Please choose an option:"
        echo "1) Install Node"
        echo "2) Get Node Status URL"
        echo "3) Check Nesa Node Status"
        echo "4) Start Nesa Node"
        echo "5) Stop Nesa Node"
        echo "6) Restart Nesa Node"
        echo "7) Update Nesa Node"
        echo "8) Delete Nesa Node"
        echo "9) View Private Key and Node ID"
        echo "10) Exit"
        read -p "Enter your choice [1-10]: " choice

        case $choice in
            1)
                install_node
                ;;
            2)
                get_node_status_url
                ;;
            3)
                check_nesa_status
                ;;
            4)
                start_node
                ;;
            5)
                stop_node
                ;;
            6)
                restart_node
                ;;
            7)
                update_node
                ;;
            8)
                delete_node
                ;;
            9)
                view_private_key_and_node_id
                ;;
            10)
                echo "Exiting the script."
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

# Function to check Nesa node status
function check_nesa_status() {
    echo "Checking Nesa Node status..."
    # Run the status command and capture the exit code
    sudo systemctl status nesa-node.service > /tmp/nesa_node_status.txt
    if [ $? -eq 0 ]; then
        echo "Nesa Node status:"
        cat /tmp/nesa_node_status.txt | grep -E "Loaded|Active|Main PID|Tasks|Memory|CPU|CGroup"
        echo "Nesa Node is running."
    else
        echo "Failed to retrieve Nesa Node status."
    fi
    # Clean up temporary file
    rm /tmp/nesa_node_status.txt
    read -p "Press any key to return to the main menu..."
}

# Function to start the Nesa node
function start_node() {
    echo "Starting Nesa Node..."
    sudo systemctl start nesa-node.service
    if [ $? -eq 0 ]; then
        echo "Nesa Node started successfully."
    else
        echo "Failed to start Nesa Node."
    fi
    read -p "Press any key to return to the main menu..."
}

# Function to stop the Nesa node
function stop_node() {
    echo "Stopping Nesa Node..."
    sudo systemctl stop nesa-node.service
    if [ $? -eq 0 ]; then
        echo "Nesa Node stopped successfully."
    else
        echo "Failed to stop Nesa Node."
    fi
    read -p "Press any key to return to the main menu..."
}

# Function to restart the Nesa node
function restart_node() {
    echo "Restarting Nesa Node..."
    sudo systemctl restart nesa-node.service
    if [ $? -eq 0 ]; then
        echo "Nesa Node restarted successfully."
    else
        echo "Failed to restart Nesa Node."
    fi
    read -p "Press any key to return to the main menu..."
}

# Function to update the Nesa node
function update_node() {
    echo "Updating Nesa Node..."
    cd $HOME/nesa-node && git pull
    if [ $? -eq 0 ]; then
        echo "Nesa Node updated successfully."
    else
        echo "Failed to update Nesa Node."
    fi
    read -p "Press any key to return to the main menu..."
}

# Function to delete Nesa nodes
function delete_node() {
    echo "Deleting Nesa Node..."
    sudo systemctl stop nesa-node.service
    sudo systemctl disable nesa-node.service
    sudo rm -rf /etc/systemd/system/nesa-node.service
    sudo rm -rf $HOME/nesa-node
    if [ $? -eq 0 ]; then
        echo "Nesa Node deleted successfully."
    else
        echo "Failed to delete Nesa Node."
    fi
    read -p "Press any key to return to the main menu..."
}

# Function to view Private Key and Node ID
function view_private_key_and_node_id() {
    if [ -f "$HOME/.nesa/identity/node_id.id" ]; then
        PUB_KEY=$(cat $HOME/.nesa/identity/node_id.id)
        PRIVATE_KEY=$(cat $HOME/.nesa/identity/private_key.id)
        echo "Node ID: $PUB_KEY"
        echo "Private Key: $PRIVATE_KEY"
    else
        echo "Node ID or Private Key not found. Please ensure $HOME/.nesa/identity/ exists."
    fi
    read -p "Press any key to return to the main menu..."
}

# Function to get the Node Status URL
function get_node_status_url() {
    if [ -f "$HOME/.nesa/identity/node_id.id" ]; then
        PUB_KEY=$(cat $HOME/.nesa/identity/node_id.id)
        echo "Node Status URL: https://node.nesa.ai/nodes/$PUB_KEY"
    else
        echo "Node identity file not found. Please make sure $HOME/.nesa/identity/node_id.id exists."
    fi
    read -p "Press any key to return to the main menu..."
}

# Separate functions for node types to keep install_node clean
function configure_validator_node() {
    read -p "Validator's Private Key: " PRIVATE_KEY
    log_message "Configured Validator Node: Private Key entered."
}

function configure_distributed_miner_node() {
    PS3="Please select a swarm action: "
    SWARM_ACTION_OPTIONS=("Join existing swarm" "Start a new swarm" "Exit")
    select SWARM_ACTION in "${SWARM_ACTION_OPTIONS[@]}"
    do
        case $SWARM_ACTION in
            "Start a new swarm")
                read -p "Which model would you like to run? (meta-llama/Llama-2-13b-Chat-Hf): " MODEL
                MODEL=${MODEL:-Llama-2-13b-Chat-Hf}
                log_message "Configured Distributed Miner Node: Model $MODEL"
                break
                ;;
            "Join existing swarm")
                echo "Joining existing swarm logic here."
                log_message "Configured Distributed Miner Node: Joining existing swarm."
                break
                ;;
            "Exit")
                exit 1
                ;;
            *)
                echo "Invalid option $REPLY"
                ;;
        esac
    done
}

function configure_non_distributed_miner_node() {
    read -p "Which model would you like to run? (meta-llama/Llama-2-13b-Chat-Hf): " MODEL
    MODEL=${MODEL:-Llama-2-13b-Chat-Hf}
    log_message "Configured Non-Distributed Miner Node: Model $MODEL"
}

# Function to check if a port is available
check_port() {
    local PORT=$1
    if sudo lsof -i:"$PORT" &> /dev/null; then
        log_message "Port $PORT is already in use."
        return 1
    else
        log_message "Port $PORT is available."
        return 0
    fi
}

# Function to configure Docker ports
configure_docker_ports() {
    local DEFAULT_PORT=8080
    local DEFAULT_PORT_DB=5432
    local NEW_PORT
    local NEW_PORT_DB

    log_message "Checking if default ports are available..."

    # Check if the default ports are available
    if check_port "$DEFAULT_PORT" && check_port "$DEFAULT_PORT_DB"; then
        log_message "Using default ports: $DEFAULT_PORT and $DEFAULT_PORT_DB."
        NEW_PORT=$DEFAULT_PORT
        NEW_PORT_DB=$DEFAULT_PORT_DB
    else
        # If default ports are taken, prompt the user for new ports
        log_message "Default ports are taken. Please provide new port values."
        read -p "Enter a new port for the node service (e.g., 8081): " NEW_PORT
        read -p "Enter a new port for the database service (e.g., 5433): " NEW_PORT_DB
    fi

    # Update the docker-compose.yml with new port values
    sed -i "s/8080:8080/$NEW_PORT:8080/" "$HOME/nesa-node/docker-compose.yml"
    sed -i "s/5432:5432/$NEW_PORT_DB:5432/" "$HOME/nesa-node/docker-compose.yml"
    log_message "Docker ports configured: Node service on $NEW_PORT, DB service on $NEW_PORT_DB."
}

# Install the Node with error handling, separation of logic, and logging
function install_node() {
    log_message "Starting node installation..."

    # Update the system and install curl
    sudo apt-get update && sudo apt-get install -y curl
    check_status "System Update and curl Installation"

    # Docker installation with error handling
    echo "Installing Docker..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    check_status "Docker Installation"

    # Start Docker service
    sudo systemctl start docker && sudo systemctl enable docker
    check_status "Docker Service Start"

    # NVIDIA driver installation check with logging and error handling
    if ! command -v nvidia-smi &> /dev/null; then
        log_message "NVIDIA drivers not found. Installing..."
        sudo add-apt-repository ppa:graphics-drivers/ppa && sudo apt-get update && sudo apt-get install -y ubuntu-drivers-common
        check_status "NVIDIA PPA and Driver Installation"
        sudo ubuntu-drivers autoinstall
        check_status "NVIDIA Driver Autoinstall"
    else
        log_message "NVIDIA drivers already installed."
    fi

    # Install gum
    if ! command -v gum &> /dev/null; then
        log_message "Installing gum..."
        curl -fsSL https://github.com/charmbracelet/gum/releases/download/v0.18.0/gum_0.18.0_linux_amd64.tar.gz | sudo tar xz -C /usr/local/bin
        check_status "gum Installation"
    else
        log_message "gum already installed."
    fi

    # Install jq
    if ! command -v jq &> /dev/null; then
        log_message "Installing jq..."
        sudo apt-get install -y jq
        check_status "jq Installation"
    else
        log_message "jq already installed."
    fi

    # Configure Docker ports
    configure_docker_ports

    # Configure the node
    echo "Configuring the node..."
    read -p "Please choose a unique name for your node: " NODE_NAME
    PS3="Please select the node type: "
    NODE_TYPE_OPTIONS=("Validator" "Distributed Miner" "Non-Distributed Miner" "Exit")
    select NODE_TYPE in "${NODE_TYPE_OPTIONS[@]}"
    do
        case $NODE_TYPE in
            "Validator")
                configure_validator_node
                break
                ;;
            "Distributed Miner")
                configure_distributed_miner_node
                break
                ;;
            "Non-Distributed Miner")
                configure_non_distributed_miner_node
                break
                ;;
            "Exit")
                exit 1
                ;;
            *)
                echo "Invalid option $REPLY"
                ;;
        esac
    done

    # Run the remote initialization script
    log_message "Running remote initialization script..."
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
    check_status "Remote Initialization Script"

    # Create systemd service
    echo "Creating systemd service for Nesa Node..."
    sudo tee /etc/systemd/system/nesa-node.service > /dev/null <<EOF
[Unit]
Description=Nesa Node Service
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=$HOME/nesa-node
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nesa-node.service
    sudo systemctl start nesa-node.service
    check_status "Nesa Node Systemd Setup"

    log_message "Nesa Node installed and started successfully."
    read -p "Press any key to return to the main menu..."
}

# Run the main menu
main_menu
