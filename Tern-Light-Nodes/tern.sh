#!/bin/bash

log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    log "ERROR" "This script needs to be run with root user privileges."
    log "INFO" "Please try switching to the root user using 'sudo -i' and then run this script again."
    exit 1
fi

# Function to display the main menu
main_menu() {
    clear
    echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░"
    echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗"
    echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝"
    echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗"
    echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║"
    echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝"
    echo "==================== Tern Light Node (Executor) Menu ===================="
    echo "1. Download and Initialize Tern Executor (Input Private Key)"
    echo "2. Start Executor"
    echo "3. View Logs"
    echo "4. Check Executor Status"
    echo "5. Stop Executor"
    echo "6. Restart Executor"
    echo "7. Update Executor"
    echo "8. Delete Executor"
    echo "9. View Private Key, BRN Balance, and Address"
    echo "10. Exit"
    echo "================================================================="
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
        9) view_key_balance_address ;;
        10) exit 0 ;;
        *) log "ERROR" "Invalid choice. Please choose again." && read -n 1 -s -r -p "Press any key to continue..." && main_menu ;;
    esac
}

# Option 1: Download and Initialize Tern Executor (with Private Key input)
download_initialize_executor() {
    remove_old_service

    read -p "Enter your PRIVATE_KEY_LOCAL (without 0x prefix): " PRIVATE_KEY_LOCAL
    if [ ${#PRIVATE_KEY_LOCAL} -ne 64 ]; then
        log "ERROR" "Invalid private key. It must be 64 characters long."
        exit 1
    fi

    export PRIVATE_KEY_LOCAL
    log "INFO" "Private key stored successfully."

    update_system

    # Retrieve latest version dynamically
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_VERSION/executor-linux-$LATEST_VERSION.tar.gz"

    log "INFO" "Downloading Executor version $LATEST_VERSION..."
    wget -q $EXECUTOR_URL -O executor-linux-$LATEST_VERSION.tar.gz
    tar -xvf executor-linux-$LATEST_VERSION.tar.gz

    create_systemd_service
    log "INFO" "Executor initialized successfully."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Remove old service
remove_old_service() {
    log "INFO" "Stopping and removing old Executor service..."
    sudo systemctl stop executor.service 2>/dev/null
    sudo systemctl disable executor.service 2>/dev/null
    sudo rm -f /etc/systemd/system/executor.service
    sudo systemctl daemon-reload
    log "INFO" "Old service has been removed."
}

# Update the system
update_system() {
    log "INFO" "Updating and upgrading system packages..."
    sudo apt update -q && sudo apt upgrade -qy
    if [ $? -ne 0 ]; then
        log "ERROR" "System update failed. Exiting."
        exit 1
    fi
}

# Create systemd service file
create_systemd_service() {
    log "INFO" "Creating systemd service file..."
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
    sudo systemctl daemon-reload
    sudo systemctl enable executor
}

# Option 2: Start Executor
start_executor() {
    log "INFO" "Starting Executor service..."
    sudo systemctl start executor
    log "INFO" "Executor service started."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 3: View Logs
view_logs() {
    log "INFO" "Displaying executor logs... (Press Ctrl+C to exit)"
    journalctl -u executor -f
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 4: Check Executor Status
check_status() {
    log "INFO" "Checking Executor status..."
    sudo systemctl status executor
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 5: Stop Executor
stop_executor() {
    log "INFO" "Stopping Executor service..."
    sudo systemctl stop executor
    log "INFO" "Executor service stopped."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 6: Restart Executor
restart_executor() {
    log "INFO" "Restarting Executor service..."
    sudo systemctl restart executor
    log "INFO" "Executor service restarted."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 7: Update Executor
update_executor() {
    log "INFO" "Updating Executor service..."
    sudo systemctl stop executor
    rm -rf executor
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | jq -r .tag_name)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_VERSION/executor-linux-$LATEST_VERSION.tar.gz"
    wget -q $EXECUTOR_URL -O executor-linux-$LATEST_VERSION.tar.gz
    tar -xvf executor-linux-$LATEST_VERSION.tar.gz
    sudo systemctl start executor
    log "INFO" "Executor service updated."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 8: Delete Executor
delete_executor() {
    log "INFO" "Deleting Executor service..."
    sudo systemctl stop executor
    sudo systemctl disable executor
    sudo rm /etc/systemd/system/executor.service
    sudo systemctl daemon-reload
    rm -rf executor
    log "INFO" "Executor service deleted."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 9: View Private Key, BRN Balance, and Address
view_key_balance_address() {
    if [ -z "$PRIVATE_KEY_LOCAL" ]; then
        log "ERROR" "Private key not found. Please initialize the Executor first."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi

    # Convert private key to address
    ADDRESS=$(curl -s -X POST -H "Content-Type: application/json" --data "{\"method\":\"eth_accounts\",\"params\":[],\"id\":1,\"jsonrpc\":\"2.0\"}" http://localhost:8545 | jq -r .result[0])

    if [ -z "$ADDRESS" ]; then
        log "ERROR" "Failed to fetch address from private key."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi

    # Fetch BRN balance using pricer API
    BALANCE=$(curl -s "https://pricer.t1rn.io/user/brn/balance?account=$ADDRESS" | jq -r '.balance')

    echo "Private Key: $PRIVATE_KEY_LOCAL"
    echo "Address: $ADDRESS"
    echo "BRN Balance: $BALANCE"

    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Start the main menu
main_menu
