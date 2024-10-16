#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Install dependencies and RivalZ function
function install_all() {
    # Update package list and upgrade system
    echo "Updating package list and upgrading the system..."
    sudo apt update && sudo apt upgrade -y

    # Attempt to fix any broken packages
    echo "Fixing broken packages..."
    sudo apt --fix-broken install -y

    # Clean up any leftover package information
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

        # Verify Node.js and npm installation
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

    # Install Rivalz
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

    # Prompt the user to enter the screen session and monitor the process
    echo "Rivalz is running in a screen session."
    echo "Please use 'screen -r rivalz' to enter the screen session. After completing the setup, press any key to return to the main menu..."
    read -n 1 -s
}

# Remove Rivalz
function remove_rivalz() {
    echo "Removing Rivalz..."
    
    # Check and remove rivalz command
    if command -v rivalz &>/dev/null; then
        echo "Rivalz found, removing..."
        sudo rm $(which rivalz)
        echo "Rivalz removed."
    else
        echo "Rivalz does not exist, cannot remove."
    fi

    # Remove /root/.rivalz folder
    if [ -d /root/.rivalz ]; then
        echo "Found /root/.rivalz folder, removing..."
        sudo rm -rf /root/.rivalz
        echo "/root/.rivalz folder removed."
    else
        echo "/root/.rivalz folder does not exist."
    fi

    # Remove /usr/bin/rivalz folder
    if [ -d /usr/bin/rivalz ]; then
        echo "Found /usr/bin/rivalz folder, removing..."
        sudo rm -rf /usr/bin/rivalz
        echo "/usr/bin/rivalz folder removed."
    else
        echo "/usr/bin/rivalz folder does not exist."
    fi

    # Remove /root/.npm/rivalz-node-cli directory
    if [ -d /root/.npm/rivalz-node-cli ]; then
        echo "Found /root/.npm/rivalz-node-cli directory, removing..."
        sudo rm -rf /root/.npm/rivalz-node-cli
        echo "/root/.npm/rivalz-node-cli directory removed."
    else
        echo "/root/.npm/rivalz-node-cli directory does not exist."
    fi
    
    # Remove /root/.nvm/versions/node/v20.0.0/bin/rivalz file
    if [ -f /root/.nvm/versions/node/v20.0.0/bin/rivalz ]; then
        echo "Found /root/.nvm/versions/node/v20.0.0/bin/rivalz file, removing..."
        sudo rm /root/.nvm/versions/node/v20.0.0/bin/rivalz
        echo "/root/.nvm/versions/node/v20.0.0/bin/rivalz file removed."
    else
        echo "/root/.nvm/versions/node/v20.0.0/bin/rivalz file does not exist."
    fi

    # Remove /usr/lib/node_modules/rivalz-node-cli
    if [ -d /usr/lib/node_modules/rivalz-node-cli ]; then
        echo "Found /usr/lib/node_modules/rivalz-node-cli, removing..."
        sudo rm -rf /usr/lib/node_modules/rivalz-node-cli
        echo "/usr/lib/node_modules/rivalz-node-cli removed."
    else
        echo "/usr/lib/node_modules/rivalz-node-cli does not exist."
    fi
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
            *)
                echo "Invalid option, please try again."
                ;;
        esac

        # Prompt the user to press any key to return to the main menu
        read -p "Operation completed, press any key to return to the main menu..."
    done
}

# Execute the main menu function
main_menu
