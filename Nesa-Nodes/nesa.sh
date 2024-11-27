#!/bin/bash

# Define color variables
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

# Display a logo
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Display Banner
echo -e "${YELLOW}"
echo "=============================================="
echo "        Nesa Node Installation Manager        "
echo "=============================================="
echo -e "${NC}"

# Function to install required packages
install_package() {
    local package=$1
    if ! dpkg -s $package &> /dev/null; then
        echo -e "${BLUE}Installing $package...${NC}"
        sudo apt update && sudo apt install -y $package
        echo -e "${GREEN}$package installed successfully!${NC}"
    else
        echo -e "${GREEN}$package is already installed.${NC}"
    fi
}

# Main installation function
install_node() {
    # Install required packages
    install_package "curl"
    install_package "jq"

    # Set up working directory
    WORK_DIR="/root/nesa"
    mkdir -p $WORK_DIR
    cd $WORK_DIR

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${BLUE}Installing Docker...${NC}"
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
            sudo apt-get remove -y $pkg
        done
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update -y && sudo apt install -y docker-ce
        sudo systemctl start docker
        sudo systemctl enable docker

        echo -e "${BLUE}Installing Docker Compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker and Docker Compose installed successfully!${NC}"
    else
        echo -e "${GREEN}Docker is already installed.${NC}"
    fi

    # Install Node.js
    echo -e "${BLUE}Installing Node.js LTS version using NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    echo -e "${GREEN}Node.js installed successfully!${NC}"

    # User instructions
    echo -e "${YELLOW}Please obtain your API key from the following site:${NC}"
    echo -e "${BLUE}https://huggingface.co/join${NC}"
    echo -e "${YELLOW}Download the Leap Wallet and copy your private key.${NC}"
    read -p "Press Enter once you have completed the above steps."

    echo -e "${YELLOW}Provide the following settings during installation:${NC}"
    echo -e "${BLUE}Wizardy - Node Name - Email - Referral Code - API Key - Private Key${NC}"
    read -p "Press Enter to continue."

    # Run the installation program
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
}

# Function to change port and restart the node
change_port_and_restart() {
    echo -e "${YELLOW}Currently running Nesa-related containers:${NC}"
    docker ps --filter "name=nesa" --format "ID: {{.ID}}, Name: {{.Names}}, Ports: {{.Ports}}"

    # Input the container ID
    read -p "Enter the ID of the Nesa container listed above: " container_id

    # Validate container ID
    if ! docker ps --filter "id=$container_id" --format "{{.ID}}" &> /dev/null; then
        echo -e "${RED}Error: Invalid container ID. Please enter a valid ID from the list above.${NC}"
        return 1
    fi

    # Stop the container
    echo -e "${BLUE}Stopping the container...${NC}"
    docker stop "$container_id"

    # Function to find an available port
    find_available_port() {
        local start_port=$1
        while ss -tuln | grep ":$start_port" &> /dev/null; do
            start_port=$((start_port + 1))
        done
        echo $start_port
    }

    # Check if port 8080 is available, otherwise find the next one
    echo -e "${YELLOW}Checking for available ports...${NC}"
    target_port=$(find_available_port 8080)
    echo -e "${GREEN}Using port: $target_port${NC}"

    # Modify the docker-compose.yml file to use the new port
    echo -e "${BLUE}Updating the port in the docker-compose.yml file...${NC}"
    cd /root/.nesa/docker || {
        echo -e "${RED}Error: Failed to navigate to /root/.nesa/docker. Check if the directory exists.${NC}"
        return 1
    }
    sed -i "s/- [0-9]\+:8080/- $target_port:8080/" compose.ipfs.yml

    # Verify sed operation success
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to update the port in compose.ipfs.yml. Please check the file manually.${NC}"
        return 1
    fi

    # Restart the node
    echo -e "${BLUE}Restarting the node...${NC}"
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Node restarted successfully!${NC}"
        echo -e "${CYAN}Visit your dashboard at: https://node.nesa.ai/${NC}"
    else
        echo -e "${RED}Error: Node restart failed. Please check the logs for more details.${NC}"
        return 1
    fi
}

# Main Menu
while true; do
    echo -e "\n${YELLOW}=== Main Menu ===${NC}"
    echo -e "${BLUE}1) Install Node${NC}"
    echo -e "${BLUE}2) Change Port and Restart${NC}"
    echo -e "${BLUE}3) Exit${NC}"
    read -p "Please choose an option (1-3): " choice

    case $choice in
        1)
            echo -e "${GREEN}Starting Node Installation...${NC}"
            install_node
            ;;
        2)
            echo -e "${GREEN}Changing Port and Restarting Node...${NC}"
            change_port_and_restart
            ;;
        3)
            echo -e "${GREEN}Thank you for using the Nesa Node Installation Manager! Goodbye.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select a valid option.${NC}"
            ;;
    esac
done
