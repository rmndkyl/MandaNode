#!/bin/bash
set -e

# Define color codes for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Display Loader and Logo
echo -e "${BLUE}Loading setup files...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh

echo -e "${BLUE}Displaying LOGO...${NC}"
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 2

echo -e "${GREEN}Starting the automatic installation of Multiple Network nodes...${NC}"
sleep 3

# Detect system architecture
echo -e "${YELLOW}Checking system architecture...${NC}"
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
elif [[ "$ARCH" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
else
    echo -e "${RED}Unsupported system architecture: $ARCH${NC}"
    exit 1
fi
echo -e "${GREEN}System architecture detected: $ARCH${NC}"

# Download the client files
echo -e "${YELLOW}Downloading client files from $CLIENT_URL...${NC}"
wget $CLIENT_URL -O multipleforlinux.tar

# Extract the installation package
echo -e "${YELLOW}Extracting installation package...${NC}"
tar -xvf multipleforlinux.tar
rm -f multipleforlinux.tar

cd multipleforlinux

# Set necessary file permissions
echo -e "${YELLOW}Setting necessary file permissions...${NC}"
chmod +x multiple-cli
chmod +x multiple-node

# Configure system PATH
echo -e "${YELLOW}Configuring system PATH...${NC}"
echo "PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc

# Set directory permissions
echo -e "${YELLOW}Setting directory permissions...${NC}"
chmod -R 755 .

# Prompt user for account information
echo -e "${YELLOW}Please enter account information to bind the node:${NC}"
while [[ -z "$IDENTIFIER" ]]; do
    read -p "Enter your IDENTIFIER (account ID): " IDENTIFIER
    IDENTIFIER=$(echo "$IDENTIFIER" | xargs)  # Trim any leading/trailing spaces
    if [[ -z "$IDENTIFIER" ]]; then
        echo -e "${RED}IDENTIFIER cannot be empty. Please try again.${NC}"
    fi
done

while [[ -z "$PIN" ]]; do
    read -p "Enter your PIN (password): " PIN
    PIN=$(echo "$PIN" | xargs)  # Trim any leading/trailing spaces
    if [[ -z "$PIN" ]]; then
        echo -e "${RED}PIN cannot be empty. Please try again.${NC}"
    fi
done

echo "Debug: IDENTIFIER=$IDENTIFIER, PIN=$PIN"  # Debugging output for validation

# Start the node program
echo -e "${GREEN}Starting node program...${NC}"
nohup ./multiple-node > output.log 2>&1 &
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Failed to start the node program. Check the logs for details.${NC}"
    exit 1
fi
echo -e "${BLUE}Node is running. Logs are available at: $(pwd)/output.log${NC}"

# Bind account information
echo -e "${GREEN}Binding account information...${NC}"
if ! ./multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100; then
    echo -e "${RED}Account binding failed. Please check your inputs and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Account binding completed successfully.${NC}"

# Installation complete
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}For more help, run ./multiple-cli --help to view available commands.${NC}"
