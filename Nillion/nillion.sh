#!/bin/bash

# Display a logo or banner (optional step, fetched from an external source)
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to handle errors and exit the script
function error_exit {
    echo "$1" >&2
    exit 1
}

# Main Menu Function
function main_menu {
    clear
    echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
    echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
    echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
    echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
    echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
    echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ Nillion Verifier Setup ==================================="
    echo "Node community Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
    echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "1. Update system and install prerequisites"
    echo "2. Install Docker"
    echo "3. Initialize Nillion accuser"
    echo "4. Show account information"
    echo "5. Remove existing Nillion setup"
    echo "6. View Nillion Verifier logs"
    echo "7. Start Nillion Verifier"
    echo "8. Restart Nillion Verifier"
    echo "9. Stop Nillion Verifier"
    echo "10. Exit"
    echo "======================================================================================"
    read -p "Select an option: " choice

    case $choice in
        1)
            update_system
            ;;
        2)
            install_docker
            ;;
        3)
            initialize_accuser
            ;;
        4)
            show_account_info
            ;;
        5)
            remove_nillion
            ;;
        6)
            view_logs
            ;;
        7)
            start_verifier
            ;;
        8)
            restart_verifier
            ;;
        9)
            stop_verifier
            ;;
        10)
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            read -p "Press any key to return to the main menu..."
            main_menu
            ;;
    esac
}

# Function to update the system and install prerequisites
function update_system {
    echo "1. Updating system and installing prerequisites..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install apt-transport-https ca-certificates curl software-properties-common jq bc -y
    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to install Docker
function install_docker {
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
    else
        echo "2. Installing Docker..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install docker-ce docker-ce-cli containerd.io -y
        sudo docker run hello-world
    fi
    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to remove existing Nillion setup
function remove_nillion {
    echo "5. Removing existing Nillion setup..."

    if [ -d "nillion" ]; then
        echo "'nillion' directory found. Removing..."
        sudo rm -r "nillion"
    else
        echo "'nillion' directory not found."
    fi

    echo "Stopping and removing any running containers with the name 'nillion'..."
    sudo docker ps | grep nillion | awk '{print $1}' | xargs -r docker stop
    sudo docker ps -a | grep nillion | awk '{print $1}' | xargs -r docker rm

    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to initialize the Nillion accuser
function initialize_accuser {
    echo "3. Initializing Nillion accuser..."
    
    # Prompt user to choose between using an existing wallet or creating a new one
    read -p "Do you want to import an existing wallet? (y/Y for Yes, n/N for No): " wallet_choice

    if [[ "$wallet_choice" =~ ^[yY]$ ]]; then
        # Input Private Key, Public Key, and Account ID manually
        read -p "Enter your Private Key: " PRIVATE_KEY
        read -p "Enter your Public Key: " PUBLIC_KEY
        read -p "Enter your Account ID (Address): " ACCOUNT_ID

        # Create the credentials.json file with the provided data
        mkdir -p nillion/accuser
        SECRET_FILE="./nillion/accuser/credentials.json"

        cat > "$SECRET_FILE" <<EOL
{
    "priv_key": "$PRIVATE_KEY",
    "pub_key": "$PUBLIC_KEY",
    "address": "$ACCOUNT_ID"
}
EOL

        echo "Credentials saved to $SECRET_FILE"
    else
        # Create a new wallet (existing process)
        mkdir -p nillion/accuser
        docker pull nillion/retailtoken-accuser:latest
        docker run -v "$(pwd)/nillion/accuser:/var/tmp" nillion/retailtoken-accuser:v1.0.1 initialise

        SECRET_FILE="./nillion/accuser/credentials.json"
        if [ ! -f "$SECRET_FILE" ]; then
            echo "Failed to create new wallet. Please check the initialization process."
            return
        fi
    fi

    # Display wallet address and prompt to request faucet
    ADDRESS=$(jq -r '.address' "$SECRET_FILE")
    echo "Request Nillion faucet (https://faucet.testnet.nillion.com) to your accuser wallet address: $ADDRESS"

    read -p "Have you requested the faucet to the accuser wallet? (y/Y to proceed): " FAUCET_REQUESTED1
    if [[ "$FAUCET_REQUESTED1" =~ ^[yY]$ ]]; then
        echo "Now visit: https://verifier.nillion.com/verifier"
        echo "Connect a new Keplr wallet and request faucet for the Nillion address: https://faucet.testnet.nillion.com"

        read -p "Have you requested the faucet to your Keplr wallet? (y/Y to proceed): " FAUCET_REQUESTED2
        if [[ "$FAUCET_REQUESTED2" =~ ^[yY]$ ]]; then
            read -p "Input your Keplr wallet's Nillion address: " KEPLR

            # Display instructions to input address and public key
            echo "Input the following information on the website: https://verifier.nillion.com/verifier"
            echo "Address: $ADDRESS"
            echo "Public Key: $(jq -r '.pub_key' "$SECRET_FILE")"

            read -p "Have you done this? (y/Y to proceed): " address_submitted
            if [[ "$address_submitted" =~ ^[yY]$ ]]; then
                echo "Save this Private Key in a safe place: $(jq -r '.priv_key' "$SECRET_FILE")"
                
                read -p "Have you saved the private key? (y/Y to proceed): " private_key_saved
                if [[ "$private_key_saved" =~ ^[yY]$ ]]; then
                    echo "Fetching latest block height for accuse command..."

                    # Fetch latest block height from the RPC
                    LATEST_BLOCK_HEIGHT=$(curl -s "https://nillion-testnet-rpc.polkachu.com/status" | jq -r '.result.sync_info.latest_block_height')

                    if [[ "$LATEST_BLOCK_HEIGHT" == "null" || -z "$LATEST_BLOCK_HEIGHT" ]]; then
                        echo "Error: Could not retrieve the latest block height. Please check the RPC endpoint."
                        return
                    fi

                    # Use the latest block height minus a small offset (5 blocks back)
                    BLOCK_START=$(echo "$LATEST_BLOCK_HEIGHT - 5" | bc)
                    echo "Using block start height: $BLOCK_START"

                    # Stop any existing accuser container
                    echo "Stopping any existing accuser container..."
                    docker stop $(docker ps -q --filter "ancestor=nillion/retailtoken-accuser:v1.0.1")

                    # Run Docker container with accuse command
                    echo "Running Docker container with accuse command..."
                    docker run -v "$(pwd)/nillion/accuser:/var/tmp" \
                        -e SLEEP_INTERVAL=300 \
                        nillion/retailtoken-accuser:v1.0.1 accuse \
                        --rpc-endpoint "https://nillion-testnet-rpc.polkachu.com" \
                        --block-start "$BLOCK_START" || {
                        echo "Docker container failed. Check Docker logs for more details."
                        docker logs $(docker ps -q --filter "ancestor=nillion/retailtoken-accuser:v1.0.1")
                    }
                else
                    echo "Please save the private key and try again."
                fi
            else
                echo "Please complete the submission and try again."
            fi
        else
            echo "Please request the faucet to your Keplr wallet and try again."
        fi
    else
        echo "Please request the faucet and try again."
    fi

    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to show account information
function show_account_info {
    echo "4. Showing account information..."
    CREDENTIALS_FILE="./nillion/accuser/credentials.json"
    if [[ -f $CREDENTIALS_FILE ]]; then
        ACCOUNT_ID=$(jq -r '.address' $CREDENTIALS_FILE)
        PUBLIC_KEY=$(jq -r '.pub_key' $CREDENTIALS_FILE)
        echo "Account ID: $ACCOUNT_ID"
        echo "Public Key: $PUBLIC_KEY"
    else
        echo "Credentials file not found!"
    fi
    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to get container ID of Nillion Verifier based on image name
function get_container_id {
    echo "Fetching container ID for the Nillion Verifier..."
    container_id=$(docker ps -q --filter "ancestor=nillion/retailtoken-accuser:v1.0.1")

    if [ -z "$container_id" ]; then
        echo "No running container found for the Nillion Verifier."
    fi
}

# Function to view logs of Nillion Verifier
function view_logs {
    get_container_id
    if [ -n "$container_id" ]; then
        echo "Viewing logs for container ID: $container_id"
        sudo docker logs "$container_id" --follow
    fi
    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to start Nillion Verifier
function start_verifier {
    echo "Starting Nillion Verifier..."
    sudo docker start $(docker ps -aq --filter "ancestor=nillion/retailtoken-accuser:v1.0.1")
    echo "Nillion Verifier started."
    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to restart Nillion Verifier
function restart_verifier {
    get_container_id
    if [ -n "$container_id" ]; then
        echo "Restarting Nillion Verifier..."
        sudo docker restart "$container_id"
        echo "Nillion Verifier restarted."
    fi
    read -p "Press any key to return to the main menu..."
    main_menu
}

# Function to stop Nillion Verifier
function stop_verifier {
    get_container_id
    if [ -n "$container_id" ]; then
        echo "Stopping Nillion Verifier..."
        sudo docker stop "$container_id"
        echo "Nillion Verifier stopped."
    fi
    read -p "Press any key to return to the main menu..."
    main_menu
}

# Display main menu on script start
main_menu
