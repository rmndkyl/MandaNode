#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Set variables
GENESIS_URL="https://raw.githubusercontent.com/rmndkyl/MandaNode/refs/heads/main/Memecore-Nodes/genesis.json"
GENESIS_FILE="./genesis.json"
NODE_DIR="./nodes/node1"
GETH_BUILD_DIR="./build/bin"
NETWORK_ID="43521"
BOOTNODES="enode://d511b4562fbf87ccf864bf8bf0536632594d5838fc2223cecdb35b30c3b281172c96201a8f9835164b1d8ec1e4d6b7542af917fab7aca891654dae50ce515bc0@18.138.235.45:30303,enode://9b5ae242c202d74db9ba8406d2e225f97bb79487eedba576f20fcf8d770488d6e5d0110b45bcaf01b107d4a429b6cfcb7dea4e07f8dbc9816e8409b0b147036e@18.143.193.46:30303"
PORT="30303"
HTTP_PORT="8545"
WS_PORT="8546"
LOG_FILE="./setup.log"

# Initialize log
echo -e "${GREEN}Node setup started at $(date)${NC}" > $LOG_FILE

# Function to log messages
log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# Step 1: Install dependencies (Go and C Compiler)
log "${YELLOW}Checking and installing dependencies...${NC}"
if ! command -v go &>/dev/null || ! go version | grep -q 'go1.19'; then
    sudo apt update >> $LOG_FILE 2>&1
    sudo apt install -y golang-1.19-go build-essential >> $LOG_FILE 2>&1
    sudo update-alternatives --install /usr/bin/go go /usr/lib/go-1.19/bin/go 1 >> $LOG_FILE 2>&1
    sudo update-alternatives --config go >> $LOG_FILE 2>&1
else
    log "${GREEN}Go 1.19 already installed.${NC}"
fi

# Step 2: Clone and Build Geth Source
log "${YELLOW}Cloning and building Geth from source...${NC}"
if git clone https://github.com/ethereum/go-ethereum.git >> $LOG_FILE 2>&1; then
    cd go-ethereum
    log "Removing toolchain directive from go.mod..."
    sed -i '/toolchain/d' go.mod >> $LOG_FILE 2>&1
    log "Running go mod tidy..."
    go mod tidy >> $LOG_FILE 2>&1
    log "Building Geth..."
    make geth >> $LOG_FILE 2>&1
else
    log "${RED}Error cloning Geth repository.${NC}"
    exit 1
fi

# Step 3: Download Genesis File
log "${YELLOW}Downloading genesis.json...${NC}"
curl -L $GENESIS_URL -o $GENESIS_FILE >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
    log "${RED}Error downloading genesis file${NC}"
    exit 1
fi

# Step 4: Initialize Geth Database
log "${YELLOW}Initializing Geth database...${NC}"
$GETH_BUILD_DIR/geth init --datadir $NODE_DIR $GENESIS_FILE >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
    log "${RED}Error initializing Geth database${NC}"
    exit 1
fi

# Step 5: Create or Import Account (Optional for RPC node)
echo -e "${YELLOW}Do you want to create a new account? (y/n)${NC}"
read create_account
if [ "$create_account" == "y" ]; then
    log "Creating new account..."
    $GETH_BUILD_DIR/geth --datadir $NODE_DIR account new >> $LOG_FILE 2>&1
    if [ $? -ne 0 ]; then
        log "${RED}Error creating new account${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Enter the path to your private key (e.g., ./privateKey.txt):${NC}"
    read private_key_path
    $GETH_BUILD_DIR/geth account import --datadir $NODE_DIR $private_key_path >> $LOG_FILE 2>&1
    if [ $? -ne 0 ]; then
        log "${RED}Error importing account${NC}"
        exit 1
    fi
fi

# Step 6: Start the Node (Validator or RPC)
echo -e "${YELLOW}Do you want to run a Validator node or RPC node? (Enter 'validator' or 'rpc')${NC}"
read node_type
if [ "$node_type" == "rpc" ]; then
    log "Starting RPC node..."
    $GETH_BUILD_DIR/geth \
        --networkid $NETWORK_ID \
        --gcmode archive \
        --datadir $NODE_DIR \
        --bootnodes $BOOTNODES \
        --port $PORT \
        --http.api eth,net,web3 \
        --http \
        --http.port $HTTP_PORT \
        --http.addr 0.0.0.0 \
        --http.vhosts "*" \
        --ws \
        --ws.port $WS_PORT \
        --ws.addr 0.0.0.0 \
        --ws.api eth,net,web3 >> $LOG_FILE 2>&1
elif [ "$node_type" == "validator" ]; then
    echo -e "${YELLOW}Enter your validator account address:${NC}"
    read validator_address
    echo -e "${YELLOW}Enter your validator account password file path:${NC}"
    read validator_password_file
    log "Starting Validator node..."
    $GETH_BUILD_DIR/geth \
        --mine --miner.etherbase=$validator_address \
        --unlock $validator_address \
        --password $validator_password_file \
        --networkid $NETWORK_ID \
        --gcmode archive \
        --datadir $NODE_DIR \
        --bootnodes $BOOTNODES \
        --port $PORT \
        --http.api eth,net,web3 \
        --http \
        --http.port $HTTP_PORT \
        --http.addr 0.0.0.0 \
        --http.vhosts "*" \
        --ws \
        --ws.port $WS_PORT \
        --ws.addr 0.0.0.0 \
        --ws.api eth,net,web3 >> $LOG_FILE 2>&1
else
    log "${RED}Invalid input. Please choose either 'rpc' or 'validator'.${NC}"
    exit 1
fi

log "${GREEN}Node setup completed at $(date)${NC}"
