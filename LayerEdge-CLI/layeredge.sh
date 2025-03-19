#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Display animations and logo
echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -f logo.sh loader.sh
sleep 2

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}=====================================================================${NC}"
    echo -e "${YELLOW}>>> $1 ${NC}"
    echo -e "${BLUE}=====================================================================${NC}\n"
}

# Function to check if a command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 completed successfully${NC}"
    else
        echo -e "${RED}✗ $1 failed. Exiting...${NC}"
        exit 1
    fi
}

# Create .env file
create_env_file() {
    print_section "Creating .env file"
    
    cat > .env << EOL
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='cli-node-private-key'
EOL
    
    echo -e "${CYAN}Created .env file with default settings.${NC}"
    echo -e "${YELLOW}IMPORTANT: Please update the PRIVATE_KEY value in .env file before running the application!${NC}"
}

# Main script starts here
echo -e "${PURPLE}"
cat << "EOF"
 _                           _____    _            
| |                         |  ___|  | |           
| |     __ _ _   _  ___ _ __| |__  __| | __ _  ___ 
| |    / _` | | | |/ _ \ '__|  __|/ _` |/ _` |/ _ \
| |___| (_| | |_| |  __/ |  | |__| (_| | (_| |  __/
\_____/\__,_|\__, |\___|_|  \____/\__,_|\__, |\___|
              __/ |                      __/ |     
             |___/                      |___/      

                            From: LayerAirdrop
EOF
echo -e "${NC}"

# Check if script is running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Install dependencies
print_section "Installing Dependencies"
apt update -y
apt install wget curl git build-essential pkg-config libssl-dev -y
check_success "Dependency installation"

# Install Go
print_section "Installing Go 1.24"
wget -q https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
rm go1.24.1.linux-amd64.tar.gz

# Set up Go environment variables for all users
cat > /etc/profile.d/go.sh << 'EOL'
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOL

# Set environment variables for current session
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Verify Go installation
go version
check_success "Go installation"

# Install Rust and RiscZero (Fixed for current shell session)
print_section "Installing Rust and RiscZero"

# Install Rust
if ! command -v rustc &> /dev/null; then
    echo -e "${CYAN}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    check_success "Rust installation"
else
    echo -e "${CYAN}Rust is already installed.${NC}"
    source "$HOME/.cargo/env"
fi

# Install RiscZero directly
echo -e "${CYAN}Installing RiscZero...${NC}"
curl -L https://risczero.com/install | bash
echo 'export PATH=$PATH:$HOME/.risc0/bin' >> "$HOME/.bashrc"
export PATH=$PATH:$HOME/.risc0/bin
check_success "RiscZero curl installation"

# Verify rzup is accessible
if [ -f "$HOME/.risc0/bin/rzup" ]; then
    echo -e "${CYAN}Running rzup install...${NC}"
    $HOME/.risc0/bin/rzup install
    check_success "RiscZero rzup install"
else
    echo -e "${RED}Could not find rzup binary. Trying alternative installation...${NC}"
    
    # Try an alternative approach
    cd $HOME
    git clone https://github.com/risc0/risc0.git
    cd risc0
    cargo install --path tools/rzup
    rzup install
    check_success "RiscZero alternative installation"
fi

# Clone the repository
print_section "Cloning the LayerEdge Light Node Repository"
cd $HOME
if [ -d "$HOME/light-node" ]; then
    echo -e "${CYAN}Light-node repository already exists, updating...${NC}"
    cd $HOME/light-node
    git pull
else
    git clone https://github.com/Layer-Edge/light-node
fi
check_success "Repository cloning"

# Build RISC0 merkle service
print_section "Building RISC0 Merkle Service"
cd $HOME/light-node/risc0-merkle-service
cargo build
check_success "RISC0 merkle service build"

# Build light-node
print_section "Building Light Node"
cd $HOME/light-node
go build
check_success "Light Node build"

# Create systemd services
print_section "Setting up systemd services"

# RISC0 Merkle Service systemd unit
cat > /etc/systemd/system/risc0-merkle.service << EOL
[Unit]
Description=RISC0 Merkle Service
After=network.target

[Service]
User=root
WorkingDirectory=$HOME/light-node/risc0-merkle-service
ExecStart=$HOME/light-node/risc0-merkle-service/target/debug/risc0-merkle-service
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOL

# Light Node systemd unit
cat > /etc/systemd/system/layeredge-node.service << EOL
[Unit]
Description=LayerEdge Light Node
After=network.target risc0-merkle.service
Requires=risc0-merkle.service

[Service]
User=root
WorkingDirectory=$HOME/light-node
ExecStart=$HOME/light-node/light-node
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOL

# Create .env file
cd $HOME/light-node
create_env_file

# Enable and start services
systemctl daemon-reload
systemctl enable risc0-merkle.service
systemctl enable layeredge-node.service

# Final instructions
print_section "Installation Complete!"
echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo -e "1. ${CYAN}Update the PRIVATE_KEY in ${HOME}/light-node/.env${NC}"
echo -e "2. ${CYAN}Start the services after updating the configuration:${NC}"
echo -e "   ${GREEN}sudo systemctl start risc0-merkle.service${NC}"
echo -e "   ${GREEN}sudo systemctl start layeredge-node.service${NC}"
echo -e ""
echo -e "3. ${CYAN}Check service status:${NC}"
echo -e "   ${GREEN}sudo systemctl status risc0-merkle.service${NC}"
echo -e "   ${GREEN}sudo systemctl status layeredge-node.service${NC}"
echo -e ""
echo -e "${PURPLE}Thank you for installing LayerEdge Light Node!${NC}"
