#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try using the 'sudo -i' command to switch to the root user, and then run this script again."
    exit 1
fi

# Node installation function
function install_node() {

# Update system package list
sudo apt update
apt install screen -y

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    # If Docker is not installed, install it
    echo "Docker not detected, installing..."
    sudo apt-get install ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Authorize Docker files
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update

    # Install the latest version of Docker
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
else
    echo "Docker is already installed."
fi

# Get the running file
read -p "Please enter your key device id: " your_device_id

keyid="$your_device_id"

# Download the PINGPONG program
wget -O PINGPONG https://pingpong-build.s3.ap-southeast-1.amazonaws.com/linux/latest/PINGPONG

if [ -f "./PINGPONG" ]; then
    chmod +x ./PINGPONG
    screen -dmS pingpong bash -c "./PINGPONG --key \"$keyid\""
else
    echo "Failed to download PINGPONG, please check your network connection or the URL."
fi

 echo "The node has started, use screen -r pingpong to view logs or use script function 2"

}

function check_service_status() {
    screen -r pingpong
}

function reboot_pingpong() {
    read -p "Please enter your key device id: " your_device_id
    keyid="$your_device_id"
    screen -dmS pingpong bash -c "./PINGPONG --key \"$keyid\""
}

function start_0g_pingpong() {
    read -p "Please enter your 0g private key: " your_0g_key
    keyid="$your_0g_key"
    screen -dmS pingpong-0g bash -c "./PINGPONG config set --0g=$your_0g_key && ./PINGPONG start --depins=0g"
}

function start_aioz() {
    read -p "Please enter your aioz private key: " your_aioz_key
    keyid="$your_aioz_key"
    screen -dmS pingpong-aioz bash -c "./PINGPONG config set --aioz=$your_aioz_key && ./PINGPONG start --depins=aioz"
}

function start_grass() {
    read -p "Please enter your grass private key: " your_grass_key
    keyid="$your_grass_key"
    screen -dmS pingpong-grass bash -c "./PINGPONG config set --grass=$your_grass_key && ./PINGPONG start --depins=grass"
}

# Main menu
function main_menu() {
    clear
    echo "Script and tutorial written by Twitter user @y95277777, free and open source, do not believe in paid versions"
    echo "================================================================"
    echo "Node community Telegram group: https://t.me/niuwuriji"
    echo "Node community Telegram channel: https://t.me/niuwuriji"
    echo "Node community Discord group: https://discord.gg/GbMV5EcNWF"
    echo "Please choose the operation you want to perform:"
    echo "1. Install node"
    echo "2. View node logs"
    echo "3. Restart pingpong"
    echo "4. Start pingpong-0g (requires private key)"
    echo "5. Start pingpong-aioz (requires private key)"
    echo "6. Start pingpong-grass (requires private key)"
    read -p "Please enter an option (1-6): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) reboot_pingpong ;; 
    4) start_0g_pingpong ;; 
    5) start_aioz ;; 
    6) start_grass ;; 
    *) echo "Invalid option." ;;
    esac
}

# Display the main menu
main_menu