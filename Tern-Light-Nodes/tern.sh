#!/bin/bash

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root user privileges."
    echo "Please try switching to the root user using 'sudo -i' and then run this script again."
    exit 1
fi

# Function to display the main menu
main_menu() {
    clear
    echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
    echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
    echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
    echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
    echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
    echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ Tern Light Node (Executor) Menu ================================="
    echo "Node community Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
    echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "1. Download and Initialize Tern Executor (Input Private Key)"
    echo "2. Start Executor"
    echo "3. View Logs"
    echo "4. Check Executor Status"
    echo "5. Stop Executor"
    echo "6. Restart Executor"
    echo "7. Update Executor"
    echo "8. Delete Executor"
    echo "9. Exit"
    echo "============================================================================================="
    read -p "Please choose an option: " choice
    case $choice in
        1) download_initialize_executor ;;
        2) start_executor ;;
        3) view_logs ;;
        4) check_status ;;
        5) stop_executor ;;
        6) restart_executor ;;
        7) update_executor ;;
        8) delete_executor ;;
        9) exit 0 ;;
        *) echo "Invalid choice. Please choose again." && read -n 1 -s -r -p "Press any key to continue..." && main_menu ;;
    esac
}

# Option 1: Download and Initialize Tern Executor (with Private Key input)
download_initialize_executor() {
    # Step 1: Input Private Key
    read -p "Enter your PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL
    echo "Private key stored successfully."

    # Step 2: Install dependencies
    echo "Updating package list and installing dependencies..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl wget tar build-essential jq unzip -y

    # Step 3: Define the latest version and download
    LATEST_VERSION="v0.21.0"
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_VERSION/executor-linux-$LATEST_VERSION.tar.gz"
    
    echo "Downloading executor version $LATEST_VERSION..."
    wget -q $EXECUTOR_URL -O executor-linux-$LATEST_VERSION.tar.gz
    tar -xvf executor-linux-$LATEST_VERSION.tar.gz

    # Step 4: Create a systemd service file
    echo "Creating executor service file..."
sudo tee /etc/systemd/system/executor.service > /dev/null <<EOF
[Unit]
Description=Executor Service
After=network.target

[Service]
User=root
WorkingDirectory=$(pwd)/executor/executor
Environment="NODE_ENV=testnet"
Environment="LOG_LEVEL=debug"
Environment="LOG_PRETTY=false"
Environment="PRIVATE_KEY_LOCAL=$PRIVATE_KEY_LOCAL"
Environment="ENABLED_NETWORKS=arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn"
ExecStart=$(pwd)/executor/executor/bin/executor
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Step 5: Reload and enable the service
    echo "Reloading systemd daemon and enabling executor service..."
    sudo systemctl daemon-reload
    sudo systemctl enable executor

    echo "Executor initialized successfully."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 2: Start Executor
start_executor() {
    echo "Starting executor service..."
    sudo systemctl start executor
    echo "Executor service started."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 3: View Logs
view_logs() {
    echo "Displaying executor logs... (Press Ctrl+C to exit logs)"
    sleep 2
    journalctl -u executor -f
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 4: Check Executor Status
check_status() {
    echo "Checking executor status..."
    sudo systemctl status executor
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 5: Stop Executor
stop_executor() {
    echo "Stopping executor service..."
    sudo systemctl stop executor
    echo "Executor service stopped."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 6: Restart Executor
restart_executor() {
    echo "Restarting executor service..."
    sudo systemctl restart executor
    echo "Executor service restarted."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 7: Update Executor
update_executor() {
    echo "Updating executor service..."
    sudo systemctl stop executor
    [ -d "executor" ] && rm -rf executor
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | jq -r .tag_name)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_VERSION/executor-linux-$LATEST_VERSION.tar.gz"
    EXECUTOR_FILE="executor-linux-$LATEST_VERSION.tar.gz"
    curl -L -o $EXECUTOR_FILE $EXECUTOR_URL
    tar -xzvf $EXECUTOR_FILE
    rm -f $EXECUTOR_FILE
    sudo systemctl start executor
    sudo systemctl status executor
    echo "Executor service updated."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 8: Delete Executor
delete_executor() {
    echo "Deleting executor service and files..."
    sudo systemctl stop executor
    sudo systemctl disable executor
    sudo rm /etc/systemd/system/executor.service
    sudo systemctl daemon-reload
    rm -rf executor
    sudo systemctl status executor
    echo "Executor service and files have been deleted."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Start the main menu
main_menu
