#!/usr/bin/env bash

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i' and then run this script again."
    exit 1
fi

# Script save path
SCRIPT_PATH="$HOME/Ritual.sh"

# Log file paths
LOG_FILE="/root/ritual_install.log"
DOCKER_LOG_FILE="/root/infernet_node.log"

# Initialize log files
echo "Ritual Script Log - $(date)" > "$LOG_FILE"
echo "Docker Container Log - $(date)" > "$DOCKER_LOG_FILE"

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions." | tee -a "$LOG_FILE"
        echo "============================ Ritual Node Installation ====================================" | tee -a "$LOG_FILE"
        echo "To exit the script, press Ctrl + C." | tee -a "$LOG_FILE"
        echo "Please select an operation:" | tee -a "$LOG_FILE"
        echo "1) Install Ritual Node" | tee -a "$LOG_FILE"
        echo "2) View Ritual Node Logs" | tee -a "$LOG_FILE"
        echo "3) Remove Ritual Node" | tee -a "$LOG_FILE"
        echo "4) Exit Script" | tee -a "$LOG_FILE"
        
        read -p "Enter your choice: " choice
        echo "User selection: $choice" >> "$LOG_FILE"

        case $choice in
            1) 
                install_ritual_node
                ;;
            2)
                view_logs
                ;;
            3)
                remove_ritual_node
                ;;
            4)
                echo "Exiting script!" | tee -a "$LOG_FILE"
                exit 0
                ;;
            *)
                echo "Invalid option, please try again." | tee -a "$LOG_FILE"
                ;;
        esac

        echo "Press any key to continue..." | tee -a "$LOG_FILE"
        read -n 1 -s
    done
}

function install_ritual_node() {
    echo "Starting Ritual Node Installation - $(date)" | tee -a "$LOG_FILE"
    
    # System update and necessary package installation (including Python and pip)
    echo "System update and installing necessary packages..." | tee -a "$LOG_FILE"
    sudo apt update && sudo apt upgrade -y >> "$LOG_FILE" 2>&1
    sudo apt -qy install curl git jq lz4 build-essential screen python3 python3-pip >> "$LOG_FILE" 2>&1

    # Install or upgrade Python packages
    echo "[Note] Upgrading pip3 and installing infernet-cli / infernet-client" | tee -a "$LOG_FILE"
    pip3 install --upgrade pip >> "$LOG_FILE" 2>&1
    pip3 install infernet-cli infernet-client >> "$LOG_FILE" 2>&1

    # Check if Docker is already installed
    echo "Checking if Docker is already installed..." | tee -a "$LOG_FILE"
    if command -v docker &> /dev/null; then
        echo " - Docker is already installed, skipping this step." | tee -a "$LOG_FILE"
    else
        echo " - Docker not installed, proceeding with installation..." | tee -a "$LOG_FILE"
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common >> "$LOG_FILE" 2>&1
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >> "$LOG_FILE" 2>&1
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >> "$LOG_FILE" 2>&1
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1
        sudo systemctl enable docker >> "$LOG_FILE" 2>&1
        sudo systemctl start docker >> "$LOG_FILE" 2>&1
        echo "Docker installation complete, current version:" | tee -a "$LOG_FILE"
        docker --version >> "$LOG_FILE" 2>&1
    fi

    # Check Docker Compose installation
    echo "Checking if Docker Compose is installed..." | tee -a "$LOG_FILE"
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo " - Docker Compose not installed, proceeding with installation..." | tee -a "$LOG_FILE"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
        sudo chmod +x /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    else
        echo " - Docker Compose is already installed, skipping this step." | tee -a "$LOG_FILE"
    fi

    echo "[Confirm] Docker Compose version:" | tee -a "$LOG_FILE"
    docker compose version >> "$LOG_FILE" 2>&1 || docker-compose version >> "$LOG_FILE" 2>&1

    # Install Foundry and set environment variables
    echo "Installing Foundry " | tee -a "$LOG_FILE"
    if pgrep anvil &>/dev/null; then
        echo "[Warning] anvil is running, shutting it down to update Foundry." | tee -a "$LOG_FILE"
        pkill anvil
        sleep 2
    fi

    cd ~ || exit 1
    mkdir -p foundry
    cd foundry
    curl -L https://foundry.paradigm.xyz | bash >> "$LOG_FILE" 2>&1
    $HOME/.foundry/bin/foundryup >> "$LOG_FILE" 2>&1
    if [[ ":$PATH:" != *":$HOME/.foundry/bin:"* ]]; then
        export PATH="$HOME/.foundry/bin:$PATH"
    fi

    echo "[Confirm] forge version:" | tee -a "$LOG_FILE"
    forge --version >> "$LOG_FILE" 2>&1 || {
        echo "[Error] Cannot find forge command, ~/.foundry/bin may not be in PATH or installation failed." | tee -a "$LOG_FILE"
        exit 1
    }

    if [ -f /usr/bin/forge ]; then
        echo "[Note] Removing /usr/bin/forge..." | tee -a "$LOG_FILE"
        sudo rm /usr/bin/forge
    fi

    echo "[Note] Foundry installation and environment variable configuration completed." | tee -a "$LOG_FILE"
    cd ~ || exit 1

    # Clone infernet-container-starter
    if [ -d "infernet-container-starter" ]; then
        echo "Directory infernet-container-starter already exists, deleting..." | tee -a "$LOG_FILE"
        rm -rf "infernet-container-starter"
    fi

    echo "Cloning infernet-container-starter..." | tee -a "$LOG_FILE"
    git clone https://github.com/ritual-net/infernet-container-starter >> "$LOG_FILE" 2>&1
    cd infernet-container-starter || { echo "[Error] Failed to enter directory" | tee -a "$LOG_FILE"; exit 1; }

    # Modify port mapping in deploy/docker-compose.yaml
    echo "Modifying port mappings in docker-compose.yaml..." | tee -a "$LOG_FILE"
    DOCKER_COMPOSE_FILE="deploy/docker-compose.yaml"
    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        # Change 4000 to 4005
        sed -i 's/0.0.0.0:4000:4000/0.0.0.0:4005:4000/' "$DOCKER_COMPOSE_FILE" >> "$LOG_FILE" 2>&1
        # Change 8545 to 8550
        sed -i 's/8545:3000/8550:3000/' "$DOCKER_COMPOSE_FILE" >> "$LOG_FILE" 2>&1
        echo "[Note] Port mappings changed to 0.0.0.0:4005:4000 and 8550:3000" | tee -a "$LOG_FILE"
    else
        echo "[Error] Could not find $DOCKER_COMPOSE_FILE, port modification failed" | tee -a "$LOG_FILE"
    fi

    # Pull Docker image
    echo "Pulling Docker image..." | tee -a "$LOG_FILE"
    docker pull ritualnetwork/hello-world-infernet:latest >> "$LOG_FILE" 2>&1

    # Deploy in a screen session with logging enabled
    echo "Checking if screen session 'ritual' exists..." | tee -a "$LOG_FILE"
    if screen -list | grep -q "ritual"; then
        echo "[Note] Found ritual session running, terminating..." | tee -a "$LOG_FILE"
        screen -S ritual -X quit
        sleep 1
    fi

    echo "Starting container deployment in screen -S ritual session, logging to /root/ritual_screen.log..." | tee -a "$LOG_FILE"
    screen -S ritual -L -Logfile /root/ritual_screen.log -dm bash -c 'project=hello-world make deploy-container; exec bash'
    echo "[Note] Deployment is running in background screen session (ritual), logs saved to /root/ritual_screen.log" | tee -a "$LOG_FILE"

    # User input (Private Key)
    echo "Configuring Ritual Node files..." | tee -a "$LOG_FILE"
    read -p "Please enter your Private Key (0x...): " PRIVATE_KEY
    echo "User input Private Key: [hidden]" >> "$LOG_FILE"

    # Default settings
    RPC_URL="https://mainnet.base.org/"
    RPC_URL_SUB="https://mainnet.base.org/"
    REGISTRY="0x3B1554f346DFe5c482Bb4BA31b880c1C18412170"
    SLEEP=3
    START_SUB_ID=160000
    BATCH_SIZE=50
    TRAIL_HEAD_BLOCKS=3
    INFERNET_VERSION="1.4.0"

    # Modify configuration files
    sed -i "s|\"registry_address\": \".*\"|\"registry_address\": \"$REGISTRY\"|" deploy/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"private_key\": \".*\"|\"private_key\": \"$PRIVATE_KEY\"|" deploy/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"sleep\": [0-9]*|\"sleep\": $SLEEP|" deploy/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"starting_sub_id\": [0-9]*|\"starting_sub_id\": $START_SUB_ID|" deploy/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"batch_size\": [0-9]*|\"batch_size\": $BATCH_SIZE|" deploy/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"trail_head_blocks\": [0-9]*|\"trail_head_blocks\": $TRAIL_HEAD_BLOCKS|" deploy/config.json >> "$LOG_FILE" 2>&1
    sed -i 's|"rpc_url": ".*"|"rpc_url": "https://mainnet.base.org"|' deploy/config.json >> "$LOG_FILE" 2>&1
    sed -i 's|"rpc_url": ".*"|"rpc_url": "https://mainnet.base.org"|' projects/hello-world/container/config.json >> "$LOG_FILE" 2>&1

    sed -i "s|\"registry_address\": \".*\"|\"registry_address\": \"$REGISTRY\"|" projects/hello-world/container/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"private_key\": \".*\"|\"private_key\": \"$PRIVATE_KEY\"|" projects/hello-world/container/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"sleep\": [0-9]*|\"sleep\": $SLEEP|" projects/hello-world/container/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"starting_sub_id\": [0-9]*|\"starting_sub_id\": $START_SUB_ID|" projects/hello-world/container/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"batch_size\": [0-9]*|\"batch_size\": $BATCH_SIZE|" projects/hello-world/container/config.json >> "$LOG_FILE" 2>&1
    sed -i "s|\"trail_head_blocks\": [0-9]*|\"trail_head_blocks\": $TRAIL_HEAD_BLOCKS|" projects/hello-world/container/config.json >> "$LOG_FILE" 2>&1

    sed -i "s|\(registry\s*=\s*\).*|\1$REGISTRY;|" projects/hello-world/contracts/script/Deploy.s.sol >> "$LOG_FILE" 2>&1
    sed -i "s|\(RPC_URL\s*=\s*\).*|\1\"$RPC_URL\";|" projects/hello-world/contracts/script/Deploy.s.sol >> "$LOG_FILE" 2>&1

    sed -i 's|ritualnetwork/infernet-node:[^"]*|ritualnetwork/infernet-node:latest|' deploy/docker-compose.yaml >> "$LOG_FILE" 2>&1

    MAKEFILE_PATH="projects/hello-world/contracts/Makefile"
    sed -i "s|^sender := .*|sender := $PRIVATE_KEY|" "$MAKEFILE_PATH" >> "$LOG_FILE" 2>&1
    sed -i "s|^RPC_URL := .*|RPC_URL := $RPC_URL|" "$MAKEFILE_PATH" >> "$LOG_FILE" 2>&1

    # Start containers and redirect logs
    cd ~/infernet-container-starter || exit 1
    echo "docker compose down & up..." | tee -a "$LOG_FILE"
    docker compose -f deploy/docker-compose.yaml down >> "$LOG_FILE" 2>&1
    docker compose -f deploy/docker-compose.yaml up -d >> "$LOG_FILE" 2>&1
    echo "[Note] Containers running in background (-d), logs will be redirected to $DOCKER_LOG_FILE" | tee -a "$LOG_FILE"

    # Output Docker logs to file and monitor size
    echo "Configuring Docker log output to $DOCKER_LOG_FILE, monitoring size (auto-clean if >500MB)..." | tee -a "$LOG_FILE"
    (
        while true; do
            docker logs -f infernet-node >> "$DOCKER_LOG_FILE" 2>&1 &
            LOG_PID=$!
            while kill -0 $LOG_PID 2>/dev/null; do
                LOG_SIZE=$(stat -c%s "$DOCKER_LOG_FILE" 2>/dev/null || echo 0)
                if [ "$LOG_SIZE" -ge $((500 * 1024 * 1024)) ]; then  # 500MB = 500 * 1024 * 1024 bytes
                    echo "[$DOCKER_LOG_FILE] Log size reached ${LOG_SIZE} bytes (>500MB), cleaning..." | tee -a "$LOG_FILE"
                    kill $LOG_PID 2>/dev/null
                    echo "Docker container logs - $(date)" > "$DOCKER_LOG_FILE"  # Clear and reinitialize
                    echo "[$DOCKER_LOG_FILE] Cleanup complete, new logs will continue." | tee -a "$LOG_FILE"
                    break
                fi
                sleep 60  # Check every minute
            done
            wait $LOG_PID 2>/dev/null
        done
    ) &

    # Install Forge libraries
    echo "Installing Forge (project dependencies)" | tee -a "$LOG_FILE"
    cd projects/hello-world/contracts || exit 1
    rm -rf lib/forge-std
    rm -rf lib/infernet-sdk
    forge install --no-commit foundry-rs/forge-std >> "$LOG_FILE" 2>&1
    forge install --no-commit ritual-net/infernet-sdk >> "$LOG_FILE" 2>&1

    # Restart containers
    echo "Restarting docker compose..." | tee -a "$LOG_FILE"
    cd ~/infernet-container-starter || exit 1
    docker compose -f deploy/docker-compose.yaml down >> "$LOG_FILE" 2>&1
    docker compose -f deploy/docker-compose.yaml up -d >> "$LOG_FILE" 2>&1
    echo "[Note] View infernet-node logs: tail -f $DOCKER_LOG_FILE" | tee -a "$LOG_FILE"

    # Deploy project contracts
    echo "Deploying project contracts..." | tee -a "$LOG_FILE"
    DEPLOY_OUTPUT=$(project=hello-world make deploy-contracts 2>&1)
    echo "$DEPLOY_OUTPUT" | tee -a "$LOG_FILE"

    NEW_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed SaysHello:\s+\K0x[0-9a-fA-F]{40}')
    if [ -z "$NEW_ADDR" ]; then
        echo "[Warning] New contract address not found. May need to manually update CallContract.s.sol." | tee -a "$LOG_FILE"
    else
        echo "[Note] Deployed SaysHello address: $NEW_ADDR" | tee -a "$LOG_FILE"
        sed -i "s|SaysGM saysGm = SaysGM(0x[0-9a-fA-F]\+);|SaysGM saysGm = SaysGM($NEW_ADDR);|" \
            projects/hello-world/contracts/script/CallContract.s.sol >> "$LOG_FILE" 2>&1
        echo "Executing call-contract with new address..." | tee -a "$LOG_FILE"
        project=hello-world make call-contract >> "$LOG_FILE" 2>&1
    fi

    echo "===== Ritual Node Installation Complete =====" | tee -a "$LOG_FILE"
    read -n 1 -s -r -p "Press any key to return to main menu..."
    main_menu
}

# View Ritual Node Logs
function view_logs() {
    echo "Viewing Ritual node logs (real-time output to $DOCKER_LOG_FILE)..." | tee -a "$LOG_FILE"
    tail -f "$DOCKER_LOG_FILE"
}

# Remove Ritual Node
function remove_ritual_node() {
    echo "Removing Ritual Node - $(date)" | tee -a "$LOG_FILE"

    # Stop and remove Docker containers
    echo "Stopping and removing Docker containers..." | tee -a "$LOG_FILE"
    cd /root/infernet-container-starter || echo "Directory does not exist, skipping docker compose down" | tee -a "$LOG_FILE"
    if [ -d "/root/infernet-container-starter" ]; then
        docker compose down >> "$LOG_FILE" 2>&1
    fi

    # Stop and remove containers one by one
    containers=(
        "infernet-node"
        "infernet-fluentbit"
        "infernet-redis"
        "infernet-anvil"
        "hello-world"
    )
    
    for container in "${containers[@]}"; do
        if [ "$(docker ps -aq -f name=$container)" ]; then
            echo "Stopping and removing $container..." | tee -a "$LOG_FILE"
            docker stop "$container" >> "$LOG_FILE" 2>&1
            docker rm "$container" >> "$LOG_FILE" 2>&1
        fi
    done

    # Remove related files
    echo "Removing related files..." | tee -a "$LOG_FILE"
    rm -rf ~/infernet-container-starter >> "$LOG_FILE" 2>&1

    # Remove Docker images
    echo "Removing Docker images..." | tee -a "$LOG_FILE"
    docker rmi -f ritualnetwork/hello-world-infernet:latest >> "$LOG_FILE" 2>&1
    docker rmi -f ritualnetwork/infernet-node:latest >> "$LOG_FILE" 2>&1
    docker rmi -f fluent/fluent-bit:3.1.4 >> "$LOG_FILE" 2>&1
    docker rmi -f redis:7.4.0 >> "$LOG_FILE" 2>&1
    docker rmi -f ritualnetwork/infernet-anvil:1.0.0 >> "$LOG_FILE" 2>&1

    # Clean up background log processes
    echo "Cleaning up background log processes..." | tee -a "$LOG_FILE"
    pkill -f "docker logs -f infernet-node" 2>/dev/null || echo "No background log processes to clean up" | tee -a "$LOG_FILE"

    echo "Ritual node has been successfully removed!" | tee -a "$LOG_FILE"
}

# Call Main Menu Function
main_menu
