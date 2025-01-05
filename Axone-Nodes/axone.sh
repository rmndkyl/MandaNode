#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Function to print colored text
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        print_color "$GREEN" "✓ Success"
    else
        print_color "$RED" "✗ Failed"
        exit 1
    fi
}

# Print banner
print_color "$BLUE" "======================================"
print_color "$BLUE" "     Axone Node Installation Script   "
print_color "$BLUE" "======================================"

# Check system requirements
print_color "$YELLOW" "\nChecking system requirements..."
RAM=$(free -m | awk '/^Mem:/{print $2}')
CPU_CORES=$(nproc)
DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')

if [ $RAM -lt 8192 ]; then
    print_color "$RED" "Warning: Minimum 8GB RAM recommended. Current: ${RAM}MB"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Prompt user for nodename and port prefix with validation
while true; do
    read -p "$(echo -e ${YELLOW}Enter the nodename: ${NC})" NODENAME
    if [[ ! -z "$NODENAME" ]]; then
        break
    fi
    print_color "$RED" "Nodename cannot be empty"
done

while true; do
    printf "${YELLOW}Enter the custom port prefix (e.g., 176): ${NC}"
    read PORT_PREFIX
    if [[ "$PORT_PREFIX" =~ ^[0-9]{3}$ ]]; then
        break
    fi
    print_color "$RED" "Please enter a valid 3-digit port prefix"
done

# Backup existing configuration if exists
if [ -d "$HOME/.axoned" ]; then
    BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
    print_color "$YELLOW" "\nBacking up existing configuration..."
    tar -czf "$HOME/.axoned_backup_${BACKUP_TIME}.tar.gz" "$HOME/.axoned" 2>/dev/null
    check_status
fi

# Install dependencies
print_color "$YELLOW" "\nInstalling dependencies..."
sudo apt update
sudo apt install -y curl git jq lz4 build-essential
check_status

# Install Go
print_color "$YELLOW" "\nInstalling Go..."
GO_VERSION="1.22.10"
sudo rm -rf /usr/local/go
curl -Ls "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh
echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile
source /etc/profile.d/golang.sh
source $HOME/.profile
check_status

# Clone and build project
print_color "$YELLOW" "\nCloning and building Axone..."
cd && rm -rf axoned
git clone https://github.com/axone-protocol/axoned
cd axoned
git checkout v10.0.0
make install
check_status

# Initialize directories and configuration
print_color "$YELLOW" "\nInitializing node configuration..."
mkdir -p $HOME/.axoned/cosmovisor/genesis/bin
ln -s $HOME/.axoned/cosmovisor/genesis $HOME/.axoned/cosmovisor/current -f
cp $(which axoned) $HOME/.axoned/cosmovisor/genesis/bin

# Configure node
axoned config chain-id axone-dentrite-1
axoned config keyring-backend test
axoned config node tcp://localhost:${PORT_PREFIX}57
axoned init "$NODENAME" --chain-id axone-dentrite-1

# Download genesis and addrbook
print_color "$YELLOW" "\nDownloading genesis and addrbook..."
curl -L https://snapshots-testnet.nodejumper.io/axone/genesis.json > $HOME/.axoned/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/axone/addrbook.json > $HOME/.axoned/config/addrbook.json
check_status

# Configure node
print_color "$YELLOW" "\nConfiguring node..."
# Set seeds
sed -i -e 's|^seeds *=.*|seeds = "3f472746f46493309650e5a033076689996c8881@axone-testnet.rpc.kjnodes.com:13659"|' $HOME/.axoned/config/config.toml

# Set minimum gas price
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.001uaxone"|' $HOME/.axoned/config/app.toml

# Set pruning
sed -i \
    -e 's|^pruning *=.*|pruning = "custom"|' \
    -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
    -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
    $HOME/.axoned/config/app.toml

# Enable prometheus
sed -i -e 's|^prometheus *=.*|prometheus = true|' $HOME/.axoned/config/config.toml

# Change ports
sed -i -e "s%:1317%:${PORT_PREFIX}17%; s%:8080%:${PORT_PREFIX}80%; s%:9090%:${PORT_PREFIX}90%; s%:9091%:${PORT_PREFIX}91%; s%:8545%:${PORT_PREFIX}45%; s%:8546%:${PORT_PREFIX}46%; s%:6065%:${PORT_PREFIX}65%" $HOME/.axoned/config/app.toml
sed -i -e "s%:26658%:${PORT_PREFIX}58%; s%:26657%:${PORT_PREFIX}57%; s%:6060%:${PORT_PREFIX}60%; s%:26656%:${PORT_PREFIX}56%; s%:26660%:${PORT_PREFIX}61%" $HOME/.axoned/config/config.toml

# Download chain snapshot
print_color "$YELLOW" "\nDownloading chain snapshot..."
curl "https://snapshots-testnet.nodejumper.io/axone/axone_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.axoned"
check_status

# Install Cosmovisor
print_color "$YELLOW" "\nInstalling Cosmovisor..."
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.7.0
check_status

# Create service file
print_color "$YELLOW" "\nCreating service file..."
sudo tee /etc/systemd/system/axone.service > /dev/null << EOF
[Unit]
Description=Axone node service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.axoned
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.axoned"
Environment="DAEMON_NAME=axoned"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"

[Install]
WantedBy=multi-user.target
EOF

# Start service
print_color "$YELLOW" "\nStarting Axone service..."
sudo systemctl daemon-reload
sudo systemctl enable axone.service
sudo systemctl start axone.service

print_color "$GREEN" "\n======================================"
print_color "$GREEN" "Installation completed successfully!"
print_color "$GREEN" "======================================"
print_color "$YELLOW" "\nTo check logs, run: sudo journalctl -u axone.service -f --no-hostname -o cat"
print_color "$YELLOW" "To check service status, run: sudo systemctl status axone.service"
