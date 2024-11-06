#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No color

# Script save path
SCRIPT_PATH="$HOME/sonaric.sh"
LOG_FILE="$HOME/sonaric_install_log.txt"

# Log script start
echo "Starting script at $(date)" >> "$LOG_FILE"

# Check for dependencies
command -v wget >/dev/null 2>&1 || { echo -e "${RED}wget is required but not installed. Exiting.${NC}" >> "$LOG_FILE"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo -e "${RED}curl is required but not installed. Exiting.${NC}" >> "$LOG_FILE"; exit 1; }

# Showing Animation
echo -e "${BLUE}Showing Animation..${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh || { echo -e "${RED}Failed to download loader.sh${NC}" >> "$LOG_FILE"; exit 1; }
chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh || { echo -e "${RED}Failed to execute loader.sh${NC}" >> "$LOG_FILE"; exit 1; }
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh || { echo -e "${RED}Failed to download logo.sh${NC}" >> "$LOG_FILE"; exit 1; }
chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh || { echo -e "${RED}Failed to execute logo.sh${NC}" >> "$LOG_FILE"; exit 1; }
sleep 4

rm -rf loader.sh
rm -rf logo.sh

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script needs to be run with root user privileges.${NC}"
    echo -e "Please try switching to the root user using 'sudo -i' and then run this script again." >> "$LOG_FILE"
    exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        echo -e "${BLUE}Script and tutorial written by Telegram user @rmndkyl, free and open source.${NC}"
	echo -e "${BLUE}============================ Sonaric Node Installation ====================================${NC}"
        echo -e "${YELLOW}Node community Telegram channel: https://t.me/layerairdrop${NC}"
        echo -e "${YELLOW}Node community Telegram group: https://t.me/layerairdropdiskusi${NC}"
        echo -e "${GREEN}To exit the script, press ctrl + C.${NC}"
        echo -e "${BLUE}Please select an operation:${NC}"
        echo -e "1) Start Node"
        echo -e "2) Register Node on Discord"
        echo -e "3) View Points"
        echo -e "4) Claim Points"
        echo -e "5) Backup Node"
        echo -e "6) Delete Node"
        echo -e "7) Exit"

        read -p "Enter your choice [1-7]: " choice

        case $choice in
            1)
                echo -e "${YELLOW}Starting to update and upgrade system packages. This may take a few minutes...${NC}"
                sudo apt update -y && sudo apt upgrade -y || { echo -e "${RED}Failed to update system packages.${NC}" >> "$LOG_FILE"; exit 1; }

                echo -e "${YELLOW}System package update and upgrade completed. Next, the installation script will be downloaded and executed.${NC}"
                sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)" || { echo -e "${RED}Failed to run the install script.${NC}" >> "$LOG_FILE"; exit 1; }

                echo -e "${GREEN}Press any key to check the node status. This may take 3-4 minutes...${NC}"
                read -n 1 -s -r

                sonaric node-info || { echo -e "${RED}Failed to check node status.${NC}" >> "$LOG_FILE"; exit 1; }
                echo -e "${GREEN}Node status check completed.${NC}"
                ;;
            2)
                echo -e "${YELLOW}Please enter your registration code:${NC}"
                read -p "Registration Code: " register_code

                # Validate registration code
                if [[ ! "$register_code" =~ ^[A-Za-z0-9]+$ ]]; then
                    echo -e "${RED}Invalid registration code. Only alphanumeric characters are allowed.${NC}"
                    return
                fi

                echo -e "${YELLOW}Registering node, please wait...${NC}"
                sonaric node-register "$register_code" || { echo -e "${RED}Failed to register node.${NC}" >> "$LOG_FILE"; exit 1; }

                echo -e "${GREEN}Registration completed. Press any key to return to the main menu...${NC}"
                read -n 1 -s -r
                ;;
            3)
                echo -e "${YELLOW}Viewing points, please wait...${NC}"
                sonaric points || { echo -e "${RED}Failed to view points.${NC}" >> "$LOG_FILE"; exit 1; }

                echo -e "${GREEN}Points viewed successfully. Press any key to return to the main menu...${NC}"
                read -n 1 -s -r
                ;;
            4)
                echo -e "${YELLOW}Please enter your signature information:${NC}"
                read -p "Signature Information: " sign_message

                echo -e "${YELLOW}Claiming points, please wait...${NC}"
                sonaric sign "$sign_message" || { echo -e "${RED}Failed to claim points.${NC}" >> "$LOG_FILE"; exit 1; }

                echo -e "${GREEN}Points claimed successfully. Press any key to return to the main menu...${NC}"
                read -n 1 -s -r
                ;;
            5)
                echo -e "${YELLOW}Backing up node data, please wait...${NC}"

                # Backup node-related data
                sudo cp -r /var/lib/sonaricd ~/.sonaric_backup || { echo -e "${RED}Backup failed.${NC}" >> "$LOG_FILE"; exit 1; }

                echo -e "${GREEN}Backup completed. Please keep the backup files safe.${NC}"
                echo -e "Backup file path: ~/.sonaric_backup"
                echo -e "${GREEN}Press any key to return to the main menu...${NC}"
                read -n 1 -s -r
                ;;
            6)
                echo -e "${YELLOW}Deleting node and related files, please wait...${NC}"
                
                # Uninstall and delete node-related files and processes
                sudo apt-get remove --purge -y sonaricd sonaric || { echo -e "${RED}Failed to remove sonaricd package.${NC}" >> "$LOG_FILE"; exit 1; }
                sudo pkill -f sonaric
                sudo rm -rf /usr/local/bin/sonaric
                sudo rm -rf /opt/sonaric
                sudo rm -rf ~/.sonaric

                echo -e "${GREEN}Node deleted successfully. Press any key to return to the main menu...${NC}"
                read -n 1 -s -r
                ;;
            7)
                echo -e "${GREEN}Exiting script.${NC}"
                echo -e "Script exited at $(date)" >> "$LOG_FILE"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option, please enter a number between 1 and 7.${NC}"
                ;;
        esac

        # Wait for the user to press any key to return to the main menu
        echo -e "${GREEN}Press any key to return to the main menu...${NC}"
        read -n 1 -s -r
    done
}

# Run the main menu function
main_menu
