#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Script save path
SCRIPT_PATH="$HOME/Quai.sh"

# Ensure the script is run as root
if [ "$(id -u)" -ne "0" ]; then
  echo "Please run this script as root or using sudo"
  exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "This script was created by the Big Gamble community hahaha, Twitter @ferdie_jhovie, open source and free, don't believe anyone charging for it."
        echo "If you have any questions, feel free to contact via Twitter, this is the only account."
        echo "A new Telegram group was created for easy communication: t.me/Sdohua"
        echo "================================================================"
        echo "To exit the script, press ctrl + C on the keyboard."
        echo "Please choose an option to execute:"
        echo "1) Deploy node"
        echo "2) View logs"
        echo "3) Deploy Stratum Proxy"
        echo "4) Start miner"
        echo "5) View mining logs"
        echo "6) Exit"

        read -p "Enter your choice: " choice

        case $choice in
            1)
                deploy_node
                ;;
            2)
                view_logs
                ;;
            3)
                deploy_stratum_proxy
                ;;
            4)
                start_miner
                ;;
            5)
                view_mining_logs
                ;;
            6)
                echo "Exiting script..."
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

# Check and install Docker
function check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed, installing Docker..."
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker installation complete!"
    else
        echo "Docker is already installed, version as follows:"
        docker --version
    fi
}

# Check if CUDA is installed
function check_cuda() {
    if ! dpkg -l | grep -q "cuda-12-6"; then
        echo "CUDA 12.6 is not installed, installing..."
        # Add commands to install CUDA here
        echo "Please manually install CUDA 12.6 or ensure it is installed."
    else
        echo "CUDA 12.6 is installed."
    fi
}

# Deploy node function
function deploy_node() {
    # Install necessary dependencies
    echo "Installing necessary dependencies..."
    sudo apt update
    sudo apt install -y git make g++

    # Check Docker
    check_docker

    # Create directory and navigate to it
    mkdir -p /data/ && cd /data/

    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        echo "Go is not installed, downloading and installing the latest version..."

        # Download and install the latest version of Go
        wget -q https://golang.org/dl/go1.23.2.linux-amd64.tar.gz -O go.tar.gz
        sudo tar -C /usr/local -xzf go.tar.gz
        rm go.tar.gz

        # Update PATH
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc

        echo "Go installation complete!"
    else
        echo "Go is already installed, version as follows:"
    fi

    # Finally, check Go version
    go version

    # Clone Git repository
    echo "Cloning Git repository..."
    git clone https://github.com/dominant-strategies/go-quai

    # Switch to go-quai directory
    cd go-quai

    # Checkout to the specified version
    git checkout vX.XX.X

    # Build the project
    make go-quai

    # Prompt the user to input addresses
    read -p 'Enter Quai address: ' quai_address
    read -p 'Enter Qi address: ' qi_address

    # Start Docker container
    docker run -d --name quai-node \
        -e QUAI_ADDRESS="$quai_address" \
        -e QI_ADDRESS="$qi_address" \
        -v /data/go-quai:/data/go-quai \
        -w /data/go-quai \
        golang:latest \
        ./build/bin/go-quai start --node.slices '[0 0]' --node.coinbases "$quai_address,$qi_address"
}

# View logs function
function view_logs() {
    echo "Viewing node logs..."
    tail -f /data/go-quai/nodelogs/global.log
}

# Deploy Stratum Proxy function
function deploy_stratum_proxy() {
    echo "Deploying Stratum Proxy..."
    cd /data/
    git clone https://github.com/dominant-strategies/go-quai-stratum
    cd go-quai-stratum

    # Checkout to the specified version
    git checkout v0.XX.X

    # Copy configuration file
    cp config/config.example.json config/config.json

    # Switch to go-quai-stratum directory
    cd /data/go-quai-stratum

    # Build Stratum Proxy
    make go-quai-stratum

    # Run Stratum Proxy
    docker run -d --name quai-stratum \
        -v /data/go-quai-stratum:/data/go-quai-stratum \
        -w /data/go-quai-stratum \
        golang:latest \
        ./build/bin/go-quai-stratum --region=cyprus --zone=cyprus1 --stratum=6666

    echo "Stratum Proxy deployed successfully!"
}

# Start miner function
function start_miner() {
    # Update package manager and install NVIDIA drivers
    echo "Updating package manager and installing NVIDIA drivers..."
    sudo apt update
    sudo apt install nvidia-driver-560 -y

    # Verify successful installation
    echo "Verifying NVIDIA driver installation..."
    nvidia-smi

    check_cuda

    # Prompt the user to input node IP address
    read -p 'Enter the IP address of the node: ' node_ip

    # Download and install miner
    echo "Downloading miner deployment script..."
    wget https://raw.githubusercontent.com/dominant-strategies/quai-gpu-miner/refs/heads/main/deploy_miner.sh

    # Change permissions and execute
    sudo chmod +x deploy_miner.sh
    sudo ./deploy_miner.sh

    # Download and set executable permissions for the miner
    wget -P /usr/local/bin/ https://github.com/dominant-strategies/quai-gpu-miner/releases/download/v0.2.0/quai-gpu-miner
    chmod +x /usr/local/bin/quai-gpu-miner

    # Run miner using Docker
    echo "Starting miner..."
    docker run -d --name quai-gpu-miner \
        -v /var/log:/var/log \
        quai-gpu-miner -U -P stratum://$node_ip:3333 2>&1 | tee /var/log/miner.log

    echo "Miner started successfully!"
}

# View mining logs function
function view_mining_logs() {
    echo "Viewing mining logs..."
    grep Accepted /var/log/miner.log
}

# Start main menu
main_menu