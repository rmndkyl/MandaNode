#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Define service name and file path
SERVICE_NAME="nexus"
SERVICE_FILE="/etc/systemd/system/nexus.service"  # Update the service file path

# Script save path
SCRIPT_PATH="$HOME/nexus.sh"

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as root."
    echo "Please try using 'sudo -i' to switch to the root user and run this script again."
    exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version"
        echo "============================== Nexus Prover Automation! ===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press ctrl + C on the keyboard."
        echo "Please choose an operation:"
        echo "1. Start Node"
        echo "2. Check Prover Status"
        echo "3. View Logs"
        echo "4. Delete Node"
        echo "5. Show ID"  # Added option
        echo "6. Exit"
        
        read -p "Please enter an option (1-6): " choice
        
        case $choice in
            1)
                start_node  # Call start node function
                ;;
            2)
                check_prover_status  # Call check prover status function
                ;;
            3)
                view_logs  # Call view logs function
                ;;
            4)
                delete_node  # Call delete node function
                ;;
            5)
                show_id  # Call show ID function
                ;;
            6)
                echo "Exiting script."
                exit 0
                ;;
            *)
                echo "Invalid option, please choose again."
                ;;
        esac
    done
}

# Function to show ID
function show_id() {
    if [ -f /root/.nexus/prover-id ]; then
        echo "Prover ID content:"
        echo "$(</root/.nexus/prover-id)"  # Use echo to display file content
    else
        echo "File /root/.nexus/prover-id does not exist."
    fi

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu"
}

# Function to start the node
function start_node() {
    # Check if the service is already running
    if systemctl is-active --quiet nexus.service; then
        echo "nexus.service is currently running. Stopping and disabling it..."
        sudo systemctl stop nexus.service
        sudo systemctl disable nexus.service
    else
        echo "nexus.service is not currently running."
    fi

    # Ensure the directory exists
    mkdir -p /root/.nexus  # Create directory (if it doesn't exist)

    # Update the system and install necessary packages
    echo "Updating the system and installing necessary packages..."
    if ! sudo apt update && sudo apt upgrade -y && sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y; then
        echo "Failed to install packages."  # Error message
        exit 1
    fi
    
    # Check and install Git
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Installing Git..."
        if ! sudo apt install git -y; then
            echo "Failed to install Git."  # Error message
            exit 1
        fi
    else
        echo "Git is already installed."  # Success message
    fi

    # Check if Rust is installed
    if command -v rustc &> /dev/null; then
        echo "Rust is installed, version: $(rustc --version)"
    else
        echo "Rust is not installed, installing Rust..."
        # Install Rust using rustup
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        echo "Rust installation completed."
        
        # Load Rust environment
        source $HOME/.cargo/env
        export PATH="$HOME/.cargo/bin:$PATH"
        echo "Rust environment loaded."
    fi

    if [ -d "$HOME/network-api" ]; then
        echo "Removing existing repository..."
        rm -rf "$HOME/network-api"
    fi
    
    # Clone the specified GitHub repository
    echo "Cloning repository..."
    cd
    git clone https://github.com/nexus-xyz/network-api.git

    # Install dependencies
    cd $HOME/network-api/clients/cli
    echo "Installing required dependencies..." 
    if ! sudo apt install pkg-config libssl-dev -y; then
        echo "Failed to install dependencies."  # Error message
        exit 1
    fi
    
    # Create a systemd service file
    echo "Creating systemd service..." 
    if ! sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Nexus XYZ Prover Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
Environment=PATH=/root/.cargo/bin:$PATH
ExecStart=$HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"; then
        echo "Failed to create systemd service file." 
        exit 1
    fi

    # Reload systemd and start the service
    echo "Reloading systemd and starting the service..." 
    if ! sudo systemctl daemon-reload; then
        echo "Failed to reload systemd."
        exit 1
    fi

    if ! sudo systemctl start nexus.service; then
        echo "Failed to start the service." 
        exit 1
    fi

    if ! sudo systemctl enable nexus.service; then
        echo "Failed to enable the service." 
        exit 1
    fi

    echo "Node started successfully!"
    
    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu"
}

# Function to check the Prover status
function check_prover_status() {
    echo "Checking Prover status..."
    systemctl status nexus.service
}

# Function to view the logs
function view_logs() {
    echo "Viewing Prover logs..."
    journalctl -u nexus.service -f -n 50
}

# Function to delete the node
function delete_node() {
    echo "Deleting the node..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
    rm -rf /root/network-api
    rm -rf /etc/systemd/system/nexus.service
    echo "Node successfully deleted. Press any key to return to the main menu."
    
    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu"
}

# Function to show status
function show_status() {
    echo "$1"
}

# Call the main menu function
main_menu
