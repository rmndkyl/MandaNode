#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/ZenRock.sh"

# Function to deploy the script
function deploy_script() {
    echo "Executing deployment script..."

    # Update system package list and upgrade installed packages
    sudo apt update -y && sudo apt upgrade -y

    # Install required packages
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev \
    build-essential pkg-config ncdu tar clang bsdmainutils lsb-release \
    libssl-dev libreadline-dev libffi-dev jq gcc screen unzip lz4

    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        echo "Go is not installed, installing Go..."
        cd $HOME
        VER="1.23.1"
        wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
        rm "go$VER.linux-amd64.tar.gz"

        # Update environment variables
        [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
        echo "export PATH=\$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
        source $HOME/.bash_profile

        [ ! -d ~/go/bin ] && mkdir -p ~/go/bin
        echo "Go installation completed!"
    else
        echo "Go is already installed, version: $(go version)"
    fi

    # Set the node's name
    read -p "Please enter your node name (MONIKER): " MONIKER  # User input for node name

    # Download the binary
    mkdir -p $HOME/.zrchain/cosmovisor/genesis/bin
    wget -O $HOME/.zrchain/cosmovisor/genesis/bin/zenrockd https://releases.gardia.zenrocklabs.io/zenrockd-4.7.1
    chmod +x $HOME/.zrchain/cosmovisor/genesis/bin/zenrockd

    # Create symbolic links
    sudo ln -s $HOME/.zrchain/cosmovisor/genesis $HOME/.zrchain/cosmovisor/current -f
    sudo ln -s $HOME/.zrchain/cosmovisor/current/bin/zenrockd /usr/local/bin/zenrockd -f

    # Manage the node using Cosmovisor
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.6.0

    # Create the service
    sudo tee /etc/systemd/system/zenrock-testnet.service > /dev/null << EOF
[Unit]
Description=Zenrock node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.zrchain"
Environment="DAEMON_NAME=zenrockd"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.zrchain/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF

    # Reload the system daemon and enable the service
    sudo systemctl daemon-reload
    sudo systemctl enable zenrock-testnet.service

    # Configure the node
    zenrockd config set client chain-id gardia-2
    zenrockd config set client keyring-backend test
    zenrockd config set client node tcp://localhost:18257

    # Initialize the node
    zenrockd init $MONIKER --chain-id gardia-2

    # Download the genesis block and address book
    curl -Ls https://snapshots.kjnodes.com/zenrock-testnet/genesis.json > $HOME/.zrchain/config/genesis.json
    curl -Ls https://snapshots.kjnodes.com/zenrock-testnet/addrbook.json > $HOME/.zrchain/config/addrbook.json

    # Add seed node
    sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@zenrock-testnet.rpc.kjnodes.com:18259\"|" $HOME/.zrchain/config/config.toml

    # Set GAS
    sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0urock\"|" $HOME/.zrchain/config/app.toml

    # Set pruning parameters
    sed -i \
        -e 's|^pruning *=.*|pruning = "custom"|' \
        -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
        -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
        -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
        $HOME/.zrchain/config/app.toml

    # Adjust ports
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:18258\"%;" \
           -e "s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:18257\"%;" \
           -e "s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:18260\"%;" \
           -e "s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:18256\"%;" \
           -e "s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":18266\"%;" \
           $HOME/.zrchain/config/config.toml

    sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:18217\"%;" \
           -e "s%^address = \":8080\"%address = \":18280\"%;" \
           -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:18290\"%;" \
           -e "s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:18291\"%;" \
           -e "s%:8545%:18245%;" \
           -e "s%:8546%:18246%;" \
           -e "s%:6065%:18265%;" \
           $HOME/.zrchain/config/app.toml

    # Download snapshot and start node
    curl -L https://snapshots.kjnodes.com/zenrock-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.zrchain
    [[ -f $HOME/.zrchain/data/upgrade-info.json ]] && cp $HOME/.zrchain/data/upgrade-info.json $HOME/.zrchain/cosmovisor/genesis/upgrade-info.json

    # Start the service
    sudo systemctl start zenrock-testnet.service
}

# Function to create a wallet
function create_wallet() {
    echo "Creating wallet..."
    WALLET_NAME="${WALLET_NAME:-wallet}"  # Use 'wallet' as the default name if WALLET_NAME is not set
    zenrockd keys add "$WALLET_NAME"  # Create wallet using the wallet name
    echo "Wallet creation completed!"
}

# Function to import a wallet
function import_wallet() {
    echo "Importing wallet..."
    WALLET="${WALLET:-wallet}"  # Use 'wallet' as the default name if WALLET is not set
    zenrockd keys add "$WALLET" --recover  # Import wallet using the wallet name
    echo "Wallet import completed!"
}

# Function to view logs
function check_sync_status() {
    echo "Checking log status..."
    sudo journalctl -u zenrock-testnet.service -f --no-hostname -o cat
}

# Function to check sync height
function check_height_status() {
    local CONFIG_FILE="$HOME/.zrchain/config/config.toml"
    
    # Extract port number from config.toml
    echo "Extracting port number..."
    local PORT
    PORT=$(sed -n 's/.*laddr = "tcp:\/\/127.0.0.1:\([0-9]*\)".*/\1/p' "$CONFIG_FILE")

    # Print extracted port number
    echo "Extracted port number: $PORT"
    
    # Check if the port number was successfully extracted
    if [ -z "$PORT" ]; then
        echo "Failed to extract port number from the configuration file."
        read -n 1 -s -r -p "Press any key to return to the main menu..."
        return 1
    fi
    
    # Construct RPC URL
    local RPC_URL="http://localhost:${PORT}"
    
    echo "Checking sync status..."

    # Fetch status information
    local status
    status=$(curl -s "$RPC_URL/status")

    # Check if the curl command was successful
    if [ $? -ne 0 ]; then
        echo "Failed to connect to the local RPC server."
        read -n 1 -s -r -p "Press any key to return to the main menu..."
        return 1
    fi

    # Check if the JSON data is valid
    if ! echo "$status" | jq . > /dev/null 2>&1; then
        echo "Failed to parse JSON data."
        read -n 1 -s -r -p "Press any key to return to the main menu..."
        return 1
    fi

    # Extract information and format the output
    echo "=== Sync Status Information ==="

    # Latest block height
    local latest_block_height
    latest_block_height=$(echo "$status" | jq -r '.result.sync_info.latest_block_height')
    echo "Latest Block Height: $latest_block_height"

    # Latest block time
    local latest_block_time
    latest_block_time=$(echo "$status" | jq -r '.result.sync_info.latest_block_time')
    echo "Latest Block Time: $latest_block_time"

    # Local block height
    echo "Local Block Height: $latest_block_height"

    # Is catching up
    local catching_up
    catching_up=$(echo "$status" | jq -r '.result.sync_info.catching_up')
    if [ "$catching_up" = "true" ]; then
        echo "The node is syncing..."
    else
        echo "The node is fully synced."
    fi

    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Function to delete the node
function delete_node() {
    echo "Deleting node..."
    sudo systemctl stop zenrockd
    sudo systemctl disable zenrockd
    sudo rm -rf /etc/systemd/system/zenrockd.service
    sudo rm $(which zenrockd)
    sudo rm -rf $HOME/.zrchain
    sed -i "/ZENROCK_/d" $HOME/.bash_profile
    echo "Node deletion completed!"
}

# Function to create a validator
function create_validator() {
    echo "Creating validator..."
    cd $HOME

    # Get the user's input for Moniker
    read -p "Please enter your Moniker: " MONIKER  # Let the user input their Moniker

    # Create validator
    zenrockd tx validation create-validator <(cat <<EOF
{
  "pubkey": $(zenrockd comet show-validator),
  "amount": "1000000urock",
  "moniker": "$MONIKER",
  "details": "I love blockchain ❤️",
  "commission-rate": "0.05",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.05",
  "min-self-delegation": "1"
}
EOF
) \
--chain-id gardia-2 \
--from wallet \
--gas-adjustment 1.4 \
--gas auto \
--gas-prices 30urock \
-y

    echo "Validator creation completed!"
}

# Function to check balance
function check_balance() {
    echo "Checking balance..."
    zenrockd q bank balances $(zenrockd keys show wallet -a)
}

# Function to generate keys
function generate_keys() {
    echo "Generating keys..."
    cd $HOME
    rm -rf zenrock-validators
    git clone https://github.com/zenrocklabs/zenrock-validators
    read -p "Enter password for the keys: " key_pass
}

# Function to output ECDSA address
function output_ecdsa_address() {
    echo "Outputting ECDSA address..."
    mkdir -p $HOME/.zrchain/sidecar/bin
    mkdir -p $HOME/.zrchain/sidecar/keys
    cd $HOME/zenrock-validators/utils/keygen/ecdsa && go build
    cd $HOME/zenrock-validators/utils/keygen/bls && go build
    ecdsa_output_file=$HOME/.zrchain/sidecar/keys/ecdsa.key.json
    ecdsa_creation=$($HOME/zenrock-validators/utils/keygen/ecdsa/ecdsa --password $key_pass -output-file $ecdsa_output_file)
    ecdsa_address=$(echo "$ecdsa_creation" | grep "Public address" | cut -d: -f2)
    echo "Please save the ECDSA address and press any key to continue..."
    read -n 1
    bls_output_file=$HOME/.zrchain/sidecar/keys/bls.key.json
    $HOME/zenrock-validators/utils/keygen/bls/bls --password $key_pass -output-file $bls_output_file
    echo "ECDSA address: $ecdsa_address"
}

# Function to set the configuration
function set_operator_config() {
    echo "Setting configuration..."
    echo "Please deposit Holesky $ETH to the wallet, then type 'yes' to continue"
    read -p "Have you completed the deposit? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Please try again after completing the deposit."
        return
    fi

    read -p "Enter the Holesky testnet endpoint: " TESTNET_HOLESKY_ENDPOINT
    read -p "Enter the mainnet endpoint: " MAINNET_ENDPOINT
    read -p "Enter the Holesky testnet RPC URL: " ETH_RPC_URL
    read -p "Enter the Holesky testnet WebSocket URL: " ETH_WS_URL

    OPERATOR_VALIDATOR_ADDRESS_TBD=$(zenrockd keys show wallet --bech val -a)
    OPERATOR_ADDRESS_TBU=$ecdsa_address
    EIGEN_OPERATOR_CONFIG="$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
    ECDSA_KEY_PATH=$ecdsa_output_file
    BLS_KEY_PATH=$bls_output_file

    cp $HOME/zenrock-validators/configs/eigen_operator_config.yaml $HOME/.zrchain/sidecar/
    cp $HOME/zenrock-validators/configs/config.yaml $HOME/.zrchain/sidecar/

    sed -i "s|EIGEN_OPERATOR_CONFIG|$EIGEN_OPERATOR_CONFIG|g" "$HOME/.zrchain/sidecar/config.yaml"
    sed -i "s|TESTNET_HOLESKY_ENDPOINT|$TESTNET_HOLESKY_ENDPOINT|g" "$HOME/.zrchain/sidecar/config.yaml"
    sed -i "s|MAINNET_ENDPOINT|$MAINNET_ENDPOINT|g" "$HOME/.zrchain/sidecar/config.yaml"
    sed -i "s|OPERATOR_VALIDATOR_ADDRESS_TBD|$OPERATOR_VALIDATOR_ADDRESS_TBD|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
    sed -i "s|OPERATOR_ADDRESS_TBU|$OPERATOR_ADDRESS_TBU|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
    sed -i "s|ETH_RPC_URL|$ETH_RPC_URL|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
    sed -i "s|ETH_WS_URL|$ETH_WS_URL|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
    sed -i "s|ECDSA_KEY_PATH|$ECDSA_KEY_PATH|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"
    sed -i "s|BLS_KEY_PATH|$BLS_KEY_PATH|g" "$HOME/.zrchain/sidecar/eigen_operator_config.yaml"

    wget -O $HOME/.zrchain/sidecar/bin/validator_sidecar https://releases.gardia.zenrocklabs.io/validator_sidecar-1.2.3
    chmod +x $HOME/.zrchain/sidecar/bin/validator_sidecar

    sudo tee /etc/systemd/system/zenrock-testnet-sidecar.service > /dev/null <<EOF
[Unit]
Description=Validator Sidecar
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/.zrchain/sidecar/bin/validator_sidecar
Restart=on-failure
RestartSec=30
LimitNOFILE=65535
Environment="OPERATOR_BLS_KEY_PASSWORD=$key_pass"
Environment="OPERATOR_ECDSA_KEY_PASSWORD=$key_pass"
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable zenrock-testnet-sidecar.service
    sudo systemctl start zenrock-testnet-sidecar.service
}

# Backup sidecar configuration and keys
function backup_sidecar_config() {
    echo "Backing up sidecar configuration and keys..."
    backup_dir="$HOME/.zrchain/sidecar_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $backup_dir
    cp -r $HOME/.zrchain/sidecar/* $backup_dir
    echo "Backup completed. Backup path: $backup_dir"
}

# Check logs
function check_logs() {
    echo "Checking logs..."
    journalctl -fu zenrock-testnet-sidecar.service -o cat
}

# Main menu
function setup_operator() {
    echo "You can perform the following validator operations:"
    echo "1. Generate keys"
    echo "2. Output ECDSA address"
    echo "3. Set configuration"
    echo "4. Check logs"
    echo "5. Backup sidecar configuration and keys"
    read -p "Please choose an option (1-5): " OPTION

    case $OPTION in
        1) generate_keys ;;
        2) output_ecdsa_address ;;
        3) set_operator_config ;;
        4) check_logs ;;
        5) backup_sidecar_config ;;
        *) echo "Invalid option, please try again." ;;
    esac
}

# Function to delegate to a validator
function delegate_validator() {
    echo "Delegating to validator..."
    
    # Prompt the user to input the delegation amount, default is 1000000
    read -p "Enter the delegation amount (default 1000000): " amount
    amount=${amount:-1000000}  # Use default value if the user doesn't input one

    zenrockd tx validation delegate $(zenrockd keys show wallet --bech val -a) "${amount}urock" --from wallet --chain-id gardia-2 --gas-adjustment 1.4 --gas auto --gas-prices 25urock -y
    echo "Delegation complete!"
}

# Main menu function
function main_menu() {
    while true; do
        clear
		echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
		echo "============================ Zenrock Node Menu ================================="
		echo "Node community Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
		echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press ctrl+c on your keyboard."
        echo "Please choose an action:"
        echo "1) Deploy script"
        echo "2) Create wallet"
        echo "3) Import wallet"
        echo "4) Check node sync status"  # Keep the original command
        echo "5) Create validator"
        echo "6) Delegate to validator"
        echo "7) Check balance"
        echo "8) Setup operator functions"
        echo "9) Delete node"  # Command to delete the node
        echo "10) Check sync height"  # New command for checking sync height
        echo "11) Exit script"

        read -p "Enter your choice: " choice

        case $choice in
            1)
                deploy_script
                ;;
            2)
                create_wallet
                ;;
            3)
                import_wallet
                ;;
            4)
                check_sync_status  # Call the check node sync status function
                ;;
            5)
                create_validator
                ;;
            6)
                delegate_validator 
                ;;
            7)
                check_balance
                ;;
            8)
                setup_operator
                ;;
            9)
                delete_node  # Command to delete the node
                ;;
            10)
                check_hight_status  # Call the check sync height function
                ;;
            11)
                echo "Exiting script."
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac

        read -p "Press any key to continue..."
    done
}

# Run the main menu
main_menu