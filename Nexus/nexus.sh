#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Define service name and file path
SERVICE_NAME="nexus"
SERVICE_FILE="/etc/systemd/system/nexus.service"  # Update service file path

# Script save path
SCRIPT_PATH="$HOME/nexus.sh"

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root privileges."
    echo "Please try switching to the root user using the 'sudo -i' command, then run this script again."
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
        echo "To exit the script, please press ctrl + C."
        echo "Please choose an operation:"
        echo "1. Start node"
        echo "2. Check Prover status"
        echo "3. View logs"
        echo "4. Delete node"
        echo "5. Show ID"  # New option
        echo "6. Improved status logic"  # New option
        echo "7. Exit"
        
        read -p "Enter your choice (1-7): " choice
        
        case $choice in
            1)
                start_node  # Call start node function
                ;;
            2)
                check_prover_status  # Call check Prover status function
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
                improved_status_logic  # Call improved status logic function
                ;;
            7)
                echo "Exiting the script."
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

    # Wait for user to press any key to return to main menu
    read -p "Press any key to return to the main menu"
}

# Function to start the node
function start_node() {
    # Ensure the directory exists
    mkdir -p /root/.nexus  # Create directory if it doesn't exist
    
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
        echo "Rust installation complete."
        
        # Load Rust environment
        source $HOME/.cargo/env
        echo "Rust environment loaded."
    fi

    # Clone the specified GitHub repository
    echo "Cloning the repository..."
    git clone https://github.com/nexus-xyz/network-api.git

    # Install dependencies
    cd $HOME/network-api/clients/cli
    echo "Installing required dependencies..." 
    if ! sudo apt install pkg-config libssl-dev -y; then
        echo "Failed to install dependencies."  # Error message
        exit 1
    fi

    # Create systemd service file
    echo "Creating systemd service..." 
    SERVICE_FILE="/etc/systemd/system/nexus.service"  # Update service file path
    if ! sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Nexus XYZ Prover Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
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

# Function to check Prover status
function check_prover_status() {
    echo "Checking Prover status..."
    systemctl status nexus.service
}

# Function to view logs
function view_logs() {
    echo "Viewing Prover logs..."
    journalctl -u nexus.service -f -n 50
}

# Function to delete the node
function delete_node() {
    echo "Deleting node..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
    echo "Node deleted successfully, press any key to return to the main menu."
    
    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu"
}

# Improved status logic function
function improved_status_logic() {
    if sudo systemctl is-active --quiet $SERVICE_NAME.service; then
        show_status "Service is running." 
    else
        show_status "Failed to retrieve service status." 
    fi

    show_status "Nexus Prover installation and service setup completed!" 
}

# Function to show status
function show_status() {
    echo "$1"
}

# Call the main menu function
main_menu
