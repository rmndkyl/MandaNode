#!/bin/bash

# Define color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Error handling function
error_exit() {
    echo -e "${RED}Error: $1${RESET}" >&2
    read -p "Press any key to exit..." 
    exit 1
}

# Logging function
log_message() {
    echo -e "${GREEN}[LOG]${RESET} $1"
}

# Comprehensive prerequisite installation
install_prerequisites() {
    log_message "Installing prerequisite packages..."
    
    # Ensure multiverse and universe repositories are enabled
    sudo add-apt-repository -y multiverse
    sudo add-apt-repository -y universe
    
    # Update package lists
    sudo apt update -y
    
    # Install core prerequisites
    sudo apt install -y \
        wget \
        curl \
        jq \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release || error_exit "Failed to install prerequisites"

    # Verify jq is installed
    command -v jq >/dev/null 2>&1 || error_exit "jq is not installed"

    read -p "Press any key to continue..."
}

# Animation and setup
setup_animations() {
    log_message "Showing Animation..."
    
    # Download and execute loader and logo scripts with error handling
    for script in loader logo; do
        wget -O ${script}.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/${script}.sh ||
            error_exit "Failed to download ${script}.sh"
        chmod +x ${script}.sh
        sed -i 's/\r$//' ${script}.sh
        ./${script}.sh || error_exit "Failed to execute ${script}.sh"
    done
    
    rm -rf logo.sh loader.sh
    sleep 4
    read -p "Press any key to continue..."
}

# Install Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        log_message "Installing Docker..."
        # Update system
        sudo apt update -y && sudo apt upgrade -y

        # Remove conflicting packages
        sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc

        # Install prerequisites
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

        # Add Docker's official GPG key and repository
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
        sudo chmod a+r /etc/apt/trusted.gpg.d/docker.gpg
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        # Install Docker
        sudo apt update -y
        sudo apt install -y docker-ce docker-ce-cli containerd.io

        sudo systemctl start docker
        sudo systemctl enable docker

        log_message "Docker installed successfully."
    else
        log_message "Docker is already installed."
    fi
    
    read -p "Press any key to continue..."
}

# Install Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log_message "Installing Docker Compose..."
        
        # Fetch latest version dynamically
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        log_message "Docker Compose installed successfully."
    else
        log_message "Docker Compose is already installed."
    fi
    
    read -p "Press any key to continue..."
}

# Generate secure random credentials
generate_credentials() {
    # Use more secure random generation methods
    username=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 10)
    password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+~`' < /dev/urandom | head -c 16)
    
    echo "$username" "$password"
}

# Get timezone with multiple fallback methods
get_timezone() {
    local timezone

    # Try multiple methods to get timezone
    timezone=$(curl -s http://ip-api.com/json | jq -r '.timezone // empty' 2>/dev/null)
    
    # Fallback methods
    if [[ -z "$timezone" ]]; then
        # Try system timezone
        timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    fi

    # Ultimate fallback
    if [[ -z "$timezone" ]]; then
        timezone="UTC"
        log_message "Unable to detect timezone. Defaulting to UTC."
    fi
    
    echo "$timezone"
}

# Prepare Docker Compose configuration
prepare_docker_compose() {
    # Read credentials and timezone
    read -r username password <<< "$(generate_credentials)"
    timezone=$(get_timezone)

    # Ensure directory exists
    mkdir -p "$HOME/chrom"
    cd "$HOME/chrom" || error_exit "Failed to change directory"

    # Create docker-compose configuration with careful YAML formatting
    cat > docker-compose.yaml << 'EOF'
version: '3.8'
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    user: root
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=${username}
      - PASSWORD=${password}
      - PUID=1000
      - PGID=1000
      - TIMEZONE=${timezone}
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
    volumes:
      - /root/chrom/config:/config
    ports:
      - "3010:3000"
      - "3011:3001"
    shm_size: "1gb"
    restart: unless-stopped
EOF

    # Use sed to replace placeholders safely
    sed -i "s/\${username}/$username/g" docker-compose.yaml
    sed -i "s/\${password}/$password/g" docker-compose.yaml
    sed -i "s/\${timezone}/$timezone/g" docker-compose.yaml

    # Verify configuration file creation and validity
    [[ -f "docker-compose.yaml" ]] || error_exit "Failed to create docker-compose.yaml"
    
    read -p "Press any key to continue..."
}

# Open necessary firewall ports
configure_firewall() {
    log_message "Configuring firewall..."
    # Check if UFW is installed
    if command -v ufw &> /dev/null; then
        sudo ufw allow 3010/tcp
        sudo ufw allow 3011/tcp
    else
        log_message "UFW not found. Skipping firewall configuration."
    fi
    
    read -p "Press any key to continue..."
}

# Deploy Chromium container
deploy_chromium() {
    cd "$HOME/chrom" || error_exit "Failed to change directory"
    
    # Ensure proper Docker Compose installation
    if command -v docker-compose &> /dev/null; then
        docker-compose config || error_exit "Invalid Docker Compose configuration"
        docker-compose up -d || error_exit "Failed to start Chromium container with docker-compose"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose config || error_exit "Invalid Docker Compose configuration"
        docker compose up -d || error_exit "Failed to start Chromium container with docker compose"
    else
        error_exit "Neither docker-compose nor docker compose found"
    fi
    
    read -p "Press any key to continue..."
}

# Get server IP address
get_server_ip() {
    # Try multiple methods to get the IP address
    local ip
    ip=$(hostname -I | awk '{print $1}')
    
    if [[ -z "$ip" ]]; then
        ip=$(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
    fi
    
    if [[ -z "$ip" ]]; then
        ip=$(curl -s https://ipv4.icanhazip.com)
    fi
    
    echo "$ip"
}

# Get and display access information
display_access_info() {
    local ipvps
    ipvps=$(get_server_ip)
    
    echo -e "\n${GREEN}Chromium Container Deployment Completed!${RESET}"
    echo -e "${YELLOW}Access Information:${RESET}"
    echo -e "Web Interface 1: ${BLUE}http://$ipvps:3010${RESET}"
    echo -e "Web Interface 2: ${BLUE}http://$ipvps:3011${RESET}"
    echo -e "\n${RED}Credentials:${RESET}"
    echo -e "Username: ${GREEN}$username${RESET}"
    echo -e "Password: ${GREEN}$password${RESET}"
    
    echo -e "\n${YELLOW}Firewall Configuration Reminder:${RESET}"
    echo -e "- Ensure ports 3010 and 3011 are open in your firewall/security group"
    echo -e "- If using cloud providers like AWS, Azure, or DigitalOcean, check security group settings"

    echo -e "\n${RED}IMPORTANT SECURITY NOTES:${RESET}"
    echo -e "- Change default password after first login"
    echo -e "- Use strong, unique passwords"
    echo -e "- Consider setting up SSH tunneling or VPN for additional security"
    
    log_message "Deployment completed successfully."
    
    read -p "Press any key to continue..."
}

# Main script execution
main() {
    # Ensure script is run as root
    [[ $EUID -ne 0 ]] && error_exit "This script must be run as root. Use 'sudo $0'"

    install_prerequisites
    setup_animations
    install_docker
    install_docker_compose
    configure_firewall
    prepare_docker_compose
    deploy_chromium
    display_access_info

    echo -e "${GREEN}Script execution completed successfully!${RESET}"
    read -p "Press any key to exit..."
}

# Execute main function
main
