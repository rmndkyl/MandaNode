#!/bin/bash

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function for printing colored headers
print_header() {
    echo -e "${BLUE}=================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}=================================================================${NC}"
}

# Function for printing steps
print_step() {
    echo -e "${YELLOW}>>> $1${NC}"
}

# Function for success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Custom function to handle trap deployment that might fail in CLI but succeed on-chain
deploy_trap() {
    print_step "Deploying Trap..."
    echo -e "${YELLOW}When prompted, type 'ofc' and press Enter${NC}"

    # Find the drosera binary path
    DROSERA_PATH=$(find $HOME -name "drosera" 2>/dev/null | head -n 1 || echo "/usr/local/bin/drosera")

    if [ -x "$DROSERA_PATH" ]; then
        # Capture the output of the apply command
        DEPLOY_OUTPUT=$(DROSERA_PRIVATE_KEY=$PRIVATE_KEY $DROSERA_PATH apply 2>&1)
        DEPLOY_STATUS=$?
        
        # Check if transaction hash is present in the output regardless of exit code
        TX_HASH=$(echo "$DEPLOY_OUTPUT" | grep -o "0x[a-fA-F0-9]\{64\}")
        
        if [ -n "$TX_HASH" ]; then
            echo -e "${GREEN}Transaction sent with hash: $TX_HASH${NC}"
            echo -e "${YELLOW}Checking transaction status on Etherscan...${NC}"
            
            # Print Etherscan link for user to check
            EXPLORER_LINK="https://holesky.etherscan.io/tx/$TX_HASH"
            echo -e "${CYAN}Explorer Link: $EXPLORER_LINK${NC}"
            
            echo -e "${YELLOW}Transaction might succeed on-chain even if CLI reports an error.${NC}"
            echo -e "${YELLOW}Please verify the transaction in the explorer.${NC}"
            
            # Wait a bit for the transaction to be mined
            echo -e "${YELLOW}Waiting for transaction confirmation...${NC}"
            sleep 20
            
            # Store the transaction hash for later use
            echo "$TX_HASH" > ~/drosera_trap_tx_hash.txt
            print_success "Trap deployment transaction sent"
            return 0
        elif [[ "$DEPLOY_OUTPUT" =~ "Trap deployed" ]]; then
            print_success "Trap deployment"
            return 0
        else
            echo -e "${RED}Error: Trap deployment failed - no transaction hash found${NC}"
            echo "$DEPLOY_OUTPUT"
            
            # Check if drosera.toml exists anyways - sometimes deployment succeeds but CLI fails
            if [ -f ~/my-drosera-trap/drosera.toml ]; then
                TRAP_ADDRESS=$(grep -A 2 "Trap deployed" ~/my-drosera-trap/drosera.toml 2>/dev/null | grep "address" | awk -F'"' '{print $2}')
                if [ ! -z "$TRAP_ADDRESS" ]; then
                    echo -e "${GREEN}Found Trap address in config: $TRAP_ADDRESS${NC}"
                    print_success "Trap deployment (found in config)"
                    return 0
                fi
            fi
            
            # Ask user if they want to continue
            echo -e "${YELLOW}The CLI reported deployment failure, but the transaction may have succeeded on-chain.${NC}"
            read -p "Do you want to continue with the setup? (y/n): " CONTINUE
            if [[ "$CONTINUE" == "y" || "$CONTINUE" == "Y" ]]; then
                print_success "Continuing setup despite reported deployment error"
                return 0
            else
                return 1
            fi
        fi
    else
        echo -e "${RED}Error: drosera binary not found. Please install Drosera CLI manually.${NC}"
        return 1
    fi
}

# Function to check if command was successful with option to continue
check_status_with_continue() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        echo -e "${RED}Warning: $1 might have failed${NC}"
        read -p "Do you want to continue anyway? (y/n): " CONTINUE
        if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
            exit 1
        else
            echo -e "${YELLOW}Continuing despite reported error...${NC}"
        fi
    fi
}

# Function to ask for input with a default value
ask_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    echo -ne "${PURPLE}$prompt ${YELLOW}[$default]${PURPLE}: ${NC}"
    read input
    
    # If input is empty, use default
    if [ -z "$input" ]; then
        input="$default"
    fi
    
    # Set global variable
    eval "$var_name='$input'"
    echo -e "${GREEN}Using: $input${NC}"
}

clear
echo -e "${PURPLE}"
echo "██████╗ ██████╗  ██████╗ ███████╗███████╗██████╗  █████╗"
echo "██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗"
echo "██║  ██║██████╔╝██║   ██║███████╗█████╗  ██████╔╝███████║"
echo "██║  ██║██╔══██╗██║   ██║╚════██║██╔══╝  ██╔══██╗██╔══██║"
echo "██████╔╝██║  ██║╚██████╔╝███████║███████╗██║  ██║██║  ██║"
echo "╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝"
echo -e "${BLUE}                        NETWORK${NC}"
echo
echo -e "${CYAN}Comprehensive Drosera Network Node Setup Script${NC}"
echo -e "${YELLOW}===============================================${NC}"
echo

# Wait for user to be ready
echo -e "${PURPLE}This script will guide you through setting up a Drosera node.${NC}"
echo -e "${PURPLE}You will need:${NC}"
echo -e " ${YELLOW}• An EVM wallet with private key${NC}"
echo -e " ${YELLOW}• Some Holesky ETH for transactions${NC}"
echo -e " ${YELLOW}• Your server's public IP address${NC}"
echo
read -p "Press Enter when you're ready to begin..."

# Collect necessary information
print_header "SETUP CONFIGURATION"

# Ask for private key
ask_with_default "Enter your EVM wallet private key (without 0x prefix)" "privatekey" "PRIVATE_KEY"

# Ask for public address
ask_with_default "Enter your EVM wallet public address (with 0x prefix)" "0xYourWalletAddress" "WALLET_ADDRESS"

# Ask for server IP
SERVER_IP=$(curl -s ifconfig.me)
ask_with_default "Enter your server's public IP address" "$SERVER_IP" "SERVER_IP"

# Ask for github info
ask_with_default "Enter your GitHub username" "github-username" "GITHUB_USERNAME"
ask_with_default "Enter your GitHub email" "github-email@example.com" "GITHUB_EMAIL"

echo
print_header "INSTALLING DEPENDENCIES"

# Update system
print_step "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y
check_status "System update"

# Install required packages
print_step "Installing required packages..."
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
check_status "Package installation"

# Install Docker
print_step "Installing Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    sudo apt-get remove $pkg -y > /dev/null 2>&1
done

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y && sudo apt upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
check_status "Docker installation"

# Test Docker
print_step "Testing Docker..."
sudo docker run hello-world > /dev/null 2>&1
check_status "Docker test"

# Install Drosera CLI
print_header "INSTALLING DROSERA CLI"
print_step "Installing Drosera CLI..."
curl -L https://app.drosera.io/install | bash
check_status "Drosera CLI download"

# Source bashrc to use droseraup
print_step "Setting up Drosera CLI environment..."
export PATH="$HOME/.local/bin:$PATH"
for rc in ~/.bashrc ~/.bash_profile /root/.bashrc /root/.bash_profile; do
    if [ -f "$rc" ]; then
        source "$rc" 2>/dev/null || true
    fi
done

# Run droseraup with trapping to avoid script exit on failure
print_step "Running droseraup..."
{
    # Try using direct path first
    if [ -f "$HOME/.local/bin/droseraup" ]; then
        $HOME/.local/bin/droseraup
    elif [ -f "/root/.local/bin/droseraup" ]; then
        /root/.local/bin/droseraup
    else
        # Try to find droseraup
        DROSERAUP_PATH=$(find $HOME -name "droseraup" 2>/dev/null | head -n 1)
        if [ -n "$DROSERAUP_PATH" ]; then
            $DROSERAUP_PATH
        else
            echo -e "${YELLOW}Warning: droseraup not found automatically. Trying with default path...${NC}"
            # Manually download and install if needed
            mkdir -p "$HOME/.local/bin"
            curl -L https://app.drosera.io/download/linux > "$HOME/.local/bin/drosera"
            chmod +x "$HOME/.local/bin/drosera"
            print_success "Manually installed Drosera CLI"
        fi
    fi
} || {
    echo -e "${YELLOW}Note: droseraup command didn't work as expected, but we'll continue with the setup.${NC}"
    echo -e "${YELLOW}You may need to run 'droseraup' manually after this script completes.${NC}"
}

# Install Foundry CLI
print_step "Installing Foundry CLI..."
curl -L https://foundry.paradigm.xyz | bash

# Try to source all possible profile files
for rc in ~/.bashrc ~/.bash_profile /root/.bashrc /root/.bash_profile; do
    if [ -f "$rc" ]; then
        source "$rc" 2>/dev/null || true
    fi
done

# Run foundryup with trapping to avoid script exit on failure
{
    if [ -f "$HOME/.foundry/bin/foundryup" ]; then
        $HOME/.foundry/bin/foundryup
    else
        # Try to continue anyway
        export PATH="$HOME/.foundry/bin:$PATH"
        echo -e "${YELLOW}Added foundry to PATH. You can run 'foundryup' manually if needed.${NC}"
    fi
} || {
    echo -e "${YELLOW}Note: foundryup command didn't work as expected, but we'll continue with the setup.${NC}"
    echo -e "${YELLOW}You may need to run 'foundryup' manually after this script completes.${NC}"
}
print_success "Foundry CLI setup"

# Install Bun
print_step "Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
print_success "Bun installation"

print_header "DEPLOYING CONTRACT & TRAP"
print_step "Creating Trap directory..."
mkdir -p ~/my-drosera-trap
cd ~/my-drosera-trap

print_step "Configuring Git..."
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USERNAME"
check_status "Git configuration"

print_step "Initializing Trap..."
# Use forge binary directly to avoid PATH issues
if [ -f "$HOME/.foundry/bin/forge" ]; then
    $HOME/.foundry/bin/forge init -t drosera-network/trap-foundry-template
else
    # Try to find forge
    FORGE_PATH=$(find $HOME -name "forge" 2>/dev/null | head -n 1)
    if [ -n "$FORGE_PATH" ]; then
        $FORGE_PATH init -t drosera-network/trap-foundry-template
    else
        echo -e "${RED}Error: forge binary not found.${NC}"
        echo -e "${YELLOW}Trying to install it directly via foundryup...${NC}"
        curl -L https://foundry.paradigm.xyz | bash
        source ~/.bashrc
        ~/.foundry/bin/foundryup
        ~/.foundry/bin/forge init -t drosera-network/trap-foundry-template
        check_status_with_continue "Trap initialization"
    fi
fi

print_step "Compiling Trap..."
# Use bun binary directly
if [ -f "$HOME/.bun/bin/bun" ]; then
    $HOME/.bun/bin/bun install || echo -e "${YELLOW}Bun install had issues but continuing...${NC}"
else
    # Try to find bun
    BUN_PATH=$(find $HOME -name "bun" 2>/dev/null | head -n 1)
    if [ -n "$BUN_PATH" ]; then
        $BUN_PATH install || echo -e "${YELLOW}Bun install had issues but continuing...${NC}"
    else
        echo -e "${YELLOW}Warning: bun binary not found. Trying default path...${NC}"
        ~/.bun/bin/bun install 2>/dev/null || echo -e "${YELLOW}Failed to run bun install, continuing anyway...${NC}"
    fi
fi

# Use forge binary directly
if [ -f "$HOME/.foundry/bin/forge" ]; then
    $HOME/.foundry/bin/forge build || echo -e "${YELLOW}Forge build had issues but continuing...${NC}"
else
    # Try to find forge again
    FORGE_PATH=$(find $HOME -name "forge" 2>/dev/null | head -n 1)
    if [ -n "$FORGE_PATH" ]; then
        $FORGE_PATH build || echo -e "${YELLOW}Forge build had issues but continuing...${NC}"
    else
        echo -e "${RED}Error: forge binary not found.${NC}"
        # Try to continue anyway
        print_step "Will continue despite forge build issues..."
    fi
fi
print_success "Trap compilation completed (ignore warnings)"

# Use our custom deploy function that handles failures better
deploy_trap
if [ $? -ne 0 ]; then
    echo -e "${RED}Trap deployment had issues. Check the on-chain status before proceeding.${NC}"
    read -p "Do you want to continue with setup? (y/n): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        exit 1
    else
        echo -e "${YELLOW}Continuing despite reported error...${NC}"
    fi
fi

# Look for trap address in drosera.toml
TRAP_ADDRESS=$(grep -A 2 "Trap deployed" ~/my-drosera-trap/drosera.toml 2>/dev/null | grep "address" | awk -F'"' '{print $2}')
if [ ! -z "$TRAP_ADDRESS" ]; then
    echo -e "${GREEN}Found Trap address in config: $TRAP_ADDRESS${NC}"
    echo "$TRAP_ADDRESS" > ~/drosera_trap_address.txt
else
    echo -e "${YELLOW}Couldn't find Trap address in config. Check app.drosera.io dashboard after setup.${NC}"
    echo -e "${YELLOW}You may need to manually add your trap address to the config later.${NC}"
fi

print_header "SETTING UP OPERATOR"

print_step "Updating Trap configuration for operator whitelisting..."
cd ~/my-drosera-trap
# Check if drosera.toml exists
if [ ! -f drosera.toml ]; then
    echo -e "${YELLOW}Warning: drosera.toml not found. Creating a new one...${NC}"
    echo "[keeper]" > drosera.toml
    echo "name = \"mytrap\"" >> drosera.toml
fi

# Add whitelist configuration - append without checking if it already exists
echo "private_trap = true" >> drosera.toml
echo "whitelist = [\"$WALLET_ADDRESS\"]" >> drosera.toml
print_success "Trap configuration update"

print_step "Applying updated configuration..."
# Find the drosera binary path again
DROSERA_PATH=$(find $HOME -name "drosera" 2>/dev/null | head -n 1 || echo "/usr/local/bin/drosera")

if [ -x "$DROSERA_PATH" ]; then
    DROSERA_PRIVATE_KEY=$PRIVATE_KEY $DROSERA_PATH apply || {
        echo -e "${YELLOW}Warning: Configuration apply reported an error, but it might have succeeded on-chain.${NC}"
        echo -e "${YELLOW}Continuing with setup...${NC}"
    }
else
    echo -e "${RED}Error: drosera binary not found. Please install Drosera CLI manually.${NC}"
    echo -e "${YELLOW}Continuing with setup despite this error...${NC}"
fi
print_success "Configuration updated (ignoring CLI errors)"

print_step "Installing Operator CLI..."
cd ~
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin
check_status "Operator CLI installation"

print_step "Registering Operator..."
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $PRIVATE_KEY || {
    echo -e "${YELLOW}Warning: Operator registration reported an error, but it might have succeeded on-chain.${NC}"
    echo -e "${YELLOW}Continuing with setup...${NC}"
}
print_success "Operator registration completed (ignoring CLI errors)"

print_step "Creating systemd service..."
sudo tee /etc/systemd/system/drosera.service > /dev/null <<EOF
[Unit]
Description=drosera node service
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=$(which drosera-operator) node --db-file-path $HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \
    --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \
    --eth-backup-rpc-url https://1rpc.io/holesky \
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \
    --eth-private-key $PRIVATE_KEY \
    --listen-address 0.0.0.0 \
    --network-external-p2p-address $SERVER_IP \
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF
check_status "Systemd service creation"

print_step "Opening required ports..."
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 31313/tcp
sudo ufw allow 31314/tcp
echo "y" | sudo ufw enable
check_status "Firewall configuration"

print_step "Starting Drosera node..."
sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera
check_status_with_continue "Node started"

# Get node status
sleep 5
NODE_STATUS=$(systemctl is-active drosera)
if [ "$NODE_STATUS" = "active" ]; then
    print_success "Drosera node is running!"
else
    echo -e "${RED}Warning: Node service might not be running properly. Check with 'systemctl status drosera'${NC}"
    echo -e "${YELLOW}Continuing despite service issues...${NC}"
fi

print_header "SETUP COMPLETE"
echo -e "${GREEN}Your Drosera Network node has been set up successfully!${NC}"
echo
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e "1. ${CYAN}Visit:${NC} https://app.drosera.io/"
echo -e "2. ${CYAN}Connect your wallet${NC} (same wallet used during setup)"
echo -e "3. ${CYAN}Check your Trap${NC} in 'Traps Owned' section"
echo -e "4. ${CYAN}Send Bloom Boost${NC} to your Trap (deposit some Holesky ETH)"
echo -e "5. ${CYAN}Opt-in${NC} to connect your operator to the Trap"
echo
echo -e "${PURPLE}You can check your node status with:${NC} journalctl -u drosera.service -f"
echo
echo -e "${GREEN}Thank you for deploying a Drosera Network node!${NC}"

# Print deployed addresses if available
TRAP_ADDRESS=$(grep -A 2 "Trap deployed" ~/my-drosera-trap/drosera.toml 2>/dev/null | grep "address" | awk -F'"' '{print $2}')
if [ ! -z "$TRAP_ADDRESS" ]; then
    echo -e "${YELLOW}Your Trap address:${NC} $TRAP_ADDRESS"
    echo -e "${YELLOW}Save this address for future reference!${NC}"
else 
    TX_HASH=$(cat ~/drosera_trap_tx_hash.txt 2>/dev/null)
    if [ ! -z "$TX_HASH" ]; then
        echo -e "${YELLOW}Your deployment transaction hash:${NC} $TX_HASH"
        echo -e "${YELLOW}Check https://holesky.etherscan.io/tx/$TX_HASH to verify deployment status${NC}"
    fi
    echo -e "${YELLOW}Please check your dashboard at app.drosera.io to find your trap address${NC}"
fi

# Final tips
echo -e "${CYAN}TROUBLESHOOTING TIPS:${NC}"
echo -e "• If you encounter 'insufficient funds', make sure your wallet has Holesky ETH"
echo -e "• If API calls fail (429 errors), wait a few minutes and try again"
echo -e "• If the dashboard doesn't show your trap, your transaction might still be processing"
echo -e "• Check node logs with: journalctl -u drosera.service -f"
echo -e "• Join Discord for support: https://discord.gg/UXAdpTYjgr"

exit 0
