#!/bin/bash

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root user privileges."
    echo "Please try switching to the root user using 'sudo -i' and then run this script again."
    exit 1
fi

#Showing Logo from Our Group
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && ./logo.sh
sleep 4

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
    echo "1. Input Private Key (Make sure funds available)"
    echo "2. Download and Initialize Tern Executor"
    echo "3. Start Executor"
    echo "4. View Logs"
    echo "5. Check Executor Status"
    echo "6. Stop Executor"
    echo "7. Restart Executor"
    echo "8. Update Executor"
    echo "9. Exit"
    echo "============================================================================================="
    read -p "Please choose an option: " choice
    case $choice in
        1) input_private_key ;;
        2) download_initialize_executor ;;
        3) start_executor ;;
        4) view_logs ;;
        5) check_status ;;
        6) stop_executor ;;
        7) restart_executor ;;
        8) update_executor ;;
        9) exit 0 ;;
        *) echo "Invalid choice. Please choose again." && read -n 1 -s -r -p "Press any key to continue..." && main_menu ;;
    esac
}

# Option 1: Input Private Key
input_private_key() {
    read -p "Enter your PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL
    echo "Private key stored successfully."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 2: Download and Initialize Tern Executor
download_initialize_executor() {
    echo "Updating package list and installing dependencies..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl wget tar build-essential jq unzip -y

    echo "Downloading executor..."
    wget https://github.com/t3rn/executor-release/releases/download/v0.20.0/executor-linux-v0.20.0.tar.gz
    tar -xvf executor-linux-v0.20.0.tar.gz
    echo "Executor initialized."
	
	# Create a systemd service file
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
	Environment="ENABLED_NETWORKS=arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn"
	ExecStart=$(pwd)/executor/executor/bin/executor
	Restart=always
	RestartSec=3

	[Install]
	WantedBy=multi-user.target
EOF
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 3: Start Executor
start_executor() {
    echo "Starting executor service..."
    sudo systemctl start executor
    echo "Executor service started."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 4: View Logs
view_logs() {
    echo "Displaying executor logs..."
    journalctl -u executor -f
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 5: Check Executor Status
check_status() {
    echo "Checking executor status..."
    sudo systemctl status executor
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 6: Stop Executor
stop_executor() {
    echo "Stopping executor service..."
    sudo systemctl stop executor
    echo "Executor service stopped."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 7: Restart Executor
restart_executor() {
    echo "Restarting executor service..."
    sudo systemctl restart executor
    echo "Executor service restarted."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Option 8: Update Executor
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
    rm -rf $(pwd)/executor
    sudo systemctl start executor
    sudo systemctl status executor
    echo "Executor service updated."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Start the main menu
main_menu
