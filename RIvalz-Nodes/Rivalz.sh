#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Install dependencies and RivalZ function
function install_all() {
    # Update package list and upgrade the system
    echo "Updating package list and upgrading the system..."
    sudo apt update && sudo apt upgrade -y

    # Remove existing Node.js and npm installations
    echo "Removing existing Node.js and npm installations..."
    sudo apt-get remove --purge -y nodejs npm
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y

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
            echo "$pkg installation failed, please check the error message."
            exit 1
        fi
    done

    # Install Node.js and npm
    echo "Installing Node.js and npm..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs

    # Verify if Node.js and npm are installed successfully
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        echo "Node.js and npm installed successfully!"
    else
        echo "Node.js or npm installation failed, please check the error message."
        exit 1
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
            echo "Rivalz installation failed, please check the error message."
            exit 1
        fi
    fi

    echo "Dependencies and Rivalz node installation completed."

    # Create a screen session and run Rivalz
    echo "Creating a screen session and running Rivalz..."
    screen -dmS rivalz bash -c "rivalz run; exec bash"

    # Prompt the user to enter the screen session and monitor the process
    echo "Rivalz is running in a screen session."
    echo "Please use the 'screen -r rivalz' command to enter the screen session. After completing the setup, press any key to return to the main menu..."
    read -n 1 -s
}

# Remove Rivalz
function remove_rivalz() {
    echo "Removing Rivalz..."
    
    # Check and remove the rivalz command
    if command -v rivalz &>/dev/null; then
        echo "Found Rivalz, removing..."
        sudo rm $(which rivalz)
        echo "Rivalz has been removed."
    else
        echo "Rivalz does not exist, cannot remove."
    fi

    # Remove the /root/.rivalz folder
    if [ -d /root/.rivalz ]; then
        echo "Found /root/.rivalz folder, removing..."
        sudo rm -rf /root/.rivalz
        echo "/root/.rivalz folder has been removed."
    else
        echo "/root/.rivalz folder does not exist."
    fi
}

# Remove /root/.nvm/versions/node/v20.0.0/bin/rivalz file
if [ -f /root/.nvm/versions/node/v20.0.0/bin/rivalz ]; then
    echo "Found /root/.nvm/versions/node/v20.0.0/bin/rivalz file, removing..."
    sudo rm /root/.nvm/versions/node/v20.0.0/bin/rivalz
    echo "/root/.nvm/versions/node/v20.0.0/bin/rivalz file has been removed."
else
    echo "/root/.nvm/versions/node/v20.0.0/bin/rivalz file does not exist."
fi

# Remove /root/.npm/rivalz-node-cli directory
if [ -d /root/.npm/rivalz-node-cli ]; then
    echo "Found /root/.npm/rivalz-node-cli directory, removing..."
    sudo rm -rf /root/.npm/rivalz-node-cli
    echo "/root/.npm/rivalz-node-cli directory has been removed."
else
    echo "/root/.npm/rivalz-node-cli directory does not exist."
fi
}

# Error fix and restart function
function fix_and_restart() {
    echo "Executing hardware configuration changes..."
    rivalz change-hardware-config
    echo "Please reconfigure the disk space, press any key to continue after completing..."
    read -n 1 -s

    echo "Executing wallet configuration changes..."
    rivalz change-wallet
    echo "Please reconfigure the wallet address, press any key to continue after completing..."
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
        echo "To exit the script, press Ctrl + C."
        echo "Please select the operation to perform:"
        echo "1) Install RivalZ node"
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

        # Add a prompt for the user to press any key to return to the main menu
        read -p "Operation completed, press any key to return to the main menu..."
    done
}

# Execute the main menu function
main_menu
