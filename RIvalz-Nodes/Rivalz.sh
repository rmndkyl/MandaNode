#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && ./loader.sh
curl -s https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh | bash
sleep 2

echo "Starting the setup process..."
rm -rf Rivalz.sh
# Step 1: Download and install NVM
echo "Downloading and installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

# Load nvm and bash_completion
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Ensure the shell knows where to find nvm
source ~/.bashrc

# Step 2: Install Node.js
echo "Installing Node.js..."
nvm install node

# Update npm to a specific version
echo "Updating npm to version 10.8.2..."
npm install -g npm@10.8.2

# Optional: Fund the npm package maintainers (only if needed, can be removed)
npm fund
sudo apt update

# Step 3: Install rClient CLI
echo "Installing rivalz-node-cli..."
npm install -g rivalz-node-cli

# Step 4: Install rClient CLI
echo "Installing rivalz-node-cli..."
rivalz update-version

# Step 5: Run rClient
echo "Running rivalz-node-cli..."
rivalz run

echo "Setup completed successfully."

rm -rf Rivalz.sh

echo "Setup completed."
