#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/Dawn.sh"

# Check if the script is being run as the root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root privileges."
    echo "Please try using the 'sudo -i' command to switch to the root user, then run this script again."
    exit 1
fi

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check and install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is already installed."
    else
        echo "Node.js is not installed, installing..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed."
    else
        echo "npm is not installed, installing..."
        sudo apt-get install -y npm
    fi
}

# Check and install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed."
    else
        echo "PM2 is not installed, installing..."
        npm install pm2@latest -g
    fi
}

# Install Python package manager pip3
function install_pip() {
    if ! command -v pip3 > /dev/null 2>&1; then
        echo "pip3 is not installed, installing..."
        sudo apt-get install -y python3-pip
    else
        echo "pip3 is already installed."
    fi
}

# Install Python packages
function install_python_packages() {
    echo "Installing Python packages..."
    pip3 install pillow ddddocr requests loguru
}

# Function to install and start Dawn
function install_and_start_dawn() {
    # Update and install necessary software
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip lz4 snapd

    # Install Node.js, npm, PM2, pip3, and Python packages
    install_nodejs_and_npm
    install_pm2
    install_pip
    install_python_packages

    # Get username and password
    read -r -p "Please enter your email: " DAWNUSERNAME
    export DAWNUSERNAME=$DAWNUSERNAME
    read -r -p "Please enter your password: " DAWNPASSWORD
    export DAWNPASSWORD=$DAWNPASSWORD

    echo "$DAWNUSERNAME:$DAWNPASSWORD" > password.txt

    wget -O dawn.py https://raw.githubusercontent.com/b1n4he/DawnAuto/main/dawn.py

    # Start Dawn
    pm2 start python3 --name dawn -- dawn.py
}

# Function to view logs
function view_logs() {
    echo "Viewing Dawn logs..."
    pm2 log dawn
    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Function to stop and remove Dawn
function stop_and_remove_dawn() {
    if pm2 list | grep -q "dawn"; then
        echo "Stopping Dawn..."
        pm2 stop dawn
        echo "Removing Dawn..."
        pm2 delete dawn
    else
        echo "Dawn is not running."
    fi

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Main menu function
function main_menu() {
    while true; do
        clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Dawn Mining Installation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press Ctrl + C."
        echo "Please select an option:"
        echo "1) Install and start Dawn"
        echo "2) View logs"
        echo "3) Stop and remove Dawn"
        echo "4) Exit"

        read -p "Please enter your choice [1-4]: " choice

        case $choice in
            1)
                install_and_start_dawn
                ;;
            2)
                view_logs
                ;;
            3)
                stop_and_remove_dawn
                ;;
            4)
                echo "Exiting script..."
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
        esac
    done
}

# Run the main menu
main_menu
