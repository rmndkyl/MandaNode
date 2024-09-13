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
    echo "6. Exit"
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
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            main_menu
            ;;
    esac
}

# Function to update the system and install prerequisites
function update_system {
    echo "1. Updating system and installing prerequisites..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install apt-transport-https ca-certificates curl software-properties-common jq bc -y
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

    main_menu
}

# Function to initialize the Nillion accuser
function initialize_accuser {
    echo "3. Initializing Nillion accuser..."
    mkdir -p nillion/accuser
    docker pull nillion/retailtoken-accuser:latest
    docker run -v "$(pwd)/nillion/accuser:/var/tmp" nillion/retailtoken-accuser:v1.0.1 initialise

    SECRET_FILE="./nillion/accuser/credentials.json"
    if [ -f "$SECRET_FILE" ]; then
        ADDRESS=$(jq -r '.address' "$SECRET_FILE")
        echo "Request Nillion faucet (https://faucet.testnet.nillion.com) to your accuser wallet address: $ADDRESS"

        read -p "Have you requested the faucet to the accuser wallet? (y/Y to proceed): " FAUCET_REQUESTED1
        if [[ "$FAUCET_REQUESTED1" =~ ^[yY]$ ]]; then
            echo "Now visit: https://verifier.nillion.com/verifier"
            echo "Connect a new Keplr wallet."
            echo "Request faucet to the Nillion address: https://faucet.testnet.nillion.com"

            read -p "Have you requested faucet to your Keplr wallet? (y/Y to proceed): " FAUCET_REQUESTED2
            if [[ "$FAUCET_REQUESTED2" =~ ^[yY]$ ]]; then
                read -p "Input your Keplr wallet's Nillion address: " KEPLR

                echo "Input the following information on the website: https://verifier.nillion.com/verifier"
                echo "Address: $ADDRESS"
                echo "Public Key: $(jq -r '.pub_key' "$SECRET_FILE")"

                read -p "Have you done this? (y/Y to proceed): " address_submitted
                if [[ "$address_submitted" =~ ^[yY]$ ]]; then
                    echo "Save this Private Key in a safe place: $(jq -r '.priv_key' "$SECRET_FILE")"
                    read -p "Have you saved the private key? (y/Y to proceed): " private_key_saved
                    if [[ "$private_key_saved" =~ ^[yY]$ ]]; then
                        echo "Running Docker container with accuse command..."
                        docker run -v "$(pwd)/nillion/accuser:/var/tmp" nillion/retailtoken-accuser:v1.0.1 accuse --rpc-endpoint "https://nillion-testnet.rpc.nodex.one" --block-start "$(curl -s "https://testnet-nillion-api.lavenderfive.com/cosmos/tx/v1beta1/txs?query=message.sender='$KEPLR'&pagination.limit=20&pagination.offset=0" | jq -r '[.tx_responses[] | select(.tx.body.memo == "AccusationRegistrationMessage")] | sort_by(.height | tonumber) | .[-1].height | tonumber - 5' | bc)"
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
    else
        echo "credentials.json file not found. Ensure the initialization step completed successfully."
    fi
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
    main_menu
}

# Display main menu on script start
main_menu
