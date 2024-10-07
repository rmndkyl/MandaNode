#!/bin/bash

# Function to install Rust
install_rust() {
    echo "Installing Rust..."
    source <(wget -O - https://raw.githubusercontent.com/0xishaq/installation/main/rust.sh)
    echo "Rust installation complete."
}

# Function to install Foundry
install_foundry() {
    echo "Installing Foundry..."
    source <(wget -O - https://raw.githubusercontent.com/zunxbt/installation/main/foundry.sh)
    echo "Foundry installation complete."
}

# Function to install OpenSSL and pkg-config
install_openssl_pkgconfig() {
    echo "Updating and installing OpenSSL and pkg-config..."
    sudo apt update && sudo apt install pkg-config libssl-dev
    echo "OpenSSL and pkg-config installation complete."
}

# Function to install all dependencies (Rust, Foundry, OpenSSL, pkg-config)
install_dependencies() {
    install_rust
    install_foundry
    install_openssl_pkgconfig
    echo "All dependencies installed successfully."
    read -n 1 -s -r -p "Press any key to continue..."
}

# Function to import wallet
import_wallet() {
    echo "Importing new wallet..."
    [ -d ~/.aligned_keystore ] && rm -rf ~/.aligned_keystore && echo "Deleted existing directory ~/.aligned_keystore."
    mkdir -p ~/.aligned_keystore
    cast wallet import ~/.aligned_keystore/keystore0 --interactive
    echo "Wallet imported successfully."
    read -n 1 -s -r -p "Press any key to continue..."
}

# Function to clone repo and answer quiz
clone_repo_and_answer_quiz() {
    echo "Cloning the aligned_layer repository and navigating to zkquiz..."
    [ -d aligned_layer ] && rm -rf aligned_layer && echo "Deleted existing aligned_layer directory."
    git clone https://github.com/yetanotherco/aligned_layer.git && cd aligned_layer/examples/zkquiz
    echo "Answering zkQuiz..."
    make answer_quiz KEYSTORE_PATH=~/.aligned_keystore/keystore0
    echo "zkQuiz answered successfully."
    read -n 1 -s -r -p "Press any key to continue..."
}

# Main menu
while true; do
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ Aligned zkQuiz Installer ===================================="
    echo "Node community Telegram channel: https://t.me/layerairdrop"
    echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "1. Install Dependencies (Rust, Foundry, OpenSSL, pkg-config)"
    echo "2. Import Wallet (make sure your wallet already have 0.1-0.2 ETH Holeskhy)"
    echo "3. Clone Repo and Answer zkQuiz"
    echo "4. Exit"
    echo "--------------------------"
    read -p "Please select an option (1-4): " option

    case $option in
        1) install_dependencies ;;
        2) import_wallet ;;
        3) clone_repo_and_answer_quiz ;;
        4) echo "Exiting..."; exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done