#!/bin/bash

# Cysic agent and prover installation paths
CYSIC_AGENT_PATH="$HOME/cysic-prover-agent"
CYSIC_PROVER_PATH="$HOME/cysic-aleo-prover"

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i', and then rerun this script."
    exit 1
fi

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Install necessary dependencies
function install_dependencies() {
    apt update && apt upgrade -y
    apt install curl wget -y
}

# Check and install Node.js and npm
function check_and_install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is installed, version: $(node -v)"
    else
        echo "Node.js is not installed, installing..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    if command -v npm > /dev/null 2>&1; then
        echo "npm is installed, version: $(npm -v)"
    else
        echo "npm is not installed, installing..."
        sudo apt-get install -y npm
    fi
}

# Check and install PM2
function check_and_install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is installed, version: $(pm2 -v)"
    else
        echo "PM2 is not installed, installing..."
        npm install pm2@latest -g
    fi
}

# Install agent server
function install_agent() {
    # Create agent directory
    rm -rf $CYSIC_AGENT_PATH
    mkdir -p $CYSIC_AGENT_PATH
    cd $CYSIC_AGENT_PATH

    # Download agent server
    wget https://github.com/cysic-labs/aleo-miner/releases/download/v0.1.15/cysic-prover-agent-v0.1.15.tgz
    tar -xf cysic-prover-agent-v0.1.15.tgz
    cd cysic-prover-agent-v0.1.15

    # Start agent server
    bash start.sh
    echo "Agent server has started."
}

# Install prover
function install_prover() {
    # Create prover directory
    rm -rf $CYSIC_PROVER_PATH
    mkdir -p $CYSIC_PROVER_PATH
    cd $CYSIC_PROVER_PATH

    # Download prover
    wget https://github.com/cysic-labs/aleo-miner/releases/download/v0.1.17/cysic-aleo-prover-v0.1.17.tgz
    tar -xf cysic-aleo-prover-v0.1.17.tgz 
    cd cysic-aleo-prover-v0.1.17

    # Get user reward address
    read -p "Please enter your reward claim address (Aleo address, if you don't have one, create it at https://www.provable.tools/account): " CLAIM_REWARD_ADDRESS
    
    # Get user's IP address
    read -p "Please enter the agent server's IP address and port (e.g., 192.168.1.100:9000): " PROVER_IP

    # Create start script
    cat <<EOF > start_prover.sh
#!/bin/bash
cd $CYSIC_PROVER_PATH/cysic-aleo-prover-v0.1.17
export LD_LIBRARY_PATH=./:\$LD_LIBRARY_PATH
./cysic-aleo-prover -l ./prover.log -a $PROVER_IP -w $CLAIM_REWARD_ADDRESS.$(curl -s ifconfig.me) -tls=true -p asia.aleopool.cysic.xyz:16699
EOF
    chmod +x start_prover.sh

    # Start prover using PM2
    pm2 start start_prover.sh --name "cysic-aleo-prover"
    echo "Prover has been installed and started."
}

# Upgrade the prover
function upgrade_prover() {
    # Download the new prover version
    echo "Upgrading the Cysic prover..."
    pm2 delete cysic-aleo-prover 
    rm -rf $CYSIC_PROVER_PATH
    mkdir -p $CYSIC_PROVER_PATH
    cd $CYSIC_PROVER_PATH

    wget https://github.com/cysic-labs/aleo-miner/releases/download/v0.1.18/cysic-aleo-prover-v0.1.18.tgz
    tar -xf cysic-aleo-prover-v0.1.18.tgz 
    cd cysic-aleo-prover-v0.1.18

    # Get the user's reward claim address
    read -p "Please enter your reward claim address (Aleo address, if you don't have one, create it at https://www.provable.tools/account): " CLAIM_REWARD_ADDRESS
    
    # Get the user's IP address
    read -p "Please enter the agent server's IP address and port (e.g., 192.168.1.100:9000): " PROVER_IP

    # Create the start script
    cat <<EOF > start_prover.sh
#!/bin/bash
cd $CYSIC_PROVER_PATH/cysic-aleo-prover-v0.1.18
export LD_LIBRARY_PATH=./:\$LD_LIBRARY_PATH
./cysic-aleo-prover -l ./prover.log -a $PROVER_IP -w $CLAIM_REWARD_ADDRESS.$(curl -s ifconfig.me) -tls=true -p asia.aleopool.cysic.xyz:16699
EOF
    chmod +x start_prover.sh

    # Start the prover using PM2
    pm2 start start_prover.sh --name "cysic-aleo-prover"
    echo "Prover has been upgraded and restarted."
}

# View prover logs
function check_prover_logs() {
    pm2 logs cysic-aleo-prover
}

# Stop the prover
function stop_prover() {
    pm2 stop cysic-aleo-prover
    echo "Prover has been stopped."
}

# Start the prover
function start_prover() {
    pm2 start cysic-aleo-prover
    echo "Prover has been started."
}

# Restart the prover
function restart_prover() {
    pm2 restart cysic-aleo-prover
    echo "Prover has been restarted."
}

# Main menu
function main_menu() {
    clear
	echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
	echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
	echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
	echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
	echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
	echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "========================= Cysic Agent and Prover Installation ======================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
    echo "Please select the operation you want to perform:"
    echo "1. Install Cysic Agent Server"
    echo "2. Install Cysic Prover"
    echo "3. Upgrade Cysic Prover"
    echo "4. View Prover Logs"
    echo "5. Stop Prover"
    echo "6. Start Prover"
    echo "7. Restart Prover"
    read -p "Enter your option (1-7): " OPTION
    case $OPTION in
    1) install_dependencies && check_and_install_nodejs_and_npm && check_and_install_pm2 && install_agent ;;
    2) install_dependencies && check_and_install_nodejs_and_npm && check_and_install_pm2 && install_prover ;;
    3) upgrade_prover ;;
    4) check_prover_logs ;;
    5) stop_prover ;;
    6) start_prover ;;
    7) restart_prover ;;
    *) echo "Invalid option." ;;
    esac
}

# Display the main menu
main_menu