#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

logo=$(cat << 'EOF'
\033[32m

██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░
██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝
██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░
███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░
╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░ 
\033[0m
The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version
Node community Telegram channel: https://t.me/layerairdrop
Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1
EOF
)

echo -e "$logo"

# Check if curl is installed, and install if not
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Check if bc is installed, and install if not
echo -e "${BLUE}Checking your OS version...${NC}"
if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi
sleep 1

# Check Ubuntu version
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

echo -e "${YELLOW}Enter the number:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Installing BlockMesh node...${NC}"

        # Check if tar is installed, and install if not
        if ! command -v tar &> /dev/null; then
            sudo apt install tar -y
        fi
        sleep 1
        
        # Download the BlockMesh binary
        wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.307/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Extract the archive
        tar -xzvf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        sleep 1

        # Remove the archive
        rm blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Navigate to the node folder
        cd target/release

        # Request user data
        echo -e "${YELLOW}Enter your email:${NC}"
        read USER_EMAIL

        echo -e "${YELLOW}Enter your password:${NC}"
        read USER_PASSWORD

        # Determine current user's name and home directory
        USERNAME=$(whoami)

        if [ "$USERNAME" == "root" ]; then
            HOME_DIR="/root"
        else
            HOME_DIR="/home/$USERNAME"
        fi

        # Create or update the service file using the specified username and home directory
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

        # Final message
        echo -e "${GREEN}Installation completed and the node has been started!${NC}"

        # Check logs
        sudo journalctl -u blockmesh -f
        ;;

    2)
        # Check logs
        sudo journalctl -u blockmesh -f
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
esac
