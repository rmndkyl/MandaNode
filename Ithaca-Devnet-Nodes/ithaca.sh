#!/bin/bash

# Display a logo
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m' # Reset color

# Function to update and upgrade the system
function update_system() {
    echo -e "${YELLOW}Updating and upgrading the system...${RESET}"
    sudo apt-get update && sudo apt-get upgrade -y
}

# Function to install dependencies
function install_dependencies() {
    echo -e "${CYAN}Installing dependencies...${RESET}"
    sudo apt-get install -y git clang
}

# Function to set LIBCLANG_PATH
function set_libclang_path() {
    echo -e "${BLUE}Locating libclang.so...${RESET}"
    libclang_path=$(find /usr -name "libclang.so*" | head -n 1 | xargs dirname)
    
    if [[ -n "$libclang_path" ]]; then
        export LIBCLANG_PATH=$libclang_path
        echo -e "${GREEN}LIBCLANG_PATH set to $LIBCLANG_PATH${RESET}"
    else
        echo -e "${RED}libclang.so not found. Please ensure clang is installed.${RESET}"
        exit 1
    fi
}

# Function to install Rustup
function install_rustup() {
    echo -e "${BLUE}Installing Rustup...${RESET}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- -y
    echo -e "${BLUE}Configuring Rust path...${RESET}"
    source "$HOME/.cargo/env"
    echo -e "${GREEN}Rust version: $(rustup --version)${RESET}"
}

# Function to clone Odyssey repository
function clone_repository() {
    echo -e "${CYAN}Cloning Odyssey repository...${RESET}"
    git clone https://github.com/ithacaxyz/odyssey.git
    cd odyssey || exit
}

# Function to install the Odyssey node
function install_odyssey() {
    echo -e "${GREEN}Installing the Odyssey node...${RESET}"
    cargo install --path bin/odyssey
}

# Function to generate or import jwt.hex file
function generate_jwt() {
    echo -e "${YELLOW}Creating keys folder...${RESET}"
    mkdir -p "$HOME/odyssey/keys"
    local pvkey_path="$HOME/odyssey/keys/jwt.hex"

    # Prompt user to choose between generating a new key or importing one
    echo -e "${CYAN}Would you like to:${RESET}"
    echo -e "${GREEN}1) Generate a new private key${RESET}"
    echo -e "${GREEN}2) Import an existing private key${RESET}"
    read -p "Enter your choice (1 or 2): " choice

    case $choice in
        1)
            echo -e "${CYAN}Generating a new jwt.hex file...${RESET}"
            openssl rand -hex 32 > "$pvkey_path"
            echo -e "${GREEN}New secret key saved in jwt.hex.${RESET}"
            ;;
        2)
            # Check if jwt.hex file already exists, delete if it does
            if [[ -f "$pvkey_path" ]]; then
                echo -e "${YELLOW}Existing jwt.hex file found. Deleting it...${RESET}"
                rm "$pvkey_path"
                echo -e "${GREEN}Old jwt.hex file deleted.${RESET}"
            fi

            # Prompt for the new private key
            echo -e "${YELLOW}Importing a private key...${RESET}"
            read -sp "Enter your private key: " private_key
            echo
            echo "$private_key" > "$pvkey_path"
            echo -e "${GREEN}Private key saved in jwt.hex.${RESET}"
            ;;
        *)
            echo -e "${RED}Invalid option. Please choose 1 or 2.${RESET}"
            ;;
    esac
}

# Function to export the generated jwt.hex file
function export_jwt() {
    local default_path="$HOME/ithaca_pvkey_backup"
    mkdir -p "$default_path"  # Create the directory if it doesn't exist
    
    read -p "Enter the export path for jwt.hex (default: $default_path): " export_path
    export_path="${export_path:-$default_path}"  # Use default if no input
    
    # Check if the jwt.hex file exists
    if [[ -f "$HOME/odyssey/keys/jwt.hex" ]]; then
        cp "$HOME/odyssey/keys/jwt.hex" "$export_path"
        echo -e "${GREEN}jwt.hex file has been exported to $export_path${RESET}"
        
        # Display the contents of the exported jwt.hex file
        echo -e "${CYAN}Contents of jwt.hex:${RESET}"
        cat "$export_path/jwt.hex"
        
        # Prompt user to press any key to continue, then clear the screen
        echo -e "${YELLOW}\nPress any key to continue...${RESET}"
        read -n 1 -s
        clear
    else
        echo -e "${RED}jwt.hex file not found. Please make sure it's generated before exporting.${RESET}"
    fi
}

# Function to create Ithaca service file
function create_service() {
    echo -e "${CYAN}Creating Ithaca service file...${RESET}"
    sudo tee /etc/systemd/system/ithaca.service > /dev/null <<EOF
[Unit]
Description=Ithaca Devnet Node
After=network.target

[Service]
User=$USER
WorkingDirectory=/root/odyssey
ExecStart=/root/.cargo/bin/odyssey node --chain etc/odyssey-genesis.json --rollup.sequencer-http https://odyssey.ithaca.xyz --http --http.port 8548 --ws --ws.port 8547 --authrpc.port 9551 --port 30304 --authrpc.jwtsecret /root/odyssey/keys/jwt.hex
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${GREEN}Ithaca service file created.${RESET}"
}

# Function to start Ithaca service
function start_service() {
    echo -e "${CYAN}Reloading daemon and enabling Ithaca service...${RESET}"
    sudo systemctl daemon-reload
    sudo systemctl enable ithaca
    sudo systemctl start ithaca
    echo -e "${GREEN}Ithaca node started.${RESET}"
}

# Function to check Ithaca service status
function check_status() {
    echo -e "${CYAN}Checking Ithaca node status...${RESET}"
    sudo systemctl status ithaca
}

# Function to tail Ithaca logs
function check_logs() {
    echo -e "${YELLOW}Tailing Ithaca logs...${RESET}"
    journalctl -u ithaca -f -o cat
}

# Function to delete the Ithaca node
function delete_node() {
    echo -e "${RED}Stopping and disabling the Ithaca node service...${RESET}"
    sudo systemctl stop ithaca
    sudo systemctl disable ithaca

    echo -e "${RED}Removing Ithaca service file...${RESET}"
    sudo rm /etc/systemd/system/ithaca.service

    echo -e "${RED}Deleting Odyssey installation and files...${RESET}"
    rm -rf "$HOME/odyssey"

    echo -e "${GREEN}Ithaca node has been removed.${RESET}"
}

# Function to import private key
function import_private_key() {
    local pvkey_path="$HOME/odyssey/keys/jwt.hex"

    # Check if jwt.hex file already exists
    if [[ -f "$pvkey_path" ]]; then
        echo -e "${YELLOW}Existing jwt.hex file found. Deleting it...${RESET}"
        rm "$pvkey_path"
        echo -e "${GREEN}Old jwt.hex file deleted.${RESET}"
    fi

    # Prompt for new private key
    echo -e "${YELLOW}Importing a new private key...${RESET}"
    read -sp "Enter your private key: " private_key
    echo
    echo "$private_key" > "$pvkey_path"
    echo -e "${GREEN}Private key saved at $pvkey_path${RESET}"
}

# Function to restart the Ithaca node
function restart_service() {
    echo -e "${CYAN}Restarting Ithaca node service...${RESET}"
    sudo systemctl restart ithaca
    echo -e "${GREEN}Ithaca node restarted.${RESET}"
}


# Main menu function
function main_menu() {
    while true; do
        echo -e "${CYAN}=========================================================${RESET}"
        echo -e "${CYAN}Ithaca Devnet Node Setup${RESET}"
        echo -e "${CYAN}=========================================================${RESET}"
        echo -e "${CYAN}Please select an option:${RESET}"
        echo -e "${GREEN}1) Install Ithaca${RESET}"
        echo -e "${GREEN}2) Check Ithaca Status${RESET}"
        echo -e "${GREEN}3) View Ithaca Logs${RESET}"
        echo -e "${GREEN}4) Export PrivateKey${RESET}"
        echo -e "${GREEN}5) Import PrivateKey${RESET}"
        echo -e "${GREEN}6) Restart Ithaca Node${RESET}"
        echo -e "${GREEN}7) Delete Ithaca Node${RESET}"
        echo -e "${GREEN}8) Exit${RESET}"

        read -p "Enter your choice: " choice

        case $choice in
            1)
                update_system
                install_dependencies
                install_git
                install_rustup
                set_libclang_path
                clone_repository
                install_odyssey
                generate_jwt
                create_service
                start_service
                ;;
            2) check_status ;;
            3) check_logs ;;
            4) export_jwt ;;
            5) import_private_key ;;
            6) restart_service ;;
            7) delete_node ;;
            8)
                echo -e "${RED}Exiting...${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option, please try again.${RESET}"
                ;;
        esac

        echo -e "${CYAN}Press any key to return to the main menu...${RESET}"
        read -n 1 -s
    done
}

# Run the main menu
main_menu
