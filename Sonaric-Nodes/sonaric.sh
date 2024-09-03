#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/sonaric.sh"

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root user privileges."
    echo "Please try switching to the root user using 'sudo -i' and then run this script again."
    exit 1
fi

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Main menu function
function main_menu() {
    while true; do
        clear
		echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
		echo "============================ Sonaric Node Installation ===================================="
		echo "Node community Telegram channel: https://t.me/layerairdrop"
		echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press ctrl + C."
        echo "Please select an operation:"
        echo "1) Start Node"
        echo "2) Register Node on Discord"
        echo "3) View Points"
        echo "4) Claim Points"
        echo "5) Backup Node"
        echo "6) Delete Node"
        echo "7) Exit"

        read -p "Enter your choice [1-7]: " choice

        case $choice in
            1)
                echo "Starting to update and upgrade system packages. This may take a few minutes..."
                sudo apt update -y && sudo apt upgrade -y

                echo "System package update and upgrade completed. Next, the installation script will be downloaded and executed, which may also take some time..."
                sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"

                echo "Press any key to check the node status. This may take 3-4 minutes..."
                read -n 1 -s -r

                sonaric node-info
                echo "Node status check completed. Please make sure you have confirmed the node is running on the latest version."
                ;;
            2)
                echo "Please enter your registration code:"
                read -p "Registration Code: " register_code

                echo "Registering node, please wait..."
                sonaric node-register "$register_code"

                echo "Registration completed. Press any key to return to the main menu..."
                read -n 1 -s -r
                ;;
            3)
                echo "Viewing points, please wait..."
                sonaric points

                echo "Points viewed successfully. Press any key to return to the main menu..."
                read -n 1 -s -r
                ;;
            4)
                echo "Please enter your signature information:"
                read -p "Signature Information: " sign_message

                echo "Claiming points, please wait..."
                sonaric sign "$sign_message"

                echo "Points claimed successfully. Press any key to return to the main menu..."
                read -n 1 -s -r
                ;;
            5)
                echo "Backing up node data, please wait..."

                # Backup node-related data
                sudo cp -r /var/lib/sonaricd ~/.sonaric_backup

                echo "Backup completed. Please keep the backup files safe, including node identity, database, configuration files, and logs."
                echo "Backup file path: ~/.sonaric_backup"
                echo "Press any key to return to the main menu..."
                read -n 1 -s -r
                ;;
            6)
                echo "Deleting node and related files, please wait..."
                
                # Uninstall and delete node-related files and processes
                sudo apt-get remove --purge -y sonaricd sonaric
                sudo pkill -f sonaric
                sudo rm -rf /usr/local/bin/sonaric
                sudo rm -rf /opt/sonaric
                sudo rm -rf ~/.sonaric

                echo "Node deleted successfully. Press any key to return to the main menu..."
                read -n 1 -s -r
                ;;
            7)
                echo "Exiting script."
                exit 0
                ;;
            *)
                echo "Invalid option, please enter a number between 1 and 7."
                ;;
        esac

        # Wait for the user to press any key to return to the main menu
        echo "Press any key to return to the main menu..."
        read -n 1 -s -r
    done
}

# Run the main menu function
main_menu
