#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try using the 'sudo -i' command to switch to the root user, and then run this script again."
    exit 1
fi

# Update system package list
sudo apt update

# Clone the stack repo
laconic-so fetch-stack git.vdb.to/cerc-io/testnet-laconicd-stack

# Clone required repositories
laconic-so --stack ~/cerc/testnet-laconicd-stack/stack-orchestrator/stacks/testnet-laconicd setup-repositories --pull

# Check for errors and remove repositories if necessary
if [ $? -ne 0 ]; then
  echo "Repository error encountered. Removing and retrying..."
  rm -rf ~/cerc/testnet-laconicd-stack/stack-orchestrator/stacks/testnet-laconicd/repositories/*
  laconic-so --stack ~/cerc/testnet-laconicd-stack/stack-orchestrator/stacks/testnet-laconicd setup-repositories --pull
fi

# Build the container images
laconic-so --stack ~/cerc/testnet-laconicd-stack/stack-orchestrator/stacks/testnet-laconicd build-containers

# Create a spec file for the deployment
laconic-so --stack ~/cerc/testnet-laconicd-stack/stack-orchestrator/stacks/testnet-laconicd deploy init --output testnet-laconicd-spec.yml

# Edit the spec file to map container ports to host ports
sed -i '/network:/a \ \ ports:\n\ \ \ \ laconicd:\n\ \ \ \ \ \ - "6060:6060"\n\ \ \ \ \ \ - "26657:26657"\n\ \ \ \ \ \ - "26656:26656"\n\ \ \ \ \ \ - "9473:9473"\n\ \ \ \ \ \ - "9090:9090"\n\ \ \ \ \ \ - "1317:1317"' testnet-laconicd-spec.yml

# Create the deployment from the spec file
laconic-so --stack ~/cerc/testnet-laconicd-stack/stack-orchestrator/stacks/testnet-laconicd deploy create --spec-file testnet-laconicd-spec.yml --deployment-dir testnet-laconicd-deployment

# Copy the genesis file to the deployment directory
mkdir -p testnet-laconicd-deployment/data/laconicd-data/tmp
cp genesis.json testnet-laconicd-deployment/data/laconicd-data/tmp/genesis.json

# Configuration: edit config.env file
echo "Please configure 'CERC_PEERS' and 'CERC_MONIKER' in the 'testnet-laconicd-deployment/config.env' file."

# Start the deployment
laconic-so deployment --dir testnet-laconicd-deployment start

# Check status
docker ps -a
laconic-so deployment --dir testnet-laconicd-deployment logs laconicd -f

# Check sync status
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd status | jq .sync_info"

# View staking validators
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd query staking validators"

# Prompt for the node moniker
read -p "Enter your node's moniker: " NODE_MONIKER

# Import a key pair
KEY_NAME=alice
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd keys add $KEY_NAME --recover"
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd keys show $KEY_NAME -a"

# Check balance for your account
ACCOUNT_ADDRESS=$(laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd keys show $KEY_NAME -a")
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd query bank balances $ACCOUNT_ADDRESS"

# Create validator configuration
cat <<EOF > my-validator.json
{
  "pubkey": $(laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd cometbft show-validator"),
  "amount": "1000000000000000alnt",
  "moniker": "$NODE_MONIKER",
  "commission-rate": "0.1",
  "commission-max-rate": "0.2",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF

# Create a validator
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd tx staking create-validator my-validator.json --fees 500000alnt --chain-id=laconic_9000-1 --from $KEY_NAME"

# View staking validators
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd query staking validators"

# View validator set
laconic-so deployment --dir testnet-laconicd-deployment exec laconicd "laconicd query consensus comet validator-set"

# Clean up if needed
echo "To clean up, run the following commands:"
echo "laconic-so deployment --dir testnet-laconicd-deployment stop"
echo "laconic-so deployment --dir testnet-laconicd-deployment stop --delete-volumes"
echo "rm -r testnet-laconicd-deployment"

echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
echo "==============================Laconic LORO Nodes Automation=================================="
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"