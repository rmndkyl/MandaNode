#!/bin/bash

# Color codes
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Version variables
GO_VERSION="1.22.3"
FIAMMA_VERSION="v1.0.0"
CHAIN_ID="fiamma-testnet-1"

# Function to print colored text
print_color() {
    printf "%b%s%b\n" "${1}" "${2}" "${NC}"
}

# Function to print section headers
print_header() {
    echo "============================================================"
    print_color $BLUE "🔷 $1"
    echo "============================================================"
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ $1 completed successfully!"
    else
        print_color $RED "❌ $1 failed!"
        exit 1
    fi
}

# Function to check if fiammad is installed
check_node_installation() {
    if ! command -v fiammad &> /dev/null; then
        print_color $RED "❌ Fiamma node is not installed! Please install the node first."
        return 1
    fi
    return 0
}

# Version variables
GO_VERSION="1.22.3"
FIAMMA_VERSION="v1.0.0"

print_header "Starting Fiamma Node Installation"

# Download and execute animation scripts if they don't exist
if [ ! -f "loader.sh" ]; then
    wget -q -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh
    chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
fi

if [ ! -f "logo.sh" ]; then
    wget -q -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh
    chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
fi

rm -rf loader.sh logo.sh
sleep 2

check_sync_status() {
    print_color $YELLOW "Checking sync status..."
    
    # Set up trap for Ctrl+C
    trap 'print_color $YELLOW "Returning to main menu..."; return' INT
    
    while true; do
        local_height=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height' 2>/dev/null)
        network_height=$(curl -s https://fiamma-testnet-rpc.itrocket.net/status | jq -r '.result.sync_info.latest_block_height' 2>/dev/null)

        if ! [[ "$local_height" =~ ^[0-9]+$ ]] || ! [[ "$network_height" =~ ^[0-9]+$ ]]; then
            print_color $RED "Error: Unable to fetch block height data. Retrying..."
            sleep 5
            continue
        fi

        blocks_left=$((network_height - local_height))
        if [ "$blocks_left" -lt 0 ]; then
            blocks_left=0
        fi

        print_color $YELLOW "Node Height: $local_height | Network Height: $network_height | Blocks Left: $blocks_left"
        sleep 5
    done
}

while true; do
    print_header "Fiamma Node Installation"
    print_header "Main Menu"
    options=(
        "📥 Install Node"
        "👛 Create Wallet"
        "💼 Import Wallet"
        "🏗️ Create Validator"
        "📋 Check Node Status"
        "🔄 Check Sync Status"  # Add this line
        "💰 Check Balance"
        "📜 View Logs"
        "❌ Delete Node"
        "🚪 Exit"
    )

    
    PS3=$'\e[1;33mPlease select an option: \e[0m'
    select opt in "${options[@]}"; do
        case $opt in
            "📥 Install Node")
                print_header "Starting Installation Process"

                # Set variables
                if [ ! $NODENAME ]; then
                    read -p "$(print_color $YELLOW "Enter node name: ")" NODENAME
                    echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
                fi
                if [ ! $WALLET ]; then
                    echo "export WALLET=wallet" >> $HOME/.bash_profile
                fi
                echo "export FIAMMA_CHAIN_ID=fiamma-testnet-1" >> $HOME/.bash_profile
                source $HOME/.bash_profile

                # Update system
                print_color $YELLOW "Updating system packages..."
                sudo apt update && sudo apt upgrade -y
                check_status "System update"

                # Install dependencies
                print_color $YELLOW "Installing required packages..."
                sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop \
                    nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip lz4
                check_status "Package installation"

                # Install Go
                print_color $YELLOW "Installing Go ${GO_VERSION}..."
                wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
                sudo rm -rf /usr/local/go
                sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
                rm "go${GO_VERSION}.linux-amd64.tar.gz"
                echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
                source ~/.bash_profile
                check_status "Go installation"

                # Download binary
                cd $HOME && rm -rf fiamma
                git clone https://github.com/fiamma-chain/fiamma.git
                cd fiamma
                git checkout $FIAMMA_VERSION
                make install
                check_status "Binary installation"

                # Config & Init
                print_color $YELLOW "Configuring and initializing node..."
                fiammad init "$NODENAME" --chain-id "$FIAMMA_CHAIN_ID" --default-denom ufia
                fiammad config chain-id "$FIAMMA_CHAIN_ID"
                fiammad config keyring-backend test
                fiammad config node tcp://localhost:26657
                check_status "Node initialization"

                # Download genesis and addrbook
                wget -O $HOME/.fiamma/config/genesis.json https://server-5.itrocket.net/testnet/fiamma/genesis.json
                wget -O $HOME/.fiamma/config/addrbook.json https://server-5.itrocket.net/testnet/fiamma/addrbook.json
                check_status "Genesis download"

                print_color $YELLOW "Downloading and applying snapshot..."
                cp $HOME/.fiamma/data/priv_validator_state.json $HOME/.fiamma/priv_validator_state.json.backup 2>/dev/null || true
                rm -rf $HOME/.fiamma/data
                curl https://server-5.itrocket.net/testnet/fiamma/fiamma_2024-12-10_543036_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.fiamma
                if [ -f $HOME/.fiamma/priv_validator_state.json.backup ]; then
                    mv $HOME/.fiamma/priv_validator_state.json.backup $HOME/.fiamma/data/priv_validator_state.json
                fi
                check_status "Snapshot installation"

                # Set minimum gas price
                sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00001ufia\"|" $HOME/.fiamma/config/app.toml

                # Set peers and seeds
                SEEDS="1e8777199f1edb3a35937e653b0bb68422f3c931@fiamma-testnet-seed.itrocket.net:50656"
                PEERS="16b7389e724cc440b2f8a2a0f6b4c495851934ff@fiamma-testnet-peer.itrocket.net:49656,fd8af2419e8a1cd9198066809465cb11c63b5428@148.251.128.49:29656,2b706253a0261645233a8635ccc9c0b85d1d5e7a@62.169.26.93:26656,4f5efac1afd504f3b16fa79199965dfbc45880e3@[2a03:cfc0:8000:13::b910:27be]:14356,db875e2cb29c22752486422244c006ab13734149@46.4.91.76:29556"
                sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.fiamma/config/config.toml

                # Create service
                sudo tee /etc/systemd/system/fiammad.service > /dev/null << EOF
[Unit]
Description=Fiamma node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which fiammad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

                # Start service
                sudo systemctl daemon-reload
                sudo systemctl enable fiammad
                sudo systemctl start fiammad
                check_status "Service creation and startup"

                print_header "Installation Complete!"
                print_color $GREEN "Your Fiamma node has been successfully installed!"
                break
                ;;
            "👛 Create Wallet")
                print_header "Creating New Wallet"
                
                fiammad keys add $WALLET
                
                print_color $GREEN "Save your address and mnemonic phrase safely!"
                FIAMMA_WALLET_ADDRESS=$(fiammad keys show $WALLET -a)
                FIAMMA_VALOPER_ADDRESS=$(fiammad keys show $WALLET --bech val -a)
                
                echo 'export FIAMMA_WALLET_ADDRESS='${FIAMMA_WALLET_ADDRESS} >> $HOME/.bash_profile
                echo 'export FIAMMA_VALOPER_ADDRESS='${FIAMMA_VALOPER_ADDRESS} >> $HOME/.bash_profile
                source $HOME/.bash_profile
                
                print_color $YELLOW "Wallet Address: ${FIAMMA_WALLET_ADDRESS}"
                print_color $YELLOW "Validator Address: ${FIAMMA_VALOPER_ADDRESS}"
                break
                ;;
            "💼 Import Wallet")
                print_header "Import Existing Wallet"
                
                read -p "Enter wallet name: " wallet_name
                print_color $YELLOW "Please enter your mnemonic phrase:"
                fiammad keys add $wallet_name --recover
                
                if [ $? -eq 0 ]; then
                    FIAMMA_WALLET_ADDRESS=$(fiammad keys show $wallet_name -a)
                    FIAMMA_VALOPER_ADDRESS=$(fiammad keys show $wallet_name --bech val -a)
                    
                    echo "export FIAMMA_WALLET_ADDRESS=${FIAMMA_WALLET_ADDRESS}" >> $HOME/.bash_profile
                    echo "export FIAMMA_VALOPER_ADDRESS=${FIAMMA_VALOPER_ADDRESS}" >> $HOME/.bash_profile
                    source $HOME/.bash_profile
                    
                    print_color $GREEN "Wallet imported successfully!"
                    print_color $YELLOW "Wallet Address: ${FIAMMA_WALLET_ADDRESS}"
                    print_color $YELLOW "Validator Address: ${FIAMMA_VALOPER_ADDRESS}"
                else
                    print_color $RED "Failed to import wallet!"
                fi
                break
                ;;
            "🏗️ Create Validator")
                print_header "Creating Validator"

                # Check if wallet exists by attempting to get its address
                if ! fiammad keys show "$WALLET" &>/dev/null; then
                    print_color $RED "Wallet '$WALLET' not found! Please create or import a wallet first."
                    break
                fi

                # Check if node is synced
                if [[ $(fiammad status 2>&1 | jq .SyncInfo.catching_up) == true ]]; then
                    print_color $RED "Node is still syncing. Please wait until it's fully synced."
                    break
                fi

                # Check wallet balance before creating validator
                BALANCE=$(fiammad query bank balances $(fiammad keys show $WALLET -a) -o json | jq -r '.balances[] | select(.denom=="ufia") .amount // "0"')
                if [ "$BALANCE" -lt 1000000 ]; then
                    print_color $RED "Insufficient balance. You need at least 1 FIA (1000000 ufia) to create a validator."
                    break
                fi

                # Create validator configuration file
                cat > $HOME/validator.json << EOF
{
    "pubkey": $(fiammad tendermint show-validator),
    "amount": "1000000ufia",
    "moniker": "$NODENAME",
    "identity": "",
    "website": "",
    "security": "",
    "details": "",
    "commission-rate": "0.10",
    "commission-max-rate": "0.20",
    "commission-max-change-rate": "0.01",
    "min-self-delegation": "1"
}
EOF

                # Create validator using config file
                fiammad tx staking create-validator $HOME/validator.json \
                    --from=$WALLET \
                    --chain-id=$CHAIN_ID \
                    --gas="auto" \
                    --gas-adjustment=1.5 \
                    --fees=200ufia \
                    --broadcast-mode=sync \
                    -y

                rm $HOME/validator.json
                check_status "Validator creation"
                break
                ;;
            "📋 Check Node Status")
                print_header "Node Status"
                
                # Check service status
                service_status=$(systemctl status fiammad 2>&1 | grep "Active:")
                print_color $YELLOW "Service Status: $service_status"
                
                # Check RPC status
                rpc_status=$(curl -s localhost:26657/status)
                if [ $? -eq 0 ] && [ ! -z "$rpc_status" ]; then
                    block_height=$(echo "$rpc_status" | jq -r '.result.sync_info.latest_block_height // "N/A"')
                    catching_up=$(echo "$rpc_status" | jq -r '.result.sync_info.catching_up // "N/A"')
                    latest_block_time=$(echo "$rpc_status" | jq -r '.result.sync_info.latest_block_time // "N/A"')
                    
                    print_color $YELLOW "Current block height: $block_height"
                    print_color $YELLOW "Catching up: $catching_up"
                    print_color $YELLOW "Latest block time: $latest_block_time"
                    
                    # Check network connection
                    net_info=$(curl -s localhost:26657/net_info)
                    if [ $? -eq 0 ]; then
                        peers_count=$(echo "$net_info" | jq -r '.result.n_peers // "0"')
                        print_color $YELLOW "Connected peers: $peers_count"
                    else
                        print_color $RED "Unable to get peer information"
                    fi
                else
                    print_color $RED "Unable to connect to local RPC (port 26657)"
                    print_color $YELLOW "Checking logs for potential issues..."
                    sudo journalctl -u fiammad -n 20 -o cat
                fi
                break
                ;;
            "🔄 Check Sync Status")
                print_header "Sync Status Monitor"
                check_sync_status
                break
                ;;
            "💰 Check Balance")
                print_header "Wallet Balance"
                
                # Check if wallet exists
                if [ ! $WALLET ]; then
                    print_color $RED "No wallet found! Please create or import a wallet first."
                    break
                fi
                
                # Get wallet balance
                BALANCE=$(fiammad query bank balances $(fiammad keys show $WALLET -a) -o json | jq -r '.balances[] | select(.denom=="ufia") .amount // "0"')
                if [ "$BALANCE" == "" ]; then
                    BALANCE="0"
                fi
                
                # Convert ufia to FIA (divide by 1000000)
                FIA_BALANCE=$(echo "scale=6; $BALANCE/1000000" | bc)
                
                print_color $YELLOW "Wallet Address: $(fiammad keys show $WALLET -a)"
                print_color $GREEN "Balance: $FIA_BALANCE FIA ($BALANCE ufia)"
                
                # Show delegated amount if any
                DELEGATED=$(fiammad query staking delegations $(fiammad keys show $WALLET -a) -o json | jq -r '.delegation_responses[].balance.amount // "0"')
                if [ "$DELEGATED" != "0" ]; then
                    DELEGATED_FIA=$(echo "scale=6; $DELEGATED/1000000" | bc)
                    print_color $YELLOW "Delegated: $DELEGATED_FIA FIA ($DELEGATED ufia)"
                fi
                
                # Show rewards if any
                REWARDS=$(fiammad query distribution rewards $(fiammad keys show $WALLET -a) -o json | jq -r '.total[] | select(.denom=="ufia") .amount // "0"')
                if [ "$REWARDS" != "0" ]; then
                    REWARDS_FIA=$(echo "scale=6; ${REWARDS%.*}/1000000" | bc)
                    print_color $YELLOW "Pending Rewards: $REWARDS_FIA FIA ($REWARDS ufia)"
                fi
                break
                ;;
            "📜 View Logs")
                print_header "Node Logs"
    
                options=(
                    "View last 100 lines"
                    "View live logs"
                    "Search logs"
                    "Back"
                )
                
                PS3=$'\e[1;33mSelect log viewing option: \e[0m'
                select opt in "${options[@]}"; do
                    case $opt in
                        "View last 100 lines")
                            sudo journalctl -u fiammad -n 100 -o cat
                            break
                            ;;
                        "View live logs")
                            sudo journalctl -u fiammad -f -o cat
                            break
                            ;;
                        "Search logs")
                            read -p "Enter search term: " search_term
                            sudo journalctl -u fiammad -o cat | grep "$search_term"
                            break
                            ;;
                        "Back")
                            break
                            ;;
                        *)
                            print_color $RED "Invalid option $REPLY"
                            ;;
                    esac
                done
                break
                ;;
            "❌ Delete Node")
                print_header "Delete Fiamma Node"
    
                read -p "Are you sure you want to delete the node? This action cannot be undone. (y/n): " confirm
                if [[ $confirm == [yY] ]]; then
                    print_color $YELLOW "Stopping fiamma service..."
                    sudo systemctl stop fiammad
                    sudo systemctl disable fiammad
                    
                    print_color $YELLOW "Removing fiamma binary..."
                    sudo rm -rf ~/go/bin/fiammad
                    
                    print_color $YELLOW "Removing fiamma directory..."
                    sudo rm -rf $HOME/.fiamma
                    sudo rm -rf $HOME/fiamma
                    
                    print_color $YELLOW "Removing service file..."
                    sudo rm /etc/systemd/system/fiammad.service
                    sudo systemctl daemon-reload
                    
                    print_color $GREEN "Fiamma node has been completely removed!"
                else
                    print_color $YELLOW "Node deletion cancelled."
                fi
                break
                ;;
            "🚪 Exit")
                print_header "Goodbye!"
                exit 0
                ;;
            *) 
                print_color $RED "Invalid option $REPLY"
                ;;
        esac
    done
done
