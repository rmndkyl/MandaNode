#!/bin/bash

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/Fractal Bitcoin.sh"

# Main menu function
function main_menu() {
    while true; do
        clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Fractal Bitcoin Deploy Automation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press Ctrl+C."
        echo "Please select the operation to execute:"
        echo "1) Install Node (version 0.1.8)"
        echo "2) View Service Logs"
        echo "3) Create Wallet"
        echo "4) View Private Key"
        echo "5) Update Script (old version 0.1.7 update)"
        echo "6) Exit"
        echo -n "Please enter an option [1-6]: "
        read choice
        case $choice in
            1) install_node ;;
            2) view_logs ;;
            3) create_wallet ;;
            4) view_private_key ;;
            5) update_script ;;
            6) exit 0 ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}

# Install node function
function install_node() {
    echo "Starting system update, upgrading packages, and installing necessary packages..."

    # Update package list
    sudo apt update

    # Upgrade installed packages
    sudo apt upgrade -y

    # Install required packages
    sudo apt install make gcc chrony curl build-essential pkg-config libssl-dev git wget jq -y

    echo "System update, package upgrade, and installation completed."

    # Download fractald library
    echo "Downloading fractald library..."
    wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.1.8/fractald-0.1.8-x86_64-linux-gnu.tar.gz

    # Extract fractald library
    echo "Extracting fractald library..."
    tar -zxvf fractald-0.1.8-x86_64-linux-gnu.tar.gz

    # Enter fractald directory
    echo "Entering fractald directory..."
    cd fractald-0.1.8-x86_64-linux-gnu

    # Create data directory
    echo "Creating data directory..."
    mkdir data

    # Copy configuration file to data directory
    echo "Copying configuration file to data directory..."
    cp ./bitcoin.conf ./data

    # Create systemd service file
    echo "Creating systemd service file..."
    sudo tee /etc/systemd/system/fractald.service > /dev/null <<EOF
[Unit]
Description=Fractal Node
After=network.target

[Service]
User=root
WorkingDirectory=/root/fractald-0.1.8-x86_64-linux-gnu
ExecStart=/root/fractald-0.1.8-x86_64-linux-gnu/bin/bitcoind -datadir=/root/fractald-0.1.8-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd manager configuration
    echo "Reloading systemd manager configuration..."
    sudo systemctl daemon-reload

    # Start and enable the fractald service
    echo "Starting the fractald service and setting it to start on boot..."
    sudo systemctl start fractald
    sudo systemctl enable fractald

    echo "Node installation completed."
    
    # Prompt the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# View service logs function
function view_logs() {
    echo "Viewing fractald service logs..."
    sudo journalctl -u fractald -fo cat
    
    # Prompt the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Create wallet function
function create_wallet() {
    echo "Creating wallet..."
    cd /root/fractald-0.1.8-x86_64-linux-gnu/bin && ./bitcoin-wallet -wallet=wallet -legacy create
    
    # Prompt the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# View private key function
function view_private_key() {
    echo "Viewing private key..."
    
    # Enter fractald directory
    cd /root/fractald-0.1.8-x86_64-linux-gnu/bin
    
    # Use bitcoin-wallet to export the private key
    ./bitcoin-wallet -wallet=/root/.bitcoin/wallets/wallet/wallet.dat -dumpfile=/root/.bitcoin/wallets/wallet/MyPK.dat dump
    
    # Parse and display the private key
    awk -F 'checksum,' '/checksum/ {print "The wallet private key is:" $2}' /root/.bitcoin/wallets/wallet/MyPK.dat
    
    # Prompt the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Update script function
function update_script() {
    echo "Starting script update..."

    # Backup the data directory
    echo "Backing up the data directory..."
    sudo cp -r /root/fractald-0.1.7-x86_64-linux-gnu/data /root/fractal-data-backup

    # Download the new version of the fractald library
    echo "Downloading the new version of the fractald library..."
    wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.1.8/fractald-0.1.8-x86_64-linux-gnu.tar.gz

    # Extract the new version of the fractald library
    echo "Extracting the new version of the fractald library..."
    tar -zxvf fractald-0.1.8-x86_64-linux-gnu.tar.gz

    # Enter the new version fractald directory
    echo "Entering the new version fractald directory..."
    cd fractald-0.1.8-x86_64-linux-gnu

    # Restore the backup data files
    echo "Restoring the backup data files..."
    cp -r /root/fractal-data-backup /root/fractald-0.1.8-x86_64-linux-gnu/

    # Update systemd service file (if any changes)
    echo "Updating the systemd service file..."
    sudo tee /etc/systemd/system/fractald.service > /dev/null <<EOF
[Unit]
Description=Fractal Node
After=network.target

[Service]
User=root
WorkingDirectory=/root/fractald-0.1.8-x86_64-linux-gnu
ExecStart=/root/fractald-0.1.8-x86_64-linux-gnu/bin/bitcoind -datadir=/root/fractald-0.1.8-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd manager configuration
    echo "Reloading systemd manager configuration..."
    sudo systemctl daemon-reload

    # Enable and start the fractald service
    echo "Enabling and starting the fractald service..."
    sudo systemctl enable fractald
    sudo systemctl start fractald

    echo "Script update completed."

    # Prompt the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Start the main menu
main_menu
