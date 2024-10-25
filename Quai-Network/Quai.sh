#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Define colors and styles
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

# Log file path
LOG_FILE="$HOME/quai_script.log"

# Log writing function
write_log() {
    local message="$1"
    local log_type="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$log_type] $message" >> "$LOG_FILE"
}

log_info() {
    local message="$1"
    echo -e "${BLUE}ℹ ${BOLD}[INFO]${RESET} $message"
    write_log "$message" "INFO"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}✅ ${BOLD}[SUCCESS]${RESET} $message"
    write_log "$message" "SUCCESS"
}

log_error() {
    local message="$1"
    echo -e "${RED}❌ ${BOLD}[ERROR]${RESET} $message"
    write_log "$message" "ERROR"
}

# Choose operating system
choose_os() {
    while true; do
        echo -e "${BOLD}Please select your operating system:${RESET}"
        echo "1) macOS"
        echo "2) Windows (WSL)"
        echo "=============================================="
        read -p "Enter option (1 or 2): " os_choice

        case $os_choice in
            1)
                OS="macOS"
                log_info "User selected macOS"
                break
                ;;
            2)
                OS="Windows"
                log_info "User selected Windows (WSL)"
                break
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done

    # After choosing OS, call the main menu
    main_menu
}

# Main menu function
main_menu() {
    while true; do
        clear
		echo -e "${BOLD}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${RESET}"
		echo -e "${BOLD}============================ Quai Node Installation ====================================${RESET}"
		echo -e "${BOLD}Node community Telegram channel: https://t.me/layerairdrop${RESET}"
		echo -e "${BOLD}Node community Telegram group: https://t.me/layerairdropdiskusi${RESET}"
        echo "=================================================================================================="
        echo "Please select an operation to perform:"
        echo "1) Install system dependencies"
        echo "2) Deploy Quai node"
        echo "3) Load snapshot"
        echo "4) View Quai node logs"
        echo "5) Deploy Stratum Proxy"
        echo "6) Start miner"
        echo "7) View mining logs"
        echo "8) Exit"
        echo "=============================================="

        read -p "Enter option: " choice

        case $choice in
            1) install_dependencies ;;
            2) deploy_node ;;
            3) add_snapshots ;;
            4) view_logs ;;
            5) deploy_stratum_proxy ;;
            6) start_miner ;;
            7) view_mining_logs ;;
            8) echo "Exiting script..." && exit 0 ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}

# Install system dependencies
install_dependencies() {
    log_info "Installing system dependencies..."
    if [[ "$OS" == "macOS" ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install git wget curl screen
    elif [[ "$OS" == "Windows" ]]; then
        if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
            log_info "WSL environment detected, using apt package manager..."
            sudo apt update
            sudo apt install -y git wget curl screen
        else
            log_error "Unable to detect WSL environment, please check configuration."
            exit 1
        fi
    fi
    log_success "System dependencies installed successfully."
    pause "Press any key to return to the main menu..."
}

# Deploy Quai node
deploy_node() {
    log_info "Deploying Quai node..."
    check_go

    # Use user directory data path
    mkdir -p ~/data/ && cd ~/data/

    log_info "Cloning Quai node repository..."
    git clone https://github.com/dominant-strategies/go-quai

    cd go-quai
    git checkout v0.38.0
    make go-quai

    read -p 'Enter Quai address: ' quai_address
    read -p 'Enter Qi address: ' qi_address

    screen -dmS node bash -c "./build/bin/go-quai start --node.slices '[0 0]' \
    --node.genesis-nonce 6224362036655375007 \
    --node.quai-coinbases '$quai_address' \
    --node.qi-coinbases '$qi_address' \
    --node.miner-preference '0.5'; exec bash"

    log_success "Quai node has started. Use 'screen -r node' to view logs."
    pause "Press any key to return to the main menu..."
}

# Load snapshot
add_snapshots() {
    log_info "Loading node snapshot..."
    
    sudo apt install unzip -y
    
    # Adjust for macOS user directory path
    if [ ! -d "$HOME/data/go-quai/.config/store" ]; then
        mkdir -p "$HOME/data/go-quai/.config/store"
        log_info "Created storage directory: $HOME/data/go-quai/.config/store"
    fi

    wget -qO- https://snapshots.cherryservers.com/quilibrium/store.zip > /tmp/store.zip
    unzip -j -o /tmp/store.zip -d "$HOME/data/go-quai/.config/store"
    rm /tmp/store.zip

    screen -dmS node bash -c './build/bin/go-quai start'
    log_success "Snapshot loaded and node restarted."
    pause "Press any key to return to the main menu..."
}

# Deploy Stratum Proxy
deploy_stratum_proxy() {
    log_info "Deploying Stratum Proxy..."
    cd ~/data/
    git clone https://github.com/dominant-strategies/go-quai-stratum
    cd go-quai-stratum
    git checkout v0.16.0
    cp config/config.example.json config/config.json
    make go-quai-stratum
    screen -dmS stratum bash -c "./build/bin/go-quai-stratum --region=cyprus --zone=cyprus1 --stratum=3333; exec bash"
    log_success "Stratum Proxy has started."
    pause "Press any key to return to the main menu..."
}

# Start miner
start_miner() {
    log_info "Starting miner..."
    read -p 'Enter node IP address: ' node_ip
    wget https://raw.githubusercontent.com/dominant-strategies/quai-gpu-miner/refs/heads/main/deploy_miner.sh
    chmod +x deploy_miner.sh
    ./deploy_miner.sh

    wget -P /usr/local/bin/ https://github.com/dominant-strategies/quai-gpu-miner/releases/download/v0.2.0/quai-gpu-miner
    chmod +x /usr/local/bin/quai-gpu-miner
    screen -dmS miner bash -c "quai-gpu-miner -U -P stratum://$node_ip:3333 2>&1 | tee /var/log/miner.log"
    log_success "Miner has started! Use 'screen -r miner' to view logs."
    pause "Press any key to return to the main menu..."
}

# View node logs
view_logs() {
    log_info "Viewing node logs..."
    tail -f ~/data/go-quai/nodelogs/global.log
}

# View mining logs
view_mining_logs() {
    log_info "Viewing mining logs..."
    grep Accepted /var/log/miner.log
}

# Pause function, wait for user to press any key to continue
pause() {
    read -rsp "$*" -n1
}

# Check and install Go
check_go() {
    if ! command -v go &> /dev/null || ! go version | grep -q "go1.23"; then
        log_info "Go is not installed, installing Go 1.23..."
        if [[ "$OS" == "macOS" ]]; then
            brew install go
        elif [[ "$OS" == "Windows" ]]; then
            sudo apt install golang -y
        fi
    else
        log_info "Go is already installed, version as follows:"
        go version
    fi
}

# Choose OS and start main menu
choose_os
