#!/bin/bash

# Exit on any error
set -e

# Define log file
LOGFILE="rivalz_installation.log"
exec > >(tee -i $LOGFILE) 2>&1

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Trap to handle unexpected exits
trap 'echo "Exiting script due to an error." ; exit 1' ERR

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh

# Verify downloaded files' checksums (Optional: replace with actual checksum)
# echo "expected-checksum  loader.sh" | sha256sum -c -
# echo "expected-checksum  logo.sh" | sha256sum -c -

./loader.sh
./logo.sh
sleep 2

rm -rf loader.sh
rm -rf logo.sh

# Install dependencies and RivalZ function
function install_all() {
    echo "Updating package list and upgrading the system..."
    sudo apt update && sudo apt upgrade -y || { echo "Failed to update system"; exit 1; }

    echo "Fixing broken packages..."
    sudo apt --fix-broken install -y

    echo "Cleaning up package cache..."
    sudo apt clean

    # Install Git, curl, and screen
    for pkg in git curl screen; do
        echo "Installing $pkg..."
        sudo apt install -y $pkg
        if command -v $pkg &>/dev/null; then
            echo "$pkg installed successfully!"
        else
            echo "Failed to install $pkg, please check the error message."
            exit 1
        fi
    done

    # Install Node.js and npm
    if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
        echo "Node.js and npm are not installed, installing..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs

        if command -v node &>/dev/null && command -v npm &>/dev/null; then
            echo "Node.js and npm installed successfully!"
        else
            echo "Failed to install Node.js or npm, please check the error message."
            exit 1
        fi
    else
        echo "Node.js and npm are already installed. Version:"
        node -v
        npm -v
    fi

    echo "Installing Rivalz..."
    if npm list -g rivalz-node-cli &>/dev/null; then
        echo "Rivalz is already installed."
    else
        npm i -g rivalz-node-cli
        if npm list -g rivalz-node-cli &>/dev/null; then
            echo "Rivalz installed successfully!"
        else
            echo "Failed to install Rivalz, please check the error message."
            exit 1
        fi
    fi

    echo "Dependencies and Rivalz node installation completed."

    # Create screen session and run Rivalz
    echo "Creating screen session and running Rivalz..."
    screen -dmS rivalz bash -c "rivalz run; exec bash"
    echo "Rivalz is running in a screen session."
    echo "Please use 'screen -r rivalz' to enter the session. Press any key to return to the main menu..."
    read -n 1 -s
}

# Remove Rivalz
function remove_rivalz() {
    echo "Removing Rivalz..."

    paths_to_remove=(
        "/root/.rivalz"
        "/usr/bin/rivalz"
        "/root/.npm/rivalz-node-cli"
        "/root/.nvm/versions/node/v20.0.0/bin/rivalz"
        "/usr/lib/node_modules/rivalz-node-cli"
    )

    for path in "${paths_to_remove[@]}"; do
        if [[ -e $path ]]; then
            echo "Removing $path..."
            sudo rm -rf "$path"
            echo "$path removed."
        else
            echo "$path does not exist, skipping..."
        fi
    done
}

# Fix errors and restart
function fix_and_restart() {
    echo "Executing hardware configuration changes..."
    rivalz change-hardware-config
    echo "Please reconfigure the hard disk size, then press any key to continue..."
    read -n 1 -s

    echo "Executing wallet configuration changes..."
    rivalz change-wallet
    echo "Please reconfigure the wallet address, then press any key to continue..."
    read -n 1 -s

    echo "Running Rivalz..."
    rivalz run
    echo "Operation completed."
}

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
        echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
        echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
        echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
        echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
        echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
        echo "============================ Rivalz Light Node Installation ===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press Ctrl + C on your keyboard."
        echo "Please select the operation you want to perform:"
        echo "1) Install RivalZ Node"
        echo "2) Remove Rivalz"
        echo "3) Fix errors and restart (Please open a new screen session)"
        echo "0) Exit"
        
        read -p "Enter your choice (0-3): " choice
        if [[ ! "$choice" =~ ^[0-3]$ ]]; then
            echo "Invalid option, please enter a number from 0 to 3."
            continue
        fi

        case $choice in
            1)
                install_all
                ;;
            2)
                remove_rivalz
                ;;
            3)
                fix_and_restart
                ;;
            0)
                echo "Exiting script..."
                exit 0
                ;;
        esac

        read -p "Operation completed, press any key to return to the main menu..."
    done
}

# Execute the main menu function
main_menu
