#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/Nillion.sh"

# Ensure the script is run with root privileges
if [ "$(id -u)" -ne "0" ]; then
  echo "Please run this script as root or using sudo"
  exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
        echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
        echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
        echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
        echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
        echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
        echo "============================ Nillion Verifier Setup ==================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press Ctrl+C"
        echo "Please select an action:"
        echo "1) Install node"
        echo "2) View logs"
        echo "3) Remove node"
        echo "4) Change RPC and restart node"
        echo "5) View public_key and account_id"
        echo "6) Update node script"
        echo "7) Migrate validator (for users before 9.24)"
        echo "8) Exit"

        read -p "Enter your choice (1, 2, 3, 4, 5, 6, 7, 8): " choice

        case $choice in
            1) install_node ;;
            2) query_logs ;;
            3) delete_node ;;
            4) change_rpc ;;
            5) view_credentials ;;
            6) update_script ;;
            7) migrate_validator ;;
            8) echo "Exiting script."; exit 0 ;;
            *) echo "Invalid option, please enter 1, 2, 3, 4, 5, 6, 7, or 8." ;;
        esac
    done
}

# Migrate validator function
function migrate_validator() {
    echo "Stopping and removing Docker container nillion_verifier..."
    docker stop nillion_verifier
    docker rm nillion_verifier

    echo "Migrating validator..."
    docker run -v ./nillion/accuser:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "https://nillion-testnet-rpc.polkachu.com"
}

# Install node function
function install_node() {
    # Check if Docker is installed
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
    else
        echo "Docker is not installed, installing..."

        # Update the package list
        apt-get update

        # Install necessary packages to allow apt to use repositories over HTTPS
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common

        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

        # Add Docker repository
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        # Update the package list
        apt-get update

        # Install Docker
        apt-get install -y docker-ce

        # Start and enable Docker service
        systemctl start docker
        systemctl enable docker

        echo "Docker installation complete."
    fi

    # Pull the specified Docker image
    echo "Pulling image nillion/verifier:v1.0.1..."
    docker pull nillion/verifier:v1.0.1

    # Install jq
    echo "Installing jq..."
    apt-get install -y jq
    echo "jq installation complete."

    # Initialize the directory and run Docker container
    echo "Initializing configuration..."
    mkdir -p nillion/verifier
    docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise
    echo "Initialization complete."

    # Prompt user to save important information
    echo "Initialization complete. Please check the following files for important information:"
    echo "account_id and public_key are saved in the ~/nillion/verifier directory."
    echo "Make sure to save this information as it is important for future operations."

    echo "You can view the saved file contents with these commands:"
    echo "cat ~/nillion/verifier/account_id"
    echo "cat ~/nillion/verifier/public_key"

    echo "Make sure to securely save this information and avoid sharing it."

    # Wait for user to press any key to continue
    read -p "Press any key to continue..."

    # Use a fixed RPC link
    selected_rpc_url="https://nillion-testnet-rpc.polkachu.com"

    # Query sync information
    echo "Querying sync information from $selected_rpc_url..."
    sync_info=$(curl -s "$selected_rpc_url/status" | jq .result.sync_info)

    # Display sync information
    echo "Sync information:"
    echo "$sync_info"

    # Prompt user if the node is synced
    read -p "Is the node synced? (Enter 'yes' if synced, 'no' if not): " sync_status

    if [ "$sync_status" = "yes" ]; then
        # Run the node
        echo "Running the node..."
        docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "https://nillion-testnet-rpc.polkachu.com"
        echo "Node is running."
    else
        echo "Node not synced. The script will exit."
        exit 1
    fi
    
    # Wait for user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Function to query logs
function query_logs() {
    # View Docker container logs
    echo "Fetching logs for nillion_verifier container..."

    # Check if the container exists
    if [ "$(docker ps -q -f name=nillion_verifier)" ]; then
        docker logs -f nillion_verifier --tail 100
    else
        echo "No running nillion_verifier container found."
    fi

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Function to delete the node
function delete_node() {
    echo "Backing up the /root/nillion/verifier directory..."
    tar -czf /root/nillion/verifier_backup_$(date +%F).tar.gz /root/nillion/verifier
    echo "Backup complete."

    echo "Stopping and removing Docker container nillion_verifier..."
    docker stop nillion_verifier
    docker rm nillion_verifier
    echo "Node has been deleted."

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Function to change RPC
function change_rpc() {
    # Use a fixed RPC link
    new_rpc_url="https://nillion-testnet-rpc.polkachu.com"

    echo "Stopping and removing the existing Docker container nillion_verifier..."
    docker stop nillion_verifier
    docker rm nillion_verifier

    echo "Running the new Docker container..."
    docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "$new_rpc_url"

    echo "Node has been updated to the new RPC."

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Function to update the script
function update_script() {
    # Pull the image
    echo "Pulling image nillion/verifier:v1.0.1..."
    docker pull nillion/verifier:v1.0.1

    echo "Update complete."

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Function to view credentials
function view_credentials() {
    echo "account_id and public_key are saved in the ~/nillion/accuser directory."
    echo "You can view the saved files using the following commands:"
    echo "cat ~/nillion/verifier/account_id"
    echo "cat ~/nillion/verifier/public_key"

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Start the main menu
main_menu
