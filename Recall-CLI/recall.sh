#!/bin/bash

# Script Name: recall.sh
# Purpose: Interactive menu-driven Recall CLI automation script

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Define variables
REPO_URL="https://github.com/recallnet/rust-recall.git"
INSTALL_DIR="$HOME/rust-recall"
ENV_FILE="$HOME/.recall_env"
TEST_FILE="$HOME/test.txt"
TEST_KEY="testfile"
TRANSFER_AMOUNT="0.1"

# Check if Recall CLI is installed
check_installation() {
    if command -v recall &> /dev/null; then
        echo "Recall CLI detected, version:"
        recall --version
        return 0
    fi
    return 1
}

# Check and install dependencies
install_dependencies() {
    echo "Checking dependencies..."
    if ! command -v git &> /dev/null; then
        echo "Git not found, installing..."
        sudo apt update && sudo apt install -y git
    fi
    if ! command -v make &> /dev/null; then
        echo "Make not found, installing..."
        sudo apt update && sudo apt install -y make
    fi
    if ! command -v cargo &> /dev/null; then
        echo "Rust/Cargo not found, installing..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    if ! command -v jq &> /dev/null; then
        echo "jq not found, installing..."
        sudo apt update && sudo apt install -y jq
    fi
}

# Install Recall CLI
install_recall() {
    echo "Cloning Recall repository..."
    if [ -d "$INSTALL_DIR" ]; then
        echo "Directory already exists, updating code..."
        cd "$INSTALL_DIR" && git pull
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi

    echo "Building and installing Recall CLI..."
    make install

    if [ $? -eq 0 ]; then
        echo "Installation successful! Verifying version..."
        recall --version
    else
        echo "Installation failed, please check for errors."
        exit 1
    fi
}

# Configure environment variables
configure_env() {
    echo "Configuring environment variables..."

    # Input private key (hidden input)
    read -s -p "Enter your RECALL_PRIVATE_KEY (input will be hidden): " PRIVATE_KEY
    echo "" # Newline
    if [ -z "$PRIVATE_KEY" ]; then
        echo "Error: Private key cannot be empty!"
        exit 1
    fi

    # Select network
    echo "Select a network (enter the number):"
    echo "1. testnet (default)"
    echo "2. mainnet"
    echo "3. devnet"
    echo "4. localnet (deprecated)"
    read -p "Your choice [1-4, default 1]: " NETWORK_CHOICE

    case $NETWORK_CHOICE in
        2) NETWORK="mainnet" ;;
        3) NETWORK="devnet" ;;
        4) NETWORK="localnet" ;;
        ""|1|*) NETWORK="testnet" ;;
    esac
    echo "Selected network: $NETWORK"

    # Create environment variable file
    echo "Saving environment variables to $ENV_FILE..."
    cat > "$ENV_FILE" << EOL
export RECALL_PRIVATE_KEY=$PRIVATE_KEY
export RECALL_NETWORK=$NETWORK
EOL

    # Load environment variables
    echo "Loading environment variables..."
    source "$ENV_FILE"
}

# Verify CLI
verify_cli() {
    echo "Verifying Recall CLI..."
    if recall --help &> /dev/null; then
        echo "Recall CLI is set up! You can start using: recall --help"
    else
        echo "Verification failed. Please check the private key or network configuration."
        exit 1
    fi
}

# Auto-load environment variables (if available)
auto_load_env() {
    if [ -f "$ENV_FILE" ]; then
        echo "Detected environment variable file $ENV_FILE, loading automatically..."
        source "$ENV_FILE"
        echo "Environment variables loaded successfully: RECALL_PRIVATE_KEY=$RECALL_PRIVATE_KEY, RECALL_NETWORK=$RECALL_NETWORK"
    else
        echo "Environment variable file $ENV_FILE not found. Please select option 2 to configure environment variables."
    fi
}

# Create a bucket
create_bucket() {
    echo "Creating a bucket..."
    BUCKET_OUTPUT=$(recall bucket create)
    if [ $? -eq 0 ]; then
        BUCKET_ADDRESS=$(echo "$BUCKET_OUTPUT" | jq -r '.address')
        echo "Bucket created successfully, address: $BUCKET_ADDRESS"
        echo "$BUCKET_ADDRESS" > /tmp/recall_bucket_address
    else
        echo "Bucket creation failed. Please check for errors."
        exit 1
    fi
}

# Get bucket address
get_bucket_address() {
    if [ -f /tmp/recall_bucket_address ]; then
        BUCKET_ADDRESS=$(cat /tmp/recall_bucket_address)
        if [ -z "$BUCKET_ADDRESS" ]; then
            echo "Error: Bucket address not found. Please create a bucket first."
            exit 1
        fi
    else
        echo "Error: Bucket address not found. Please create a bucket first."
        exit 1
    fi
}

# Generate target address (for transfers)
generate_target_address() {
    echo "Generating target address (for transfers)..."
    TARGET_OUTPUT=$(recall account create)
    if [ $? -eq 0 ]; then
        TARGET_ADDRESS=$(echo "$TARGET_OUTPUT" | jq -r '.address')
        echo "Target address generated successfully: $TARGET_ADDRESS"
        echo "$TARGET_ADDRESS" > /tmp/recall_target_address
    else
        echo "Target address generation failed. Please check for errors."
        exit 1
    fi
}

# Get target address
get_target_address() {
    if [ -f /tmp/recall_target_address ]; then
        TARGET_ADDRESS=$(cat /tmp/recall_target_address)
        if [ -z "$TARGET_ADDRESS" ]; then
            echo "Error: Target address not found. Please generate a target address first."
            exit 1
        fi
    else
        echo "Error: Target address not found. Please generate a target address first."
        exit 1
    fi
}

# Transfer funds
transfer_funds() {
    get_target_address
    echo "Executing transfer (amount: $TRANSFER_AMOUNT)..."
    recall account transfer --to "$TARGET_ADDRESS" "$TRANSFER_AMOUNT"
    if [ $? -eq 0 ]; then
        echo "Transfer successful!"
    else
        echo "Transfer failed. Please check your balance or network configuration."
        exit 1
    fi
}

# Upload File
upload_file() {
    get_bucket_address
    echo "Creating test file..."
    echo "Hello, Recall!" > "$TEST_FILE"

    echo "Uploading file to the bucket..."
    recall bucket add --address "$BUCKET_ADDRESS" --key "$TEST_KEY" "$TEST_FILE"
    if [ $? -eq 0 ]; then
        echo "File uploaded successfully!"
    else
        echo "File upload failed. Please check credit or balance."
        exit 1
    fi
}

# Download File
download_file() {
    get_bucket_address
    echo "Downloading file for verification..."
    recall bucket get --address "$BUCKET_ADDRESS" "$TEST_KEY"
    if [ $? -eq 0 ]; then
        echo "File downloaded successfully!"
    else
        echo "File download failed. Please check the bucket or key."
        exit 1
    fi
}

# Check and Buy Credit
check_and_buy_credit() {
    echo "Checking credit..."
    if [ -z "$RECALL_PRIVATE_KEY" ]; then
        echo "Error: RECALL_PRIVATE_KEY is not set. Please configure environment variables (Option 2)."
        exit 1
    fi
    CREDIT_INFO=$(recall account info --private-key "$RECALL_PRIVATE_KEY" | jq -r '.credit.credit_free')
    if [ $? -ne 0 ]; then
        echo "Failed to retrieve credit information. Please check network or private key configuration."
        exit 1
    fi
    if [ "$CREDIT_INFO" == "0" ]; then
        echo "Credit is 0, purchasing credit (10 units)..."
        recall account credit buy --amount 10
        if [ $? -eq 0 ]; then
            echo "Credit purchase successful!"
        else
            echo "Credit purchase failed. Please check balance."
            exit 1
        fi
    else
        echo "Sufficient credit: $CREDIT_INFO"
    fi
}

# Check Account Information
check_account() {
    echo "Checking account information..."
    if [ -z "$RECALL_PRIVATE_KEY" ]; then
        echo "Error: RECALL_PRIVATE_KEY is not set. Please configure environment variables (Option 2)."
        exit 1
    fi
    recall account info --private-key "$RECALL_PRIVATE_KEY"
    if [ $? -ne 0 ]; then
        echo "Failed to retrieve account information. Please check network or private key."
        exit 1
    fi
}

# Interactive Menu
show_menu() {
    while true; do
        clear
        echo "=== Recall CLI Automation Script ==="
        echo "1. Install Recall CLI"
        echo "2. Configure Environment Variables"
        echo "3. Check and Buy Credit"
        echo "4. Create Bucket"
        echo "5. Generate Transfer Target Address"
        echo "6. Execute Transfer"
        echo "7. Upload File to Bucket"
        echo "8. Download File for Verification"
        echo "9. Check Account Information"
        echo "0. Exit"
        echo "======================="
        read -p "Select an option [0-9]: " choice

        case $choice in
            1)
                install_dependencies
                install_recall
                press_any_key
                ;;
            2)
                configure_env
                verify_cli
                press_any_key
                ;;
            3)
                check_and_buy_credit
                press_any_key
                ;;
            4)
                create_bucket
                press_any_key
                ;;
            5)
                generate_target_address
                press_any_key
                ;;
            6)
                transfer_funds
                press_any_key
                ;;
            7)
                upload_file
                press_any_key
                ;;
            8)
                download_file
                press_any_key
                ;;
            9)
                check_account
                press_any_key
                ;;
            0)
                echo "Exiting script..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter a number between 0-9."
                press_any_key
                ;;
        esac
    done
}

# Press Any Key to Continue
press_any_key() {
    read -p "Press any key to continue..." -n1
}

# Main Process
echo "Welcome to the Recall CLI Automation Script!"

# Check if Installed
if ! check_installation; then
    install_dependencies
    install_recall
fi

# Auto-load Environment Variables
auto_load_env

# Show Menu
show_menu
