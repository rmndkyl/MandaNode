#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Function for printing colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function for printing section headers
print_header() {
    local message=$1
    echo -e "\n${PURPLE}====== $message ======${NC}\n"
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    print_message "$RED" "This script must be run as root."
    print_message "$YELLOW" "Please try switching to the root user using 'sudo -i', then run this script again."
    exit 1
fi

press_any_key() {
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s -r
    echo
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    # Check CPU cores
    cpu_cores=$(nproc)
    print_message "$BLUE" "CPU Cores: $cpu_cores"
    
    # Check available memory
    total_mem=$(free -m | awk '/Mem:/ {print $2}')
    print_message "$BLUE" "Total Memory: ${total_mem}MB"
    
    # Check available disk space
    disk_space=$(df -h / | awk 'NR==2 {print $4}')
    print_message "$BLUE" "Available Disk Space: $disk_space"
    
    # Minimum requirements
    if [ $cpu_cores -lt 2 ] || [ $total_mem -lt 2048 ]; then
        print_message "$RED" "Warning: Your system might not meet the minimum requirements:"
        print_message "$YELLOW" "- Recommended: 2+ CPU cores (you have $cpu_cores)"
        print_message "$YELLOW" "- Recommended: 2GB+ RAM (you have ${total_mem}MB)"
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ "$continue_anyway" != "y" ]]; then
            exit 1
        fi
    fi
}

# Enhanced Docker installation function
install_docker() {
    print_header "Docker Installation"
    sudo rm /usr/local/bin/docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    if ! command -v docker &> /dev/null; then
        print_message "$YELLOW" "Docker not detected, installing..."
        
        # Add error handling and progress indication
        {
            sudo apt-get update
            sudo apt-get install ca-certificates curl gnupg lsb-release -y
            
            # Add Docker's official GPG key with backup source
            sudo mkdir -p /etc/apt/keyrings
            if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
                print_message "$RED" "Failed to add Docker GPG key. Trying backup source..."
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            fi

            # Set up repository with error handling
            if ! echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
                print_message "$RED" "Failed to add Docker repository. Please check your internet connection."
                exit 1
            fi

            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            sudo apt-get update
            sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
            
            print_message "$GREEN" "Docker installation completed successfully!"
        } || {
            print_message "$RED" "Docker installation failed. Please check the error messages above."
            exit 1
        }
    else
        print_message "$GREEN" "Docker is already installed."
    fi

    # Check Docker service status
    if systemctl is-active --quiet docker; then
        print_message "$GREEN" "Docker service is running."
    else
        print_message "$YELLOW" "Starting Docker service..."
        sudo systemctl start docker
    fi
    press_any_key
}

# Enhanced create_docker_compose function with validation
create_docker_compose() {
    print_header "Creating Docker Compose Configuration"
    
    # Email validation
    while true; do
        read -p "Enter your Network3 account email: " user_email
        if [[ "$user_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            break
        else
            print_message "$RED" "Invalid email format. Please try again."
        fi
    done

    # Path validation with default
    read -p "Enter the path for WireGuard [default: /root/network3/wireguard]: " user_path
    user_path=${user_path:-/root/network3/wireguard}
    
    # Create directory structure
    mkdir -p "$user_path"
    
    print_message "$BLUE" "Creating docker-compose.yml file..."
    mkdir -p network3
    cd network3

    # Backup existing configuration if it exists
    if [ -f docker-compose.yml ]; then
        mv docker-compose.yml docker-compose.yml.backup
        print_message "$YELLOW" "Existing configuration backed up as docker-compose.yml.backup"
    fi

    # Create new configuration with proper formatting
    cat > docker-compose.yml <<EOL
version: '3.3'
services:  
  network3-01:    
    image: aron666/network3-ai    
    container_name: network3-01    
    ports:      
      - 8080:8080/tcp
    environment:
      - EMAIL=$user_email
    volumes:
      - $user_path:/usr/local/etc/wireguard    
    healthcheck:      
      test: curl -fs http://localhost:8080/ || exit 1      
      interval: 30s      
      timeout: 5s      
      retries: 5      
      start_period: 30s    
    privileged: true    
    devices:      
      - /dev/net/tun    
    cap_add:      
      - NET_ADMIN    
    restart: always

  autoheal:    
    restart: always    
    image: willfarrell/autoheal    
    container_name: autoheal    
    environment:      
      - AUTOHEAL_CONTAINER_LABEL=all    
    volumes:      
      - /var/run/docker.sock:/var/run/docker.sock
EOL

    print_message "$GREEN" "docker-compose.yml created successfully!"
    cd ..
    press_any_key
}

# Main menu with enhanced visual design
main_menu() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░
██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝
██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░
██║███████║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░
╚═╝═════╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░
EOF
    echo -e "${NC}"
    
    print_message "$YELLOW" "Script and tutorial written by Telegram user @rmndkyl"
    print_message "$GREEN" "Free and open source - do not believe in paid versions"
    
    print_header "Network3 Node Installation Menu"
    
    print_message "$BLUE" "Community Links:"
    print_message "$CYAN" "Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
    print_message "$CYAN" "Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    
    echo -e "\n${YELLOW}Available Options:${NC}"
    echo -e "${CYAN}1.${NC} Install Docker and Docker Compose"
    echo -e "${CYAN}2.${NC} Create docker-compose.yml"
    echo -e "${CYAN}3.${NC} Start Network3 Node"
    echo -e "${CYAN}4.${NC} Stop Network3 Node"
    echo -e "${CYAN}5.${NC} Check Container Status"
    echo -e "${CYAN}6.${NC} Update Network3 Node"
    echo -e "${CYAN}7.${NC} Get Node Binding URL"
    echo -e "${CYAN}8.${NC} Restart Network3 Node"
    echo -e "${CYAN}9.${NC} Get Private Key"
    echo -e "${CYAN}10.${NC} Exit"
    echo -e "${PURPLE}========================${NC}"
    
    read -p "Please choose an option [1-10]: " choice

    case $choice in
        1) check_system_requirements && install_docker ;;
        2) create_docker_compose ;;
        3) start_node ;;
        4) stop_node ;;
        5) check_status ;;
        6) update_node ;;
        7) check_url ;;
        8) restart_node ;;
        9) get_private_key ;;
        10) print_message "$GREEN" "Exiting the script. Goodbye!"; exit 0 ;;
        *) 
            print_message "$RED" "Invalid option. Please choose a valid number between 1-10."
            press_any_key
            ;;
    esac
}

# Function to start the Network3 node
start_node() {
    print_header "Starting Network3 Node"
    
    # Check if docker-compose.yml exists
    if [ ! -f "network3/docker-compose.yml" ]; then
        print_message "$RED" "Error: docker-compose.yml not found!"
        print_message "$YELLOW" "Please run option 2 first to create the configuration."
        press_any_key
        return 1
    fi
    
    cd network3
    print_message "$BLUE" "Starting containers..."
    
    # Try to start containers with error handling
    if docker-compose up -d; then
        print_message "$GREEN" "Network3 node started successfully!"
        
        # Wait for container health check
        print_message "$YELLOW" "Waiting for container health check..."
        sleep 10
        
        # Check container status
        if docker-compose ps | grep -q "network3-01.*Up"; then
            print_message "$GREEN" "Container is running properly."
            
            # Display initial logs
            print_message "$CYAN" "Initial container logs:"
            docker-compose logs --tail 10 network3-01
        else
            print_message "$RED" "Container may have started but is not healthy. Please check logs."
        fi
    else
        print_message "$RED" "Failed to start Network3 node. See error above."
    fi
    cd ..
    press_any_key
}

# Function to stop the Network3 node
stop_node() {
    print_header "Stopping Network3 Node"
    
    # Check if docker-compose.yml exists
    if [ ! -f "network3/docker-compose.yml" ]; then
        print_message "$RED" "Error: docker-compose.yml not found!"
        print_message "$YELLOW" "No running containers to stop."
        return 1
    fi

    cd network3
    print_message "$BLUE" "Stopping containers..."
    
    # Check if containers are running first
    if ! docker-compose ps | grep -q "Up"; then
        print_message "$YELLOW" "No running containers found."
        cd ..
        return 0
    fi
    
    # Try to stop containers with error handling
    if docker-compose down; then
        print_message "$GREEN" "Network3 node stopped successfully!"
    else
        print_message "$RED" "Failed to stop Network3 node gracefully."
        print_message "$YELLOW" "Attempting force stop..."
        docker-compose down -v --remove-orphans
    fi
    cd ..
    press_any_key
}

# Function to check container status and view logs
check_status() {
    print_header "Checking Container Status"
    
    # Check if docker-compose.yml exists
    if [ ! -f "network3/docker-compose.yml" ]; then
        print_message "$RED" "Error: docker-compose.yml not found!"
        press_any_key
        return 1
    fi

    cd network3
    
    # Get container status
    print_message "$BLUE" "Current container status:"
    docker-compose ps
    
    # Check container health
    if docker-compose ps | grep -q "network3-01.*Up"; then
        print_message "$GREEN" "Network3 node is running."
        
        # Get container resource usage
        print_message "$CYAN" "\nContainer resource usage:"
        docker stats --no-stream network3-01
        
        # Option to view logs
        echo -e "\n${YELLOW}Would you like to:${NC}"
        echo "1. View recent logs"
        echo "2. View and follow logs in real-time"
        echo "3. Return to main menu"
        read -p "Enter your choice [1-3]: " log_choice
        
        case $log_choice in
            1)
                print_message "$BLUE" "\nShowing recent logs:"
                docker-compose logs --tail 50 network3-01
                press_any_key
                ;;
            2)
                print_message "$BLUE" "\nShowing live logs (Ctrl+C to exit):"
                docker-compose logs -f network3-01
                press_any_key
                ;;
            3)
                print_message "$YELLOW" "Returning to main menu..."
                ;;
            *)
                print_message "$RED" "Invalid option."
                press_any_key
                ;;
        esac
    else
        print_message "$RED" "Network3 node is not running."
        press_any_key
    fi
    cd ..
}

# Function to update the containers
update_node() {
    print_header "Updating Network3 Node"
    
    # Check if docker-compose.yml exists
    if [ ! -f "network3/docker-compose.yml" ]; then
        print_message "$RED" "Error: docker-compose.yml not found!"
        return 1
    fi

    cd network3
    
    # Backup current configuration
    print_message "$BLUE" "Backing up current configuration..."
    cp docker-compose.yml docker-compose.yml.backup
    
    # Pull new images
    print_message "$YELLOW" "Pulling latest images..."
    if ! docker-compose pull; then
        print_message "$RED" "Failed to pull new images."
        print_message "$YELLOW" "Restoring backup..."
        mv docker-compose.yml.backup docker-compose.yml
        cd ..
        return 1
    fi
    
    # Stop current containers
    print_message "$BLUE" "Stopping current containers..."
    docker-compose down
    
    # Start updated containers
    print_message "$YELLOW" "Starting updated containers..."
    if docker-compose up -d; then
        print_message "$GREEN" "Network3 node updated successfully!"
        
        # Wait for container health check
        print_message "$YELLOW" "Waiting for container health check..."
        sleep 10
        
        # Verify update
        if docker-compose ps | grep -q "network3-01.*Up"; then
            print_message "$GREEN" "Update verified - container is running properly."
        else
            print_message "$RED" "Container may have started but is not healthy."
            print_message "$YELLOW" "Checking logs..."
            docker-compose logs network3-01
        fi
    else
        print_message "$RED" "Failed to start updated containers."
        print_message "$YELLOW" "Rolling back to previous version..."
        mv docker-compose.yml.backup docker-compose.yml
        docker-compose up -d
    fi
    cd ..
    press_any_key
}

# Function to restart the Network3 node
restart_node() {
    print_header "Restarting Network3 Node"
    
    # Check if docker-compose.yml exists
    if [ ! -f "network3/docker-compose.yml" ]; then
        print_message "$RED" "Error: docker-compose.yml not found!"
        return 1
    fi

    cd network3
    print_message "$BLUE" "Restarting containers..."
    
    # Stop containers
    print_message "$YELLOW" "Stopping containers..."
    if ! docker-compose down; then
        print_message "$RED" "Failed to stop containers."
        cd ..
        return 1
    fi
    
    # Start containers
    print_message "$YELLOW" "Starting containers..."
    if docker-compose up -d; then
        print_message "$GREEN" "Network3 node restarted successfully!"
        
        # Wait for container health check
        print_message "$YELLOW" "Waiting for container health check..."
        sleep 10
        
        if docker-compose ps | grep -q "network3-01.*Up"; then
            print_message "$GREEN" "Restart verified - container is running properly."
        else
            print_message "$RED" "Container may have started but is not healthy."
            print_message "$YELLOW" "Checking logs..."
            docker-compose logs network3-01
        fi
    else
        print_message "$RED" "Failed to restart containers."
    fi
    cd ..
    press_any_key
}

# Function to check and return the IP for the binding URL
check_url() {
    print_header "Generating Node Binding URL"
    
    # Try different methods to get IP
    print_message "$BLUE" "Detecting IP address..."
    
    # Method 1: hostname
    ip_address=$(hostname -I | awk '{print $1}')
    
    # Method 2: ip route
    if [ -z "$ip_address" ]; then
        ip_address=$(ip route get 1 | awk '{print $(NF-2);exit}')
    fi
    
    # Method 3: external service
    if [ -z "$ip_address" ]; then
        print_message "$YELLOW" "Could not detect local IP, trying external service..."
        ip_address=$(curl -s ifconfig.me)
    fi
    
    if [ -z "$ip_address" ]; then
        print_message "$RED" "Could not detect IP address. Please check your network connection."
        return 1
    fi
    
    # Construct and display the URL
    node_url="http://account.network3.ai:8080/main?o=$ip_address:8080"
    print_message "$GREEN" "Successfully generated binding URL!"
    echo -e "\n${CYAN}Bind your node using this URL:${NC}"
    echo -e "${YELLOW}$node_url${NC}"
    echo -e "\n${BLUE}You can open this URL in Google Chrome/Brave/Mozilla Firefox.${NC}"
    press_any_key
}

# Function to get private key
get_private_key() {
    print_header "Retrieving Private Key"
    
    key_file="/root/network3/wireguard/utun.key"
    
    # Check if directory exists
    if [ ! -d "/root/network3/wireguard" ]; then
        print_message "$RED" "Error: WireGuard directory not found!"
        print_message "$YELLOW" "Please make sure the node is properly set up and running."
        return 1
    fi
    
    # Check if key file exists
    if [ -f "$key_file" ]; then
        print_message "$BLUE" "Reading private key..."
        private_key=$(cat "$key_file")
        
        if [ -n "$private_key" ]; then
            print_message "$GREEN" "Successfully retrieved private key!"
            echo -e "\n${CYAN}Private Key:${NC} ${YELLOW}$private_key${NC}"
        else
            print_message "$RED" "Private key file is empty!"
        fi
    else
        print_message "$RED" "Private key file not found at $key_file"
        print_message "$YELLOW" "Please ensure the node is properly initialized."
    fi
    press_any_key
}

# Main loop
while true; do
    main_menu
done
