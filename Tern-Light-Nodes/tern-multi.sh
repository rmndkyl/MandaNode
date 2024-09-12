#!/bin/bash

LOG_FILE="/var/log/tern_executor.log"

log() {
    local level=$1
    local message=$2
    echo "$(date +'%Y-%m-%d %H:%M:%S') [$level] $message" >> $LOG_FILE
}

save_instance() {
    local instance_name=$1
    echo "$instance_name" >> /etc/tern_executor_instances
}

load_instances() {
    if [ -f /etc/tern_executor_instances ]; then
        cat /etc/tern_executor_instances
    else
        echo "No instances found."
    fi
}

start_executor() {
    load_instances
    read -p "Enter INSTANCE_NAME to start: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi
    log "INFO" "Starting Executor service for $INSTANCE_NAME..."
    sudo systemctl start $INSTANCE_NAME
    log "INFO" "Executor service started for $INSTANCE_NAME."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

view_logs() {
    load_instances
    read -p "Enter INSTANCE_NAME to view logs: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi
    log "INFO" "Displaying logs for $INSTANCE_NAME... (Press Ctrl+C to exit)"
    journalctl -u $INSTANCE_NAME -f
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

check_status() {
    load_instances
    read -p "Enter INSTANCE_NAME to check status: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi
    log "INFO" "Checking status for $INSTANCE_NAME..."
    sudo systemctl status $INSTANCE_NAME
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

stop_executor() {
    load_instances
    read -p "Enter INSTANCE_NAME to stop: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi
    log "INFO" "Stopping Executor service for $INSTANCE_NAME..."
    sudo systemctl stop $INSTANCE_NAME
    log "INFO" "Executor service stopped for $INSTANCE_NAME."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

restart_executor() {
    load_instances
    read -p "Enter INSTANCE_NAME to restart: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi
    log "INFO" "Restarting Executor service for $INSTANCE_NAME..."
    sudo systemctl restart $INSTANCE_NAME
    log "INFO" "Executor service restarted for $INSTANCE_NAME."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

delete_executor() {
    load_instances
    read -p "Enter INSTANCE_NAME to delete: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi
    log "INFO" "Deleting Executor service for $INSTANCE_NAME..."
    sudo systemctl stop $INSTANCE_NAME
    sudo systemctl disable $INSTANCE_NAME
    sudo rm /etc/systemd/system/$INSTANCE_NAME.service
    sudo systemctl daemon-reload
    rm -rf executor/$INSTANCE_NAME
    sed -i "/$INSTANCE_NAME/d" /etc/tern_executor_instances
    log "INFO" "Executor service deleted for $INSTANCE_NAME."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

update_executor() {
    load_instances
    read -p "Enter INSTANCE_NAME to update: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi
    log "INFO" "Updating Executor service for $INSTANCE_NAME..."
    sudo systemctl stop $INSTANCE_NAME
    rm -rf executor/$INSTANCE_NAME
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | jq -r .tag_name)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_VERSION/executor-linux-$LATEST_VERSION.tar.gz"
    wget -q $EXECUTOR_URL -O executor-linux-$LATEST_VERSION.tar.gz
    tar -xvf executor-linux-$LATEST_VERSION.tar.gz
    sudo systemctl start $INSTANCE_NAME
    log "INFO" "Executor service updated for $INSTANCE_NAME."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

view_key_address() {
    load_instances
    read -p "Enter INSTANCE_NAME to view private key and address: " INSTANCE_NAME
    if ! grep -q "$INSTANCE_NAME" /etc/tern_executor_instances; then
        log "ERROR" "Instance $INSTANCE_NAME does not exist."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi

    # Retrieve private key (assuming you saved it somewhere secure)
    PRIVATE_KEY_LOCAL=$(grep "$INSTANCE_NAME" /etc/tern_executor_instances | cut -d' ' -f2)
    if [ -z "$PRIVATE_KEY_LOCAL" ]; then
        log "ERROR" "Private key for $INSTANCE_NAME not found."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi

    # Ensure Node.js is installed
    if ! command -v node > /dev/null; then
        log "ERROR" "Node.js is not installed. Please run Option 1 to install it."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi

    mkdir -p temp_dir
    cd temp_dir || exit

    # Create the package.json file
    cat <<EOF > package.json
{
  "name": "temp_dir",
  "version": "1.0.0",
  "dependencies": {
    "ethers": "^6.5.0"
  }
}
EOF

    npm install

    # Create the Node.js script for deriving the address
    cat <<EOF > derive_address.js
const { ethers } = require('ethers');

const privateKey = process.argv[2];

if (privateKey.length !== 64) {
    console.error("Invalid private key length. It must be 64 characters long.");
    process.exit(1);
}

const wallet = new ethers.Wallet(\`0x\${privateKey}\`);
const address = wallet.address;

console.log(address);
EOF

    ADDRESS=$(node derive_address.js $PRIVATE_KEY_LOCAL)

    if [ -z "$ADDRESS" ]; then
        log "ERROR" "Failed to derive address from private key."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi

    echo "Private Key: $PRIVATE_KEY_LOCAL"
    echo "Address: $ADDRESS"

    cd ..
    rm -rf temp_dir

    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

download_and_initialize_executor() {
    read -p "Enter INSTANCE_NAME to initialize: " INSTANCE_NAME
    read -p "Enter PRIVATE_KEY for $INSTANCE_NAME: " PRIVATE_KEY

    # Validate private key length
    if [ ${#PRIVATE_KEY} -ne 64 ]; then
        log "ERROR" "Invalid private key length. It must be 64 characters long."
        read -n 1 -s -r -p "Press any key to continue..."
        main_menu
    fi

    # Create directories and fetch the latest executor release
    mkdir -p executor
    cd executor || exit
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | jq -r .tag_name)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_VERSION/executor-linux-$LATEST_VERSION.tar.gz"
    wget -q $EXECUTOR_URL -O executor-linux-$LATEST_VERSION.tar.gz
    tar -xvf executor-linux-$LATEST_VERSION.tar.gz
    rm executor-linux-$LATEST_VERSION.tar.gz

    # Create the service file
    SERVICE_FILE="/etc/systemd/system/$INSTANCE_NAME.service"
    cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Tern Executor Service for $INSTANCE_NAME
After=network.target

[Service]
ExecStart=/path/to/executor/executor --config /path/to/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # Create the config file with private key
    CONFIG_FILE="/path/to/config.json"
    mkdir -p /path/to/
    cat <<EOF | sudo tee $CONFIG_FILE
{
  "privateKey": "$PRIVATE_KEY",
  "instanceName": "$INSTANCE_NAME"
}
EOF

    # Reload systemd and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable $INSTANCE_NAME
    sudo systemctl start $INSTANCE_NAME

    # Save instance name
    save_instance "$INSTANCE_NAME"

    log "INFO" "Executor service for $INSTANCE_NAME has been initialized and started."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

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
    echo "1. Start Executor"
    echo "2. View Logs"
    echo "3. Check Status"
    echo "4. Stop Executor"
    echo "5. Restart Executor"
    echo "6. Delete Executor"
    echo "7. Update Executor"
    echo "8. View Private Key and Address"
    echo "9. Download and Initialize Executor (Input Private Key)"
    echo "10. Exit"
    read -p "Select an option: " option
    case $option in
        1) start_executor ;;
        2) view_logs ;;
        3) check_status ;;
        4) stop_executor ;;
        5) restart_executor ;;
        6) delete_executor ;;
        7) update_executor ;;
        8) view_key_address ;;
        9) download_and_initialize_executor ;;
        10) exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Ensure /etc/tern_executor_instances file exists
if [ ! -f /etc/tern_executor_instances ]; then
    touch /etc/tern_executor_instances
fi

main_menu
