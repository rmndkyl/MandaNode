#!/bin/bash

echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/chromium.sh"

# Check if the script is running as the root user
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Try switching to root user with 'sudo -i' and then rerun the script."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."

    # Update the system
    sudo apt update -y && sudo apt upgrade -y

    # Remove old versions
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg
    done

    # Install necessary packages
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker's source
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update again and install Docker
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Check Docker version
    docker --version
else
    echo "Docker is already installed, version: $(docker --version)"
fi

# Get relative path
relative_path=$(realpath --relative-to=/usr/share/zoneinfo /etc/localtime)
echo "Relative path is: $relative_path"

# Create chromium directory and navigate into it
mkdir -p $HOME/chromium
cd $HOME/chromium
echo "Entered chromium directory"

# Function to create docker-compose.yaml file and start container
function deploy_browser() {
    # Get user input
    read -p "Enter CUSTOM_USER: " CUSTOM_USER
    read -sp "Enter PASSWORD: " PASSWORD
    echo

    # Create docker-compose.yaml file
    cat <<EOF > docker-compose.yaml
---
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined # optional
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - CHROME_CLI=https://x.com/abdulbinjai32 # optional
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3010:3000   # Change 3010 to your preferred port if needed
      - 3011:3001   # Change 3011 to your preferred port if needed
    shm_size: "1gb"
    restart: unless-stopped
EOF

    echo "docker-compose.yaml file created and contents added."
    docker compose up -d
    echo "Docker Compose has started."
}

# Function to uninstall the node
function uninstall_docker() {
    echo "Stopping Docker..."
    # Stop Docker container
    cd /root/chromium
    docker compose down

    # Remove file directory
    rm -rf /root/chromium
    echo "Node has been uninstalled."
}

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "Once the browser is deployed, it can support projects like Dawn, Functor Node, Gradient, Node pay, etc."
        echo "================================================================"
        echo "To exit the script, press ctrl + C"
        echo "Select an action:"
        echo "1) Deploy Browser"
        echo "2) Uninstall Node"
        echo "3) Exit"
        
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                deploy_browser
                ;;
            2)
                uninstall_docker
                ;;
            3)
                echo "Exiting the script."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac

        read -p "Press any key to continue..."
    done
}

# Call the main menu
main_menu