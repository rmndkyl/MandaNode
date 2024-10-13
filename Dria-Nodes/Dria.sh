#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Define text formats
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
SUCCESS_COLOR='\033[1;32m'
WARNING_COLOR='\033[1;33m'
ERROR_COLOR='\033[1;31m'
INFO_COLOR='\033[1;36m'
MENU_COLOR='\033[1;34m'

# Custom status display function
display_status() {
    local message="$1"
    local status="$2"
    case $status in
        "error")
            echo -e "${ERROR_COLOR}${BOLD}❌ Error: ${message}${NORMAL}"
            ;;
        "warning")
            echo -e "${WARNING_COLOR}${BOLD}⚠️ Warning: ${message}${NORMAL}"
            ;;
        "success")
            echo -e "${SUCCESS_COLOR}${BOLD}✅ Success: ${message}${NORMAL}"
            ;;
        "info")
            echo -e "${INFO_COLOR}${BOLD}ℹ️ Info: ${message}${NORMAL}"
            ;;
        *)
            echo -e "${message}"
            ;;
    esac
}

# Ensure the script is run as root user
if [[ $EUID -ne 0 ]]; then
    display_status "Please run this script with root privileges." "error"
    exit 1
fi

# Step 1: Update the system and install dependencies
setup_prerequisites() {
    display_status "Checking and installing required system dependencies..." "info"
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get dist-upgrade -y
    sudo apt autoremove -y

    local dependencies=("curl" "ca-certificates" "gnupg" "wget" "unzip")
    for package in "${dependencies[@]}"; do
        if ! dpkg -l | grep -q "^ii\s\+$package"; then
            display_status "Installing $package..." "info"
            sudo apt install -y $package
        else
            display_status "$package is already installed, skipping." "success"
        fi
    done
}

# Install Docker environment
install_docker() {
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        display_status "Docker detected as installed, skipping installation step." "success"
        docker --version  # Display the installed Docker version
        return
    fi

    # If Docker is not installed, perform the following installation steps
    display_status "Installing Docker..." "info"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg
    done

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    docker --version && display_status "Docker installed successfully." "success" || display_status "Docker installation failed." "error"
}

# Install Ollama
install_ollama() {
    display_status "Installing Ollama..." "info"
    curl -fsSL https://ollama.com/install.sh | sh && display_status "Ollama installed successfully." "success" || display_status "Ollama installation failed." "error"
}

# Download and install Dria node
install_dria_node() {
    display_status "Downloading and installing Dria node..." "info"
    cd $HOME

    # Check if the file already exists, if so, delete it to avoid duplicate downloads
    if [[ -f "dkn-compute-node.zip" ]]; then
        display_status "Found existing Dria node zip file, deleting to avoid duplicate download..." "info"
        rm -f dkn-compute-node.zip
    fi

    # Download Dria node files
    wget -q https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip -O dkn-compute-node.zip
    
    # Check if the extraction directory exists, if so, delete it to avoid duplicate installations
    if [[ -d "dkn-compute-node" ]]; then
        display_status "Found existing Dria node directory, deleting to avoid duplicate installation..." "info"
        rm -rf dkn-compute-node
    fi

    # Unzip the file
    unzip dkn-compute-node.zip || { display_status "File extraction failed, please check the error and try again." "error"; return; }
    display_status "Dria node installation completed." "success"
}

# Run Dria node
run_dria_node() {
    display_status "Starting Dria node..." "info"
    cd $HOME/dkn-compute-node
    ./dkn-compute-launcher || { display_status "Dria node startup failed, please check the error and try again." "error"; return; }
    display_status "Dria node started successfully." "success"
}

# Main menu functionality
main_menu() {
    while true; do
        clear
	echo -e "${MENU_COLOR}The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version${NORMAL}"
        echo -e "${MENU_COLOR}${BOLD}============================ Dria Node Management Tool ============================${NORMAL}"
	echo -e "${MENU_COLOR}Node community Telegram channel: https://t.me/layerairdrop${NORMAL}"
        echo -e "${MENU_COLOR}Node community Telegram group: https://t.me/layerairdropdiskusi${NORMAL}"
        echo -e "${MENU_COLOR}Please select an action:${NORMAL}"
        echo -e "${MENU_COLOR}1. Update system and install dependencies${NORMAL}"
        echo -e "${MENU_COLOR}2. Install Docker environment${NORMAL}"
        echo -e "${MENU_COLOR}3. Install Ollama${NORMAL}"
        echo -e "${MENU_COLOR}4. Download and install Dria node${NORMAL}"
        echo -e "${MENU_COLOR}5. Run Dria node${NORMAL}"
        echo -e "${MENU_COLOR}6. Exit${NORMAL}"
        read -p "Please enter an option (1-6): " OPTION

        case $OPTION in
            1) setup_prerequisites ;;
            2) install_docker ;;
            3) install_ollama ;;
            4) install_dria_node ;;
            5) run_dria_node ;;
            6) exit 0 ;;
            *) display_status "Invalid option, please try again." "error" ;;
        esac
        read -n 1 -s -r -p "Press any key to return to the main menu..."
    done
}

# Start the main menu
main_menu
