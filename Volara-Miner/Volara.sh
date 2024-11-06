#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Automation script: Volara-Miner installation and startup

# Define color codes
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Define icons
INFO_ICON="ℹ️"
SUCCESS_ICON="✅"
WARNING_ICON="⚠️"
ERROR_ICON="❌"

# Define log file path
LOG_FILE="/var/log/dusk_script.log"

# Information display functions
log_info() {
  echo -e "${CYAN}${INFO_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO] ${1}" >> "${LOG_FILE}"
}

log_success() {
  echo -e "${GREEN}${SUCCESS_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [SUCCESS] ${1}" >> "${LOG_FILE}"
}

log_warning() {
  echo -e "${YELLOW}${WARNING_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [WARNING] ${1}" >> "${LOG_FILE}"
}

log_error() {
  echo -e "${RED}${ERROR_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] ${1}" >> "${LOG_FILE}"
  echo "Please refer to the logs for more details or contact support if needed."
}

# Function to check dependencies
check_dependency() {
  command -v "$1" &> /dev/null
  if [ $? -ne 0 ]; then
    log_error "$1 is not installed. Please install it before proceeding."
    exit 1
  fi
}

# Check required dependencies
check_dependency "curl"
check_dependency "docker"
check_dependency "screen"

# Function: Update and upgrade system
update_system() {
  log_info "Updating and upgrading the system..."
  sudo apt update -y && sudo apt upgrade -y
}

# Function: Install Docker
install_docker() {
  log_info "Checking if Docker is already installed..."

  if docker --version &> /dev/null; then
    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    log_info "Docker is already installed. Version: $docker_version"
    return 0
  fi

  log_info "Docker not found. Proceeding with installation..."

  log_info "Removing conflicting packages..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo chmod +x /usr/local/bin/docker-compose

  docker --version &> /dev/null
  if [[ $? -eq 0 ]]; then
    log_success "Docker installed successfully."
  else
    log_error "Docker installation failed."
    exit 1
  fi
}

# Function: Start Volara-Miner
start_miner() {
  log_info "Please ensure your Vana network wallet has enough test tokens. Visit the faucet: https://faucet.vana.org/moksha to receive test tokens."
  echo -e "${YELLOW}Tip: Please check your Vana network balance. Continue after receiving Moksha test tokens.${RESET}"
  
  echo -e "${MAGENTA}Enter your Metamask private key (it will not be shown):${RESET}"
  read -sp "Private Key: " VANA_PRIVATE_KEY
  export VANA_PRIVATE_KEY

  if [[ -z "$VANA_PRIVATE_KEY" ]]; then
    log_error "Metamask private key cannot be empty. Please rerun the script and enter a valid key."
    exit 1
  fi

  log_info "Pulling Volara-Miner Docker image..."
  timeout 300 docker pull volara/miner
  if [[ $? -eq 0 ]]; then
    log_success "Volara-Miner Docker image pulled successfully."
  else
    log_error "Failed to pull Volara-Miner Docker image. Check your network connection."
    exit 1
  fi

  log_info "Creating Screen session..."
  screen -S volara -m bash -c "docker run -it -e VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY} volara/miner"

  log_info "Please manually connect to the Screen session: screen -r volara"
  log_info "In the Screen session, please follow the on-screen instructions to complete Google authentication and X account login."

  log_success "Setup complete! You can check your mining points at https://volara.xyz/."
}

# Function: View Volara-Miner logs
view_miner_logs() {
  clear
  log_info "Displaying logs of Volara-Miner..."
  docker ps --filter "ancestor=volara/miner" --format "{{.Names}}" | while read container_name
  do
    echo "Logs from container: $container_name"
    docker logs --tail 20 "$container_name"
    echo "--------------------------------------"
  done
}

# Function to rotate log files
log_file_rotate() {
  if [ -f "$LOG_FILE" ]; then
    mv "$LOG_FILE" "$LOG_FILE.bak"
  fi
}

log_file_rotate

# Main menu function
show_menu() {
  clear
  echo -e "${BOLD}${BLUE}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${RESET}"
  echo -e "${BOLD}${BLUE}==================== Volara-Miner Setup ====================${RESET}"
  echo -e "${BOLD}${BLUE}Node community Telegram channel: https://t.me/layerairdrop${RESET}"
  echo -e "${BOLD}${BLUE}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${RESET}"
  echo -e "To exit the script, press ctrl+c on your keyboard."
  echo "1. Update system and upgrade packages"
  echo "2. Install Docker and its dependencies"
  echo "3. Start the Volara-Miner with your wallet credentials"
  echo "4. View the most recent Volara-Miner logs"
  echo "5. Exit"
  echo -e "${BOLD}===========================================================${RESET}"
  echo -n "Select an option [1-5]: "
}

# Main loop
while true; do
  show_menu
  read -r choice
  case $choice in
    1)
      update_system
      ;;
    2)
      install_docker
      ;;
    3)
      start_miner
      ;;
    4)
      view_miner_logs
      ;;
    5)
      log_info "Exiting the script, goodbye!"
      exit 0
      ;;
    *)
      log_warning "Invalid choice. Please select a valid option."
      ;;
  esac
done
