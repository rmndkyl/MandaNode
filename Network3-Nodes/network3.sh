#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i', then run this script again."
    exit 1
fi

#Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to check and install Docker and Docker Compose
install_docker() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null
    then
        echo "Docker not detected, installing..."
        sudo apt-get update
        sudo apt-get install ca-certificates curl gnupg lsb-release -y

        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # Set up the Docker repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Authorize Docker files
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        # Install the latest version of Docker
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
        echo "Docker installation completed."
    else
        echo "Docker is already installed."
    fi

    # Check if Docker Compose is installed
    if docker compose version &> /dev/null
    then
        echo "Docker Compose is already installed."
    else
        echo "Docker Compose is not installed. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        echo "Docker Compose installation completed."
    fi
}

# Function to create the docker-compose.yml file with user input
create_docker_compose() {
    read -p "Enter your Network3 account email: " user_email
    read -p "Enter the path on your machine for WireGuard (default: /root/network3/wireguard): " user_path
    user_path=${user_path:-/root/network3/wireguard}  # Use default path if user presses Enter
    
    echo "Creating docker-compose.yml file..."
    mkdir -p network3
    cd network3
    touch docker-compose.yml
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
    echo "docker-compose.yml created with your inputs."
    cd ..
}

# Function to check and return the IP for the binding URL
check_url() {
    # Get the machine's IP address
    ip_address=$(hostname -I | awk '{print $1}')
    
    if [ -z "$ip_address" ]; then
        echo "Could not retrieve IP address. Trying with external service..."
        ip_address=$(curl -s ifconfig.me)
    fi

    if [ -z "$ip_address" ]; then
        echo "Could not retrieve IP address. Please check your network settings."
        return 1
    fi

    # Construct the URL
    node_url="http://account.network3.ai:8080/main?o=$ip_address:8080"
    echo "Bind your node using the following URL: $node_url"
    echo "You can open the url above at Google/Brave/Mozilla."
}

# Function to start the Network3 node
start_node() {
    echo "Starting Network3 node..."
    cd network3
    docker compose up -d
    echo "Network3 node started."
    cd ..
}

# Function to stop the Network3 node
stop_node() {
    echo "Stopping Network3 node..."
    cd network3
    docker compose down
    echo "Network3 node stopped."
    cd ..
}

# Function to restart the Network3 node
restart_node() {
    echo "Restarting Network3 node..."
    cd network3
    docker compose down
    docker compose up -d
    echo "Network3 node restarted."
    cd ..
}

# Function to check container status and view logs
check_status() {
    echo "Checking container status..."
    cd network3
    docker compose ps

    echo ""
    echo "Would you like to view the logs of a specific service? (y/n)"
    read -p "Enter your choice: " view_logs

    if [[ "$view_logs" == "y" ]]; then
        echo ""
        echo "Available services:"
        docker compose ps --services
        echo ""
        read -p "Enter the service name to view logs: " service_name

        if [ -n "$service_name" ]; then
            echo "Fetching logs for $service_name..."
            docker compose logs $service_name
        else
            echo "No service name entered. Skipping log fetch."
        fi
    fi
    cd ..
}

# Function to update the containers
update_node() {
    echo "Updating Network3 node..."
    cd network3
    docker compose down
    docker compose pull
    docker compose up -d
    echo "Network3 node updated."
    cd ..
}

# Function to get private key from file and display instructions
get_private_key() {
    key_file="/root/network3/wireguard/utun.key"
    
    # Check if the key file exists
    if [ -f "$key_file" ]; then
        # Read the private key from the file
        private_key=$(cat "$key_file")
        echo "Private Key: $private_key"
    else
        echo "Private key file not found at $key_file. Please make sure the file exists."
    fi
}

# Main Menu
main_menu() {
    echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
    echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
    echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
    echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
    echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
    echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ Network3 Node Installation ===================================="
    echo "Node community Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
    echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "1. Install Docker and Docker Compose"
    echo "2. Create docker-compose.yml"
    echo "3. Start Network3 Node"
    echo "4. Stop Network3 Node"
    echo "5. Check Container Status"
    echo "6. Update Network3 Node"
    echo "7. Get Node Binding URL"
    echo "8. Restart Network3 Node"
    echo "9. Get Private Key and Bind URL"
    echo "10. Exit"
    echo "========================"
    read -p "Please choose an option [1-10]: " choice

    case $choice in
        1) install_docker ;;
        2) create_docker_compose ;;
        3) start_node ;;
        4) stop_node ;;
        5) check_status ;;
        6) update_node ;;
        7) check_url ;;
        8) restart_node ;;
        9) get_private_key ;;  # Call the new function here
        10) echo "Exiting the script. Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Please choose a valid number between 1-10." ;;
    esac
    echo "Press any key to return to the main menu..."
    read -n 1 -s -r
}

# Main loop
while true; do
    main_menu
done
