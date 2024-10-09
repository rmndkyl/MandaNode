#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install Rust
echo "Installing Rust..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"

# Create screen session named 'nexus'
echo "Creating screen session 'nexus'..."
screen -dmS nexus

# Install and run the Nexus Prover
echo "Installing Nexus Prover..."
curl https://cli.nexus.xyz/install.sh | sh

# Display Prover ID
echo "Saving Prover ID..."
cat $HOME/.nexus/prover-id



echo "The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version"
echo "==============================Nexus zkVM setup and execution complete!===================================="
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"

# Provide instructions for screen usage
echo "Installation completed. To exit the screen session, use CTRL+A+D."
echo "To re-enter the 'nexus' screen session, use: screen -r nexus."