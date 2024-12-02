#!/bin/bash

YELLOW='\033[1;33m'
NC='\033[0m'

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Main Installation Function
install_node() {
    # Install required packages
    sudo apt update && sudo apt install curl && apt install jq -y

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
            sudo apt-get remove -y $pkg
        done

        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        
        sudo apt update -y && sudo apt install -y docker-ce
        sudo systemctl start docker
        sudo systemctl enable docker

        echo "Installing Docker Compose..."

        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        echo "Docker has been successfully installed."
    else
        echo "Docker is already installed."
    fi

    # Install Node.js
    echo -e "${YELLOW}Installing and setting up the latest Node.js LTS version...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    sudo apt install -y nodejs

    echo -e "${YELLOW}Please obtain an API key from the following website.${NC}"
    echo -e "${YELLOW}Click on your profile icon -> Settings -> Access Tokens -> Create New Token.${NC}"
    echo -e "${YELLOW}https://huggingface.co/join${NC}"
    echo -e "${YELLOW}Download Leap Wallet and copy your private key.${NC}"
    read -p "Press Enter once you have completed the above steps."

    echo -e "${YELLOW}When running the installation command, please provide the following details:${NC}"
    echo -e "${YELLOW}Wizardy - Node Name - Email - Referral Code - API Key - Private Key${NC}"
    echo -e "${YELLOW}For the referral code, visit the dashboard site, connect your wallet, open it, and enter the address starting with 'nesa'.${NC}"
    echo -e "${YELLOW}You can use your own referral code or enter 'nesa1xrchtmx8s7l45edjxl8qvc855l8qfs0snnhutw'.${NC}"
    echo -e "${YELLOW}After execution, port conflicts might occur, so please re-run the script to change the port settings.${NC}"
    echo -e "${YELLOW}The dashboard site is available at: https://node.nesa.ai/${NC}"
    read -p "Press Enter once you have reviewed the above steps."

    # Execute the installation program
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
}

# Function to change port and restart
change_port_and_restart() {
    echo -e "${YELLOW}Currently running Nesa-related containers:${NC}"
    docker ps --filter "name=nesa" --format "ID: {{.ID}}, Name: {{.Names}}, Ports: {{.Ports}}"

    # Input container ID
    read -p "Enter the ID of the Nesa container listed above: " container_id

    # Stop container
    echo -e "${YELLOW}Stopping the container...${NC}"
    docker stop $container_id
    
    # Check currently used ports
    used_ports=$(docker ps --format "{{.Ports}}" | grep -oP '(?<=:)\d+(?=->)' | sort -n)
    echo -e "${YELLOW}List of currently used ports:${NC}"
    echo "$used_ports"
    
    # Find the next available port
    last_port=8080
    for port in $used_ports; do
        if [ $port -ge $last_port ]; then
            last_port=$((port + 1))
        fi
    done
    
    echo -e "${YELLOW}The next available port is: $last_port${NC}"
    
    # Modify the docker-compose.yml file
    echo -e "${YELLOW}Changing the port to $last_port...${NC}"
    cd /root/.nesa/docker
    sed -i "s/- [0-9]\+:8080/- $last_port:8080/" compose.ipfs.yml
    
    # Restart the node
    echo -e "${YELLOW}Restarting the node...${NC}"
    read -p "Visit the dashboard at: https://node.nesa.ai/ : Press Enter to continue."
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
}

# Main menu
while true; do
    echo -e "\n${YELLOW}=== Nesa Node Installation Manager ===${NC}"
    echo "1) Install Node"
    echo "2) Change Port and Restart"
    echo "3) Exit"
    read -p "Select an option (1-3): " choice

    case $choice in
        1)
            install_node
            ;;
        2)
            change_port_and_restart
            ;;
        3)
            echo "Exiting the program."
            exit 0
            ;;
        *)
            echo "Invalid selection. Please choose between 1-3."
            ;;
    esac
done
