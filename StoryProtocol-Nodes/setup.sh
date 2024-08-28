#!/bin/bash

LOGFILE="install_log.txt"
exec > >(tee -a "$LOGFILE") 2>&1

# Function to handle errors
function handle_error() {
    echo "Error on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Showing Animation
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Update and install necessary packages
echo "Updating and installing necessary packages..."
sudo apt update || { echo "Failed to update packages"; exit 1; }
sudo apt install -y screen npm wget git curl || { echo "Failed to install essential packages"; exit 1; }

# Clone the node-utils repository
echo "Cloning the node-utils repository..."
git clone https://github.com/storyprotocol/node-utils.git || { echo "Failed to clone repository"; exit 1; }

# Navigate to the directory containing the run_commands.sh script
cd node-utils/story-node-cli/linux || { echo "Failed to navigate to node-utils directory"; exit 1; }

# Make the run_commands.sh script executable
echo "Making the run_commands.sh script executable..."
chmod +x run_commands.sh || { echo "Failed to make run_commands.sh executable"; exit 1; }

# Prompt the user for a moniker name
read -p "Enter the moniker name you want to use: " MONIKER

# Start the Geth client in a new screen session
echo "Starting Geth in a new screen session..."
screen -dmS geth bash -c 'sudo bash run_commands.sh <<EOF
1
EOF'

# Wait for Geth to initialize
echo "Waiting for Geth to start..."
sleep 120  # Adjust the sleep time as needed

# Start the Iliad client in a new screen session
echo "Starting Iliad in a new screen session..."
screen -dmS iliad bash -c "sudo bash run_commands.sh <<EOF
2
$MONIKER
EOF"

# Function to prompt for private key input
function prompt_for_private_key() {
    read -p "Please enter your private key (starting with 0x): " PRIVATE_KEY
    if [[ $PRIVATE_KEY != 0x* ]]; then
        echo "Invalid private key format. The private key should start with '0x'."
        exit 1
    fi
}

# Check for nvm installation and install Node.js 20
echo "Checking Node.js version..."
if ! command -v nvm &> /dev/null; then
    echo "nvm is not installed. Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    source ~/.bashrc
    source ~/.nvm/nvm.sh
fi

nvm install 20
nvm use 20

# Check if ts-node is installed, and install if necessary
if ! command -v ts-node &> /dev/null; then
    echo "ts-node is not installed. Installing ts-node..."
    npm install -g ts-node || { echo "Failed to install ts-node"; exit 1; }
fi

# Install the Story Protocol SDK and dependencies
echo "Installing Story Protocol SDK and dependencies..."
npm install --save @story-protocol/core-sdk viem@1.21.4 || { echo "Failed to install Story Protocol SDK"; exit 1; }

# Fix or update packages if necessary
echo "Running npm audit fix..."
npm audit fix --force || { echo "npm audit fix failed"; exit 1; }

# Prompt for private key input
prompt_for_private_key

# Create .env file and insert private key
echo "Creating or updating .env file..."
cat << EOF > .env
WALLET_PRIVATE_KEY=$PRIVATE_KEY
RPC_PROVIDER_URL=https://rpc.partner.testnet.storyprotocol.net
EOF

# Create createWallet.ts script
echo "Creating createWallet.ts..."
cat << 'EOF' > createWallet.ts
import { config } from "dotenv";
import { privateKeyToAccount } from "viem/accounts";
import type { Address } from "viem";

// Load environment variables from .env file
config();

// Get the private key from the .env file
const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY || "0x";

// Create the account object using the private key
const account = privateKeyToAccount(PRIVATE_KEY as Address);

// Export the account object for use in other parts of your project
export default account;

// For demonstration, you can log the account address (not recommended for production)
console.log(`Wallet address: ${account.address}`);
EOF

# Run createWallet.ts script
echo "Running createWallet.ts script..."
npx ts-node createWallet.ts || { echo "Failed to run createWallet.ts"; exit 1; }

# Create setupClient.ts script
echo "Creating setupClient.ts..."
cat << 'EOF' > setupClient.ts
import { config as loadEnv } from "dotenv";
import { Account, privateKeyToAccount, Address } from 'viem/accounts';
import { StoryClient, StoryConfig } from "@story-protocol/core-sdk";
import { http } from 'viem'

// Load environment variables from .env file
loadEnv();

// Get the private key from the .env file and ensure it's valid
const privateKey: Address = process.env.WALLET_PRIVATE_KEY as Address;
const account: Account = privateKeyToAccount(privateKey);

// Configure the SDK client using the environment variables and the account
const config: StoryConfig = {
  transport: http(process.env.RPC_PROVIDER_URL),
  account: account, // the account object from above
  chainId: '1513' // change from Sepolia
};

export const client = StoryClient.newClient(config);
console.log("SDK Client is set up and ready to use.");
EOF

# Run setupClient.ts script
echo "Running setupClient.ts script..."
npx ts-node setupClient.ts || { echo "Failed to run setupClient.ts"; exit 1; }

# Optional cleanup
# echo "Cleaning up..."
# rm loader.sh logo.sh

# Display Watermark and Author
echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
echo "================================================================"
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
echo "================================================================"

# Display instructions for accessing the screen sessions
echo "Installation and setup complete. Your SDK should be ready to use!"
echo "Geth and Iliad are running in their respective screen sessions."
echo "To reattach to the Geth screen session, use: screen -r geth"
echo "To reattach to the Iliad screen session, use: screen -r iliad"
