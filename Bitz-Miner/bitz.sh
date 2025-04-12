#!/bin/bash

# Bitz Miner CLI Automated Installation Script (Supports base58 private keys, for English users)
# Environment: Ubuntu 22.04
# Features: Automatically installs dependencies, Solana CLI, Bitz, and configures the miner

# Show Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Set color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Bitz Miner CLI Automated Installation Script ===${NC}"
echo "This script helps you install and run Bitz Miner CLI on the Eclipse network."
echo "Please make sure you have an Eclipse wallet (e.g., Backpack) and a small amount of ETH ready."
echo -e "${RED}Note: This script must be run as root.${NC}"
echo "Press Enter to continue or Ctrl+C to exit..."
read

# Check for root permissions
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Please run with sudo: sudo bash bitz_setup.sh${NC}"
   exit 1
fi

# Check system environment
echo -e "${GREEN}Checking system environment...${NC}"
GLIBC_VERSION=$(ldd --version | head -n1 | awk '{print $NF}')
echo "GLIBC Version: $GLIBC_VERSION"

# Update system and install dependencies
echo -e "${GREEN}Step 1: Updating system and installing dependencies...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y screen curl nano build-essential python3 python3-pip
pip3 install base58
if [ $? -ne 0 ]; then
    echo -e "${RED}Dependency installation failed. Please check your network or disk space!${NC}"
    exit 1
fi

# Install Rust
echo -e "${GREEN}Step 2: Installing Rust...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustc --version
if [ $? -ne 0 ]; then
    echo -e "${RED}Rust installation failed. Please check your network!${NC}"
    exit 1
fi

# Install Solana CLI
echo -e "${GREEN}Step 3: Installing Solana CLI...${NC}"
sh -c "$(curl -sSfL https://release.anza.xyz/v1.18.25/install)"
export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
solana --version
if [ $? -ne 0 ]; then
    echo -e "${RED}Solana CLI installation failed. Please check your network or disk space!${NC}"
    exit 1
fi

# Configure Solana RPC
echo -e "${GREEN}Step 4: Configuring Solana RPC...${NC}"
solana config set --url https://mainnetbeta-rpc.eclipse.xyz/
echo "Solana RPC set to https://mainnetbeta-rpc.eclipse.xyz/"

# Wallet setup
echo -e "${GREEN}Step 5: Setting up Solana CLI wallet...${NC}"
echo "Would you like to use an existing wallet or create a new one?"
echo "1. Use an existing wallet (base58 or JSON private key)"
echo "2. Create a new wallet"
echo "Enter your choice (1 or 2):"
read WALLET_OPTION

if [ "$WALLET_OPTION" = "1" ]; then
    echo "Please enter your Eclipse wallet private key (base58 like 3QfGm... or JSON like [123,45,...]):"
    read -r PRIVATE_KEY
    if [[ "$PRIVATE_KEY" =~ ^\[.*\]$ ]]; then
        echo "Detected JSON array, importing private key..."
        echo "$PRIVATE_KEY" > ~/.config/solana/id.json
    else
        echo "Detected base58 format, converting to JSON array..."
        python3 -c "import base58; import json; key = base58.b58decode('$PRIVATE_KEY'); json_array = list(key); print(json.dumps(json_array))" > ~/.config/solana/id.json
        if [ $? -ne 0 ]; then
            echo -e "${RED}Private key conversion failed. Please check your base58 key!${NC}"
            exit 1
        fi
    fi
    echo "Verifying wallet address..."
    PUBKEY=$(solana-keygen pubkey)
    echo "Your wallet address: $PUBKEY"
    echo -e "${RED}Please ensure this address matches your actual wallet!${NC}"
else
    echo "Creating a new wallet..."
    solana-keygen new
    echo -e "${RED}IMPORTANT: Save your seed phrase and public key securely!${NC}"
fi

# Display wallet info
echo -e "${GREEN}Step 6: Displaying wallet info...${NC}"
solana config get
echo "Private key stored at ~/.config/solana/id.json:"
cat ~/.config/solana/id.json
echo -e "${RED}Make sure the private key is correct and the wallet has 0.01–0.05 ETH.${NC}"
echo "Press Enter to continue..."
read

# Install Bitz
echo -e "${GREEN}Step 7: Installing Bitz...${NC}"
cargo install bitz
if [ $? -ne 0 ]; then
    echo -e "${RED}Bitz installation failed. Please check Rust or network issues!${NC}"
    exit 1
fi

# Run Bitz Miner
echo -e "${GREEN}Step 8: Starting Bitz Miner...${NC}"
echo "Enter the number of CPU cores to use (default is 1, e.g., 4 or 8):"
read CPU_CORES
if [[ ! $CPU_CORES =~ ^[0-9]+$ ]]; then
    CPU_CORES=1
fi
screen -dmS bitz bash -c "bitz collect --cores $CPU_CORES"
echo -e "${GREEN}Bitz Miner started! Using $CPU_CORES core(s).${NC}"
echo "Management commands:"
echo "- View: screen -r bitz"
echo "- Stop: Ctrl+C (inside screen)"
echo "- Detach screen: Ctrl+A+D"
echo "- Terminate: screen -XS bitz quit"
echo "- Check account: bitz account"
echo "- Claim rewards: bitz claim"

echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo "Bitz Miner is now running in the background. For help, contact Contabo support or the Eclipse community."
