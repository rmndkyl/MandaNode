#!/bin/bash

# Pipe Network Node Setup Script
set -e

# Display a logo
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Variables
INSTALL_DIR="/opt/dcdn"
NODE_REGISTRY_URL="https://rpc.pipedev.network"

# Colors for Output
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

# Prompt for URLs
echo -e "${CYAN}🔗 Please enter the Pipe Tool Binary URL:${RESET}"
read -rp "PIPE_URL: " PIPE_URL
echo -e "${CYAN}🔗 Please enter the DCDND Node Binary URL:${RESET}"
read -rp "DCDND_URL: " DCDND_URL

# Validate URLs
if [[ -z "$PIPE_URL" || -z "$DCDND_URL" ]]; then
    echo -e "${RED}❌ URLs cannot be empty. Please re-run the script and provide valid URLs.${RESET}"
    exit 1
fi

echo -e "${CYAN}💡 Starting Pipe Network Node Setup...${RESET}"

# Step 1: Create Directory
echo -e "${CYAN}📁 Creating directory: $INSTALL_DIR...${RESET}"
sudo mkdir -p $INSTALL_DIR

# Step 2: Download Pipe Tool Binary
echo -e "${CYAN}🔽 Downloading Pipe Tool Binary...${RESET}"
sudo curl -L "$PIPE_URL" -o "$INSTALL_DIR/pipe-tool"

# Step 3: Download Node Binary
echo -e "${CYAN}🔽 Downloading Node Binary...${RESET}"
sudo curl -L "$DCDND_URL" -o "$INSTALL_DIR/dcdnd"

# Step 4: Make Binary Executable
echo -e "${CYAN}🔧 Making binaries executable...${RESET}"
sudo chmod +x "$INSTALL_DIR/pipe-tool" "$INSTALL_DIR/dcdnd"

# Step 5: Log In to Generate Access Token
echo -e "${CYAN}🔑 Logging in to generate access token...${RESET}"
"$INSTALL_DIR/pipe-tool" login --node-registry-url="$NODE_REGISTRY_URL"

# Step 6: Generate Registration Token
echo -e "${CYAN}🔑 Generating registration token...${RESET}"
"$INSTALL_DIR/pipe-tool" generate-registration-token --node-registry-url="$NODE_REGISTRY_URL"

# Step 7: Create the Service File
SERVICE_FILE="/etc/systemd/system/dcdnd.service"
echo -e "${CYAN}🛠️ Creating systemd service file...${RESET}"
sudo tee $SERVICE_FILE > /dev/null <<EOL
[Unit]
Description=Pipe Network DCDND Node
After=network.target

[Service]
ExecStart=$INSTALL_DIR/dcdnd
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

# Step 8: Open Ports
echo -e "${CYAN}🔓 Opening required ports...${RESET}"
sudo ufw allow 8002/tcp
sudo ufw allow 8003/tcp

# Step 9: Start the Node
echo -e "${CYAN}🚀 Starting the node service...${RESET}"
sudo systemctl daemon-reload
sudo systemctl enable dcdnd
sudo systemctl start dcdnd

# Step 10: Check Node Status
echo -e "${CYAN}🔍 Checking node status...${RESET}"
"$INSTALL_DIR/pipe-tool" list-nodes --node-registry-url="$NODE_REGISTRY_URL"

# Step 11: Generate and Register Wallet
echo -e "${CYAN}💰 Generating and registering wallet...${RESET}"
"$INSTALL_DIR/pipe-tool" generate-wallet --node-registry-url="$NODE_REGISTRY_URL"
echo -e "${GREEN}⚠️ Save the wallet phrase and backup the keypair.json file!${RESET}"
"$INSTALL_DIR/pipe-tool" link-wallet --node-registry-url="$NODE_REGISTRY_URL"

echo -e "${GREEN}🎉 Setup Complete! Your Pipe Network Node is up and running.${RESET}"