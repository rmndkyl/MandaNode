#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 2

# Define text formats
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
SUCCESS_COLOR='\033[1;32m'
WARNING_COLOR='\033[1;33m'
ERROR_COLOR='\033[1;31m'
INFO_COLOR='\033[1;36m'
MENU_COLOR='\033[1;34m'
LOG_FILE="$HOME/dria_node_install.log"

# Log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Custom status display function
display_status() {
    local message="$1"
    local status="$2"
    log_message "$message"
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

# Check for compatible OS and architecture
check_os_architecture() {
    if [[ "$(uname -s)" != "Linux" ]] || [[ "$(uname -m)" != "x86_64" ]]; then
        display_status "This script is designed for 64-bit Linux systems only." "error"
        exit 1
    fi
}

# Ensure the script is run as root user, offer to rerun with sudo
if [[ $EUID -ne 0 ]]; then
    display_status "Rerunning with sudo..." "info"
    exec sudo bash "$0" "$@"
fi

# Check for internet connection
check_network() {
    wget -q --spider http://github.com || { display_status "No internet connection detected. Please connect and try again." "error"; exit 1; }
}

# Command existence check
command_exists() {
    command -v "$1" &> /dev/null
}

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
    if command_exists docker; then
        display_status "Docker detected as installed, skipping installation step." "success"
        docker --version
        return
    fi

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

    if [[ -f "dkn-compute-node.zip" ]]; then
        display_status "Found existing Dria node zip file, deleting to avoid duplicate download..." "info"
        rm -f dkn-compute-node.zip
    fi

    wget -q https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip -O dkn-compute-node.zip

    if [[ -d "dkn-compute-node" ]]; then
        display_status "Found existing Dria node directory, deleting to avoid duplicate installation..." "info"
        rm -rf dkn-compute-node
    fi

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

# Uninstall Dria node and Ollama
uninstall_dria_node() {
    display_status "Removing Dria node files and Ollama..." "info"
    
    # Remove Dria node files
    rm -rf $HOME/dkn-compute-node* || { display_status "Failed to remove Dria node files." "error"; return; }
    
    # Remove Ollama files
    rm -rf $HOME/.ollama* || { display_status "Failed to remove Ollama files." "error"; return; }
    
    display_status "Dria node and Ollama files removed successfully." "success"
}

# Main menu functionality
main_menu() {
    check_os_architecture
    check_network

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
        echo -e "${MENU_COLOR}6. Uninstall Dria node${NORMAL}"
        echo -e "${MENU_COLOR}7. Exit${NORMAL}"
        read -p "Please enter an option (1-7): " OPTION

        case $OPTION in
            1) setup_prerequisites ;;
            2) install_docker ;;
            3) install_ollama ;;
            4) install_dria_node ;;
            5) run_dria_node ;;
            6) uninstall_dria_node ;;
            7) exit 0 ;;
            *) display_status "Invalid option, please try again." "error" ;;
        esac
        read -n 1 -s -r -p "Press any key to return to the main menu..."
    done
}

# Start the main menu
main_menu
