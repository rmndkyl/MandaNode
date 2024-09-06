#!/bin/bash

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Prompt for PRIVATE_KEY_LOCAL input
echo "0.1 ETH Testnet on each of these networks and BRN Token"
echo "Claim Faucet BRN Token: https://faucet.brn.t3rn.io/"
echo "Or Bridge to corresponding networks:https://bridge.t1rn.io"
echo "Arbitrum sepolia"
echo "Base sepolia"
echo "Blast sepolia"
echo "Optimism sepolia"
read -p "Enter your PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL

# Update and install dependencies
echo "Updating package list and upgrading installed packages..."
sudo apt update && sudo apt upgrade -y
if [ $? -ne 0 ]; then
  echo "Error updating and upgrading packages. Exiting..."
  exit 1
fi

echo "Installing required packages..."
sudo apt install curl wget tar build-essential jq unzip -y
if [ $? -ne 0 ]; then
  echo "Error installing packages. Exiting..."
  exit 1
fi

# Download the executor binary
echo "Downloading executor..."
wget https://github.com/t3rn/executor-release/releases/download/v0.20.0/executor-linux-v0.20.0.tar.gz
if [ $? -ne 0 ]; then
  echo "Error downloading executor. Exiting..."
  exit 1
fi

# Extract the binary
echo "Extracting executor..."
tar -xvf executor-linux-v0.20.0.tar.gz
if [ $? -ne 0 ]; then
  echo "Error extracting executor. Exiting..."
  exit 1
fi

# Create a systemd service file
echo "Creating executor service file..."
sudo tee /etc/systemd/system/executor.service > /dev/null <<EOF
[Unit]
Description=Executor Service
After=network.target

[Service]
User=root
WorkingDirectory=$(pwd)/executor/executor
Environment="NODE_ENV=testnet"
Environment="LOG_LEVEL=debug"
Environment="LOG_PRETTY=false"
Environment="PRIVATE_KEY_LOCAL=$PRIVATE_KEY_LOCAL"
Environment="ENABLED_NETWORKS=arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn"
ExecStart=$(pwd)/executor/executor/bin/executor
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
echo "Reloading systemd daemon and enabling executor service..."
sudo systemctl daemon-reload
if [ $? -ne 0 ]; then
  echo "Error reloading systemd daemon. Exiting..."
  exit 1
fi

sudo systemctl enable executor
if [ $? -ne 0 ]; then
  echo "Error enabling executor service. Exiting..."
  exit 1
fi

sudo systemctl start executor
if [ $? -ne 0 ]; then
  echo "Error starting executor service. Exiting..."
  exit 1
fi

echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
echo "============================ Dria Node Installation ===================================="
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"

echo "Executor started. Displaying logs..."
journalctl -u executor -f
