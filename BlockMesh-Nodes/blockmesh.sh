#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logo and message
logo=$(cat << 'EOF'
\033[32m
██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░
██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝
██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░
███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░
╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░  
\033[0m
EOF
)

message="\nThe script and tutorial were written by Telegram user @rmndkyl, free and open source. Please do not believe in the paid version.\n
Node community Telegram channel: https://t.me/layerairdrop\n
Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1\n"

echo -e "$logo"
echo -e "$message"

# Install required packages if not installed
for pkg in curl bc tar; do
    if ! command -v $pkg &> /dev/null; then
        sudo apt update
        sudo apt install -y $pkg
    fi
done
sleep 1

# Check Ubuntu version
echo -e "${BLUE}Checking your OS version...${NC}"
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}This node requires at least Ubuntu version 22.04${NC}"
    exit 1
fi

# Menu
echo -e "${YELLOW}Select an option:${NC}"
echo -e "${CYAN}1) Install the node${NC}"
echo -e "${CYAN}2) Check logs (exit logs with CTRL+C)${NC}"
echo -e "${CYAN}3) Remove the node${NC}"
echo -e "${CYAN}4) Exit${NC}"

echo -e "${YELLOW}Enter the number:${NC} "
read choice

case $choice in
    1)
        # Check if already installed and running
        if systemctl is-active --quiet blockmesh; then
            echo -e "${YELLOW}BlockMesh node is already installed and running. Do you want to reinstall? (y/n):${NC}"
            read reinstall
            if [ "$reinstall" != "y" ]; then
                echo -e "${GREEN}Installation skipped.${NC}"
                exit 0
            fi
        fi

        echo -e "${BLUE}Installing BlockMesh node...${NC}"

        # Download and extract the BlockMesh binary
        mkdir -p target/release
        wget -qO- https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.307/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C target/release
        sleep 1

        # Request user data with validation and secure password handling
        echo -e "${YELLOW}Enter your email:${NC}"
        read USER_EMAIL
        while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
            echo -e "${RED}Invalid email format. Please enter a valid email:${NC}"
            read USER_EMAIL
        done

        echo -e "${YELLOW}Enter your password:${NC}"
        read -s USER_PASSWORD
        echo -e "${YELLOW}Confirm your password:${NC}"
        read -s CONFIRM_PASSWORD
        while [ "$USER_PASSWORD" != "$CONFIRM_PASSWORD" ]; do
            echo -e "${RED}Passwords do not match. Please re-enter your password:${NC}"
            read -s USER_PASSWORD
            echo -e "${YELLOW}Confirm your password:${NC}"
            read -s CONFIRM_PASSWORD
        done

        # Determine current user's name and home directory
        USERNAME=$(whoami)
        if [ "$USERNAME" == "root" ]; then
            HOME_DIR="/root"
        else
            HOME_DIR="/home/$USERNAME"
        fi

        # Create or update the service file
        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/release/blockmesh-cli login --email $USER_EMAIL --password $USER_PASSWORD
WorkingDirectory=$HOME_DIR/target/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Reload services and enable BlockMesh
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable blockmesh
        sudo systemctl start blockmesh

        # Final message and log instructions
        echo -e "${GREEN}Installation completed and the node has been started! To stop viewing logs, press CTRL+C.${NC}"
        sudo journalctl -u blockmesh -f -n 50
        ;;

    2)
        # Check logs with instructions on how to exit
        echo -e "${YELLOW}Press CTRL+C to exit the log view.${NC}"
        sudo journalctl -u blockmesh -f -n 50
        ;;

    3)
        echo -e "${BLUE}Removing BlockMesh node...${NC}"

        # Stop and disable the service
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 1

        # Remove target folder with files
        rm -rf target

        echo -e "${GREEN}BlockMesh node successfully removed!${NC}"
        ;;

    4)
        echo -e "${YELLOW}Exiting the script...${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid option. Exiting.${NC}"
        exit 1
        ;;
esac
