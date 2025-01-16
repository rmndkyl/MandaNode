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
    exit 1
}

# Logging function
log_message() {
    echo -e "${GREEN}[LOG]${RESET} $1"
}

# Install prerequisite packages
install_prerequisites() {
    log_message "Installing prerequisite packages..."
    sudo apt update -y
    sudo apt install -y wget curl jq software-properties-common || error_exit "Failed to install prerequisites"
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
}

# Generate secure random credentials
generate_credentials() {
    # Use more secure random generation methods
    username=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 10)
    password=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+~`' < /dev/urandom | head -c 16)
    
    echo "$username" "$password"
}

# Get timezone based on IP with multiple fallback methods
get_timezone() {
    local timezone

    # Try multiple methods to get timezone
    timezone=$(curl -s http://ip-api.com/json | jq -r '.timezone' 2>/dev/null)
    
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

    # Create docker-compose configuration with proper indentation
    cat > docker-compose.yaml << EOF
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
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

    # Verify configuration file creation
    [[ -f "docker-compose.yaml" ]] || error_exit "Failed to create docker-compose.yaml"
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
}

# Deploy Chromium container
deploy_chromium() {
    cd "$HOME/chrom" || error_exit "Failed to change directory"
    
    # Use docker compose instead of docker-compose for newer versions
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d || error_exit "Failed to start Chromium container"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose up -d || error_exit "Failed to start Chromium container"
    else
        error_exit "Neither docker-compose nor docker compose found"
    fi
}

# Get and display access information
display_access_info() {
    local ipvps
    ipvps=$(curl -s ifconfig.me)
    
    echo -e "\n${GREEN}Chromium Container Deployment Completed!${RESET}"
    echo -e "${YELLOW}Access Information:${RESET}"
    echo -e "Web Interface 1: ${BLUE}http://$ipvps:3010${RESET}"
    echo -e "Web Interface 2: ${BLUE}http://$ipvps:3011${RESET}"
    echo -e "\n${RED}Credentials:${RESET}"
    echo -e "Username: ${GREEN}$username${RESET}"
    echo -e "Password: ${GREEN}$password${RESET}"
    
    log_message "Deployment completed successfully."
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
}

# Execute main function
main
