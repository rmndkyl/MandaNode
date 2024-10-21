#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Display a logo
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local border="-----------------------------------------------------"

    echo -e "${border}"
    case $level in
        "INFO")
            echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS] ${timestamp} - ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR] ${timestamp} - ${message}${NC}"
            ;;
        *)
            echo -e "${YELLOW}[UNKNOWN] ${timestamp} - ${message}${NC}"
            ;;
    esac
    echo -e "${border}\n"
}

common() {
    local duration=$1
    local message=$2
    local end=$((SECONDS + duration))
    local spinner="⣷⣯⣟⡿⣿⡿⣟⣯⣷"

    echo -n -e "${YELLOW}${message}...${NC} "
    while [ $SECONDS -lt $end ]; do
        printf "\b${spinner:((SECONDS % ${#spinner}))%${#spinner}:1}"
        sleep 0.1
    done
    printf "\r${GREEN}Done!${NC} \n"
}

cleanup_containers() {
    local pattern="admier/brinxai_nodes"
    log "INFO" "Searching for containers with pattern: ${pattern}"
    containers=$(docker ps --format "{{.ID}} {{.Image}} {{.Names}}" | grep "${pattern}")

    if [ -z "$containers" ]; then
        log "INFO" "No matching containers found. Skipping container cleanup."
        return
    else
        log "INFO" "Containers found:"
        echo "$containers"
        container_ids=$(echo "$containers" | awk '{print $1}')
        log "INFO" "Container IDs found:"
        echo "$container_ids"
        docker stop $container_ids && docker rm $container_ids
    fi
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

setup_firewall() {
    log "INFO" "Setting up Firewall..."
    sudo apt-get install -y ufw
    sudo ufw allow 22/tcp
    sudo ufw allow 5011/tcp
    sudo ufw --force enable
    sudo ufw status
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        log "INFO" "Installing Docker and pulling BrinxAI images..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
        sudo apt-get update
        sudo apt-get install -y docker-ce
        sudo docker pull admier/brinxai_nodes-worker:latest
    else
        log "INFO" "Docker is already installed. Skipping Docker installation."
    fi
}

check_gpu() {
    if lspci | grep -i nvidia; then
        log "INFO" "NVIDIA GPU detected. Installing NVIDIA Container Toolkit..."
        wget https://raw.githubusercontent.com/NVIDIA/nvidia-docker/main/scripts/nvidia-docker-install.sh
        sudo bash nvidia-docker-install.sh
    else
        log "INFO" "No NVIDIA GPU detected. Skipping NVIDIA installation."
    fi
}

check_port() {
    local port=$1
    if sudo lsof -i -P -n | grep ":$port" > /dev/null; then
        return 1
    else
        return 0
    fi
}

find_available_port() {
    local port=$1
    while ! check_port "$port"; do
        port=$((port+1))
    done
    echo "$port"
}

clone_repository() {
    if [ ! -d "BrinxAI-Worker-Nodes" ]; then
        log "INFO" "Cloning BrinxAI Worker Nodes repository..."
        git clone https://github.com/admier1/BrinxAI-Worker-Nodes.git
    else
        log "INFO" "BrinxAI Worker Nodes repository is already cloned."
    fi

    cd BrinxAI-Worker-Nodes || exit
    log "INFO" "Running installation script..."
    chmod +x install_ubuntu.sh
    ./install_ubuntu.sh
    log "INFO" "Pulling the latest Docker image for BrinxAI Worker..."
    sudo docker pull admier/brinxai_nodes-worker:latest
}

run_docker_menu() {
    while true; do
        echo "--------------------------------------------"
        echo "Additional Brinxai Node Docker Menu"
        echo "--------------------------------------------"
        echo "1. Run Docker Text-UI (4vCPU/4GB)"
        echo "2. Run Docker stable-diffusion (8vCPU/8GB)"
        echo "3. Run Docker rembg (2vCPU/2GB)"
        echo "4. Run Docker upscaler (2vCPU/2GB)"
        echo "5. Run All of the Dockers."
        echo "6. Exit to main menu"
        echo "--------------------------------------------"
        read -rp "Choose an option [1-6]: " choice

        case $choice in
            1) 
                run_text_ui
                ;;
            2) 
                run_stable_diffusion
                ;;
            3) 
                run_rembg
                ;;
            4) 
                run_upscaler
                ;;
            5) 
                run_all_dockers
                ;;
            6) 
                echo "Returning to main menu..."
                main_menu
                ;;
            *) 
                echo "Invalid option. Please choose a valid number [1-6]."
                ;;
        esac
    done
}

run_text_ui() {
    log "INFO" "Running Docker Text-UI..."
    local text_ui_port=$(find_available_port 5000)
    cleanup_container "text-ui"
    sudo docker run -d --name text-ui --network brinxai-network --cpus=4 --memory=4096m -p 127.0.0.1:"$text_ui_port":5000 admier/brinxai_nodes-text-ui:latest
    run_docker_menu
}

run_stable_diffusion() {
    log "INFO" "Running Docker stable-diffusion..."
    local stable_diffusion_port=$(find_available_port 5050)
    cleanup_container "stable-diffusion"
    sudo docker run -d --name stable-diffusion --network brinxai-network --cpus=8 --memory=8192m -p 127.0.0.1:"$stable_diffusion_port":5050 admier/brinxai_nodes-stabled:latest
    run_docker_menu
}

run_rembg() {
    log "INFO" "Running Docker rembg..."
    local rembg_port=$(find_available_port 7000)
    cleanup_container "rembg"
    sudo docker run -d --name rembg --network brinxai-network --cpus=2 --memory=2048m -p 127.0.0.1:"$rembg_port":7000 admier/brinxai_nodes-rembg:latest
    run_docker_menu
}

run_upscaler() {
    log "INFO" "Running Docker upscaler..."
    local upscaler_port=$(find_available_port 3000)
    cleanup_container "upscaler"
    sudo docker run -d --name upscaler --network brinxai-network --cpus=2 --memory=2048m -p 127.0.0.1:"$upscaler_port":3000 admier/brinxai_nodes-upscaler:latest
    run_docker_menu
}

run_all_dockers() {
    log "INFO" "Running all Docker containers..."
    run_text_ui
    run_stable_diffusion
    run_rembg
    run_upscaler
    run_docker_menu
}

cleanup_container() {
    local container_name=$1
    if sudo docker ps -q -f name="$container_name" | grep -q .; then
        log "INFO" "Stopping and removing container $container_name..."
        sudo docker stop "$container_name" && sudo docker rm "$container_name"
    elif sudo docker ps -aq -f name="$container_name" | grep -q .; then
        log "INFO" "Removing stopped container $container_name..."
        sudo docker rm "$container_name"
    fi
}

run_brinxai_relay() {
    log "INFO" "Running BrinxAI Relay..."

    command -v ufw &> /dev/null && sudo ufw allow 1194/udp && sudo ufw reload
    command -v firewall-cmd &> /dev/null && sudo firewall-cmd --permanent --add-port=1194/udp && sudo firewall-cmd --reload

    if sudo docker ps -q -f name=brinxai_relay; then
        sudo docker stop brinxai_relay && sudo docker rm brinxai_relay
    fi

    arch=$(uname -m)
    if [ "$arch" == "x86_64" ]; then
        sudo docker run -d --name brinxai_relay --cap-add=NET_ADMIN -p 1194:1194/udp admier/brinxai_nodes-relay:latest
    elif [ "$arch" == "aarch64" ] || [ "$arch" == "arm64" ]; then
        sudo docker run -d --name brinxai_relay --cap-add=NET_ADMIN -p 1194:1194/udp admier/brinxai_nodes-relay:arm64
    fi
}

delete_and_stop() {
	pattern="admier/brinxai_nodes"
		echo "Mencari kontainer dengan pola: ${pattern}"
		containers=$(docker ps --format "{{.ID}} {{.Image}} {{.Names}}" | grep "${pattern}")
	if [ -z "$containers" ]; then
    		echo "Tidak ada kontainer yang sesuai ditemukan."
    		exit 0
	fi
		echo "Kontainer yang ditemukan:"
		echo "$containers"
		container_ids=$(echo "$containers" | awk '{print $1}')
		echo "ID kontainer yang ditemukan:"
		echo "$container_ids"
		docker stop $container_ids && docker rm $container_ids
  }

main_menu() {
    echo -e "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo -e "============================ BrinxAI Worker Nodes Manager ================================="
    echo -e "Node community Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
    echo -e "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo -e "Please select an option:"
    echo -e "1) Cleanup Docker containers"
    echo -e "2) Setup Firewall"
    echo -e "3) Install Docker"
    echo -e "4) Check for NVIDIA GPU and install drivers"
    echo -e "5) Clone BrinxAI Worker Nodes repository"
    echo -e "6) Run additional Docker containers"
    echo -e "7) Run BrinxAI Relay"
    echo -e "8) Delete and Stop Node"
    echo -e "9) Exit"

    read -rp "Enter your choice: " choice
    case $choice in
        1)
            cleanup_containers
			read -n 1 -s -r -p "Press any key to continue..."
   			main_menu
            ;;
        2)
            setup_firewall
			read -n 1 -s -r -p "Press any key to continue..."
   			main_menu
            ;;
        3)
            install_docker
			read -n 1 -s -r -p "Press any key to continue..."
   			main_menu
            ;;
        4)
            check_gpu
			read -n 1 -s -r -p "Press any key to continue..."
   			main_menu
            ;;
        5)
            clone_repository
			read -n 1 -s -r -p "Press any key to continue..."
   			main_menu
            ;;
        6)
            run_docker_menu
			read -n 1 -s -r -p "Press any key to continue..."
   			main_menu
            ;;
        7)
            run_brinxai_relay
			read -n 1 -s -r -p "Press any key to continue..."
			main_menu
            ;;
	8)
            delete_and_stop
			read -n 1 -s -r -p "Press any key to continue..."
   			main_menu
            ;;
        9)
            log "INFO" "Exiting BrinxAI Worker Nodes Manager."
            exit 0
            ;;
        *)
            log "ERROR" "Invalid option. Please try again."
            main_menu
            ;;
    esac
}

main() {
    main_menu
}

main
