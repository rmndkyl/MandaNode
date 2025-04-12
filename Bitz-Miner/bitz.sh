#!/bin/bash

# Show Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create wallet directory if it doesn't exist
WALLET_DIR="$HOME/.bitz_wallets"
mkdir -p "$WALLET_DIR"

# File to store wallet paths
WALLET_LIST="$WALLET_DIR/wallet_list.txt"
touch "$WALLET_LIST"

# Current wallet path
CURRENT_WALLET=""

# Trap Ctrl+C and Ctrl+Z
trap ctrl_c INT
trap ctrl_z TSTP

# Function to handle Ctrl+C
ctrl_c() {
    echo -e "\n${YELLOW}Ctrl+C detected. Returning to main menu...${NC}"
    sleep 1
    main_menu
}

# Function to handle Ctrl+Z
ctrl_z() {
    echo -e "\n${YELLOW}Ctrl+Z detected. Returning to main menu...${NC}"
    sleep 1
    main_menu
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}$1 is not installed.${NC}"
        return 1
    else
        echo -e "${GREEN}$1 is installed.${NC}"
        return 0
    fi
}

# Function to check Rust installation
check_rust() {
    echo -e "${CYAN}Checking Rust installation...${NC}"
    if check_command "rustc"; then
        rustc_version=$(rustc --version)
        echo -e "${GREEN}Rust version: ${rustc_version}${NC}"
        return 0
    else
        echo -e "${YELLOW}Rust is not installed.${NC}"
        return 1
    fi
}

# Function to check Solana CLI installation
check_solana_cli() {
    echo -e "${CYAN}Checking Solana CLI installation...${NC}"
    if check_command "solana"; then
        solana_version=$(solana --version)
        echo -e "${GREEN}Solana CLI version: ${solana_version}${NC}"
        return 0
    else
        echo -e "${YELLOW}Solana CLI is not installed.${NC}"
        return 1
    fi
}

# Function to check Bitz installation
check_bitz() {
    echo -e "${CYAN}Checking Bitz installation...${NC}"
    if check_command "bitz"; then
        bitz_version=$(bitz --version)
        echo -e "${GREEN}Bitz version: ${bitz_version}${NC}"
        return 0
    else
        echo -e "${YELLOW}Bitz is not installed.${NC}"
        return 1
    fi
}

# Function to check Node.js installation
check_nodejs() {
    echo -e "${CYAN}Checking Node.js installation...${NC}"
    if check_command "node"; then
        node_version=$(node --version)
        echo -e "${GREEN}Node.js version: ${node_version}${NC}"
        return 0
    else
        echo -e "${YELLOW}Node.js is not installed.${NC}"
        return 1
    fi
}

# Function to check Yarn installation
check_yarn() {
    echo -e "${CYAN}Checking Yarn installation...${NC}"
    if check_command "yarn"; then
        yarn_version=$(yarn --version)
        echo -e "${GREEN}Yarn version: ${yarn_version}${NC}"
        return 0
    else
        echo -e "${YELLOW}Yarn is not installed.${NC}"
        return 1
    fi
}

# Function to install Rust
install_rust() {
    echo -e "${CYAN}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
    echo -e "${GREEN}Rust installed successfully.${NC}"
}

# Function to install Solana CLI
install_solana_cli() {
    echo -e "${CYAN}Installing Solana CLI...${NC}"
    sh -c "$(curl -sSfL https://release.solana.com/v1.16.15/install)"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo -e "${GREEN}Solana CLI installed successfully.${NC}"
}

# Function to install Bitz
install_bitz() {
    echo -e "${CYAN}Installing Bitz...${NC}"
    cargo install bitz
    echo -e "${GREEN}Bitz installed successfully.${NC}"
}

# Function to install Node.js
install_nodejs() {
    echo -e "${CYAN}Installing Node.js...${NC}"
    # Using nvm for Node.js installation
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install node
    echo -e "${GREEN}Node.js installed successfully.${NC}"
}

# Function to install Yarn
install_yarn() {
    echo -e "${CYAN}Installing Yarn...${NC}"
    npm install --global yarn
    echo -e "${GREEN}Yarn installed successfully.${NC}"
}

# Function to create Solana keypair
create_solana_keypair() {
    echo -e "${CYAN}Creating Solana keypair...${NC}"
    
    # Generate a unique wallet ID
    wallet_id=$(date +%s)
    wallet_path="$WALLET_DIR/wallet_$wallet_id.json"
    
    solana-keygen new -o "$wallet_path" --no-bip39-passphrase
    
    echo "$wallet_path" >> "$WALLET_LIST"
    CURRENT_WALLET="$wallet_path"
    
    # Set this wallet as current
    solana config set --keypair "$CURRENT_WALLET"
    
    echo -e "${GREEN}Keypair created successfully at $wallet_path${NC}"
    echo -e "${GREEN}This wallet is now set as your active wallet.${NC}"
}

# Function to import an existing wallet
import_wallet() {
    echo -e "${CYAN}Import existing wallet${NC}"
    echo -e "${YELLOW}Choose import method:${NC}"
    echo "1. Import from keypair file"
    echo "2. Import from secret key"
    read -p "Enter choice [1-2]: " import_choice
    
    case $import_choice in
        1)
            read -p "Enter path to existing keypair file: " existing_path
            if [ -f "$existing_path" ]; then
                # Generate a unique wallet ID
                wallet_id=$(date +%s)
                wallet_path="$WALLET_DIR/wallet_$wallet_id.json"
                
                cp "$existing_path" "$wallet_path"
                echo "$wallet_path" >> "$WALLET_LIST"
                CURRENT_WALLET="$wallet_path"
                
                # Set this wallet as current
                solana config set --keypair "$CURRENT_WALLET"
                
                echo -e "${GREEN}Wallet imported and set as active.${NC}"
            else
                echo -e "${RED}File not found. Import failed.${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}Enter your 64-character secret key:${NC}"
            read -s secret_key
            
            # Generate a unique wallet ID
            wallet_id=$(date +%s)
            wallet_path="$WALLET_DIR/wallet_$wallet_id.json"
            
            # Create JSON structure for keypair
            echo "[$(echo $secret_key | sed 's/\([0-9a-f]\{2\}\)/\1,/g' | sed 's/,$//' | sed 's/,/, /g')]" > "$wallet_path"
            
            echo "$wallet_path" >> "$WALLET_LIST"
            CURRENT_WALLET="$wallet_path"
            
            # Set this wallet as current
            solana config set --keypair "$CURRENT_WALLET"
            
            echo -e "${GREEN}Wallet imported from secret key and set as active.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
}

# Function to list all wallets and select one
select_wallet() {
    if [ ! -s "$WALLET_LIST" ]; then
        echo -e "${RED}No wallets found. Please create or import a wallet first.${NC}"
        return
    fi
    
    echo -e "${CYAN}Available wallets:${NC}"
    
    # Display wallets with addresses
    counter=1
    while IFS= read -r wallet; do
        if [ -f "$wallet" ]; then
            address=$(solana address --keypair "$wallet")
            echo "$counter) $address - $wallet"
        else
            echo "$counter) $wallet (File missing)"
        fi
        counter=$((counter+1))
    done < "$WALLET_LIST"
    
    read -p "Select wallet number (1-$((counter-1))): " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$counter" ]; then
        selected_wallet=$(sed "${selection}q;d" "$WALLET_LIST")
        
        if [ -f "$selected_wallet" ]; then
            CURRENT_WALLET="$selected_wallet"
            solana config set --keypair "$CURRENT_WALLET"
            address=$(solana address)
            echo -e "${GREEN}Selected wallet: $address${NC}"
        else
            echo -e "${RED}Wallet file not found: $selected_wallet${NC}"
        fi
    else
        echo -e "${RED}Invalid selection.${NC}"
    fi
}

# Function to set up Solana config
setup_solana_config() {
    echo -e "${CYAN}Setting Solana config to Eclipse mainnet...${NC}"
    
    # Check if a wallet is selected
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${YELLOW}No wallet selected. Selecting default config only.${NC}"
        solana config set --url https://mainnetbeta-rpc.eclipse.xyz
    else
        solana config set --keypair "$CURRENT_WALLET" --url https://mainnetbeta-rpc.eclipse.xyz
    fi
    
    echo -e "${GREEN}Solana config set to Eclipse mainnet.${NC}"
}

# Function to check wallet balance
check_wallet_balance() {
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}No wallet selected. Please select a wallet first.${NC}"
        return
    fi
    
    echo -e "${CYAN}Checking wallet balance...${NC}"
    address=$(solana address)
    echo -e "${YELLOW}Wallet: $address${NC}"
    solana balance
}

# Function to run Bitz collect
run_bitz_collect() {
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}No wallet selected. Please select a wallet first.${NC}"
        return
    fi
    
    echo -e "${CYAN}Running Bitz collect for $(solana address)...${NC}"
    bitz collect
}

# Function to claim Bitz
claim_bitz() {
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}No wallet selected. Please select a wallet first.${NC}"
        return
    fi
    
    echo -e "${CYAN}Claiming Bitz for $(solana address)...${NC}"
    bitz claim
}

# Function to check Bitz account
check_bitz_account() {
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}No wallet selected. Please select a wallet first.${NC}"
        return
    fi
    
    echo -e "${CYAN}Checking Bitz account for $(solana address)...${NC}"
    bitz account
}

# Function to install all dependencies
install_all_dependencies() {
    echo -e "${CYAN}Installing all dependencies...${NC}"
    
    if ! check_rust; then
        install_rust
    fi
    
    if ! check_solana_cli; then
        install_solana_cli
    fi
    
    if ! check_nodejs; then
        install_nodejs
    fi
    
    if ! check_yarn; then
        install_yarn
    fi
    
    if ! check_bitz; then
        install_bitz
    fi
    
    echo -e "${GREEN}All dependencies installed successfully.${NC}"
}

# Function to check if all dependencies are installed
check_all_dependencies() {
    echo -e "${CYAN}Checking all dependencies...${NC}"
    
    local all_installed=true
    
    if ! check_rust; then
        all_installed=false
    fi
    
    if ! check_solana_cli; then
        all_installed=false
    fi
    
    if ! check_nodejs; then
        all_installed=false
    fi
    
    if ! check_yarn; then
        all_installed=false
    fi
    
    if ! check_bitz; then
        all_installed=false
    fi
    
    if $all_installed; then
        echo -e "${GREEN}All dependencies are installed.${NC}"
        return 0
    else
        echo -e "${YELLOW}Some dependencies are missing.${NC}"
        return 1
    fi
}

# Function for auto-mining with one wallet
auto_mining() {
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}No wallet selected. Please select a wallet first.${NC}"
        return
    fi
    
    echo -e "${CYAN}Starting Auto Mining with wallet $(solana address)...${NC}"
    read -p "Enter interval in minutes between collections (default: 10): " interval
    interval=${interval:-10}
    interval_seconds=$((interval * 60))
    
    echo -e "${GREEN}Auto mining will run every $interval minutes.${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop auto mining and return to menu.${NC}"
    
    count=0
    while true; do
        count=$((count + 1))
        echo -e "${CYAN}Run #$count - $(date)${NC}"
        bitz collect
        echo -e "${BLUE}Sleeping for $interval minutes...${NC}"
        sleep $interval_seconds
    done
}

# Function for batch mining with all wallets
batch_mining() {
    if [ ! -s "$WALLET_LIST" ]; then
        echo -e "${RED}No wallets found. Please create or import wallets first.${NC}"
        return
    fi
    
    # Count number of wallets
    wallet_count=$(wc -l < "$WALLET_LIST")
    
    echo -e "${CYAN}Starting Batch Mining with $wallet_count wallets...${NC}"
    read -p "Enter interval in minutes between collections (default: 10): " interval
    interval=${interval:-10}
    interval_seconds=$((interval * 60))
    
    echo -e "${GREEN}Batch mining will run every $interval minutes for all wallets.${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop batch mining and return to menu.${NC}"
    
    run_count=0
    while true; do
        run_count=$((run_count + 1))
        echo -e "${PURPLE}===== Batch Run #$run_count - $(date) =====${NC}"
        
        # Process each wallet
        while IFS= read -r wallet; do
            if [ -f "$wallet" ]; then
                # Switch to this wallet
                solana config set --keypair "$wallet" > /dev/null 2>&1
                address=$(solana address)
                
                echo -e "${CYAN}Mining with wallet: $address ${NC}"
                bitz collect
                echo -e "${BLUE}Completed mining for $address${NC}"
                echo "----------------------------------------------"
            fi
        done < "$WALLET_LIST"
        
        # Switch back to current wallet if set
        if [ -n "$CURRENT_WALLET" ] && [ -f "$CURRENT_WALLET" ]; then
            solana config set --keypair "$CURRENT_WALLET" > /dev/null 2>&1
        fi
        
        echo -e "${BLUE}Completed batch run. Sleeping for $interval minutes...${NC}"
        sleep $interval_seconds
    done
}

# Function to remove a wallet from the list
remove_wallet() {
    if [ ! -s "$WALLET_LIST" ]; then
        echo -e "${RED}No wallets found.${NC}"
        return
    fi
    
    echo -e "${CYAN}Select wallet to remove:${NC}"
    
    # Display wallets with addresses
    counter=1
    while IFS= read -r wallet; do
        if [ -f "$wallet" ]; then
            address=$(solana address --keypair "$wallet")
            echo "$counter) $address - $wallet"
        else
            echo "$counter) $wallet (File missing)"
        fi
        counter=$((counter+1))
    done < "$WALLET_LIST"
    
    read -p "Select wallet number to remove (1-$((counter-1))): " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$counter" ]; then
        selected_wallet=$(sed "${selection}q;d" "$WALLET_LIST")
        
        # Remove from wallet list
        grep -v "^$selected_wallet$" "$WALLET_LIST" > "${WALLET_LIST}.tmp"
        mv "${WALLET_LIST}.tmp" "$WALLET_LIST"
        
        echo -e "${GREEN}Wallet removed from list.${NC}"
        
        # Ask if they want to delete the file too
        read -p "Do you want to delete the wallet file as well? (y/n): " delete_file
        if [[ "$delete_file" == "y" || "$delete_file" == "Y" ]]; then
            if [ -f "$selected_wallet" ]; then
                rm "$selected_wallet"
                echo -e "${GREEN}Wallet file deleted.${NC}"
            else
                echo -e "${YELLOW}Wallet file was already missing.${NC}"
            fi
        fi
        
        # If current wallet was removed, reset it
        if [ "$CURRENT_WALLET" = "$selected_wallet" ]; then
            CURRENT_WALLET=""
            echo -e "${YELLOW}Your active wallet was removed. Please select another wallet.${NC}"
        fi
    else
        echo -e "${RED}Invalid selection.${NC}"
    fi
}

# Function to display wallet management menu
wallet_management() {
    while true; do
        clear
        echo -e "${PURPLE}======================================${NC}"
        echo -e "${BLUE}         WALLET MANAGEMENT           ${NC}"
        echo -e "${PURPLE}======================================${NC}"
        
        # Show current wallet if set
        if [ -n "$CURRENT_WALLET" ] && [ -f "$CURRENT_WALLET" ]; then
            address=$(solana address --keypair "$CURRENT_WALLET")
            echo -e "${GREEN}Current wallet: $address${NC}"
        else
            echo -e "${YELLOW}No wallet selected${NC}"
        fi
        
        echo -e "${PURPLE}======================================${NC}"
        echo -e "${YELLOW}1.${NC} Create new wallet"
        echo -e "${YELLOW}2.${NC} Import existing wallet"
        echo -e "${YELLOW}3.${NC} Select wallet"
        echo -e "${YELLOW}4.${NC} Check wallet balance"
        echo -e "${YELLOW}5.${NC} Remove wallet"
        echo -e "${YELLOW}6.${NC} List all wallets"
        echo -e "${YELLOW}0.${NC} Back to main menu"
        echo -e "${PURPLE}======================================${NC}"
        read -p "Enter your choice [0-6]: " choice
        
        case $choice in
            1) create_solana_keypair; read -p "Press Enter to continue..." ;;
            2) import_wallet; read -p "Press Enter to continue..." ;;
            3) select_wallet; read -p "Press Enter to continue..." ;;
            4) check_wallet_balance; read -p "Press Enter to continue..." ;;
            5) remove_wallet; read -p "Press Enter to continue..." ;;
            6) 
                echo -e "${CYAN}Wallet List:${NC}"
                counter=1
                while IFS= read -r wallet; do
                    if [ -f "$wallet" ]; then
                        address=$(solana address --keypair "$wallet")
                        echo "$counter) $address - $wallet"
                    else
                        echo "$counter) $wallet (File missing)"
                    fi
                    counter=$((counter+1))
                done < "$WALLET_LIST"
                read -p "Press Enter to continue..." 
                ;;
            0) return ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}"; sleep 2 ;;
        esac
    done
}

# Main menu function
main_menu() {
    while true; do
        clear
        echo -e "${PURPLE}======================================${NC}"
        echo -e "${BLUE}     BITZ MINER AUTOMATION SCRIPT     ${NC}"
        echo -e "${PURPLE}======================================${NC}"
        
        # Show current wallet if set
        if [ -n "$CURRENT_WALLET" ] && [ -f "$CURRENT_WALLET" ]; then
            address=$(solana address --keypair "$CURRENT_WALLET")
            echo -e "${GREEN}Current wallet: $address${NC}"
        else
            echo -e "${YELLOW}No wallet selected${NC}"
        fi
        
        echo -e "${PURPLE}======================================${NC}"
        echo -e "${YELLOW}1.${NC} Check dependencies"
        echo -e "${YELLOW}2.${NC} Install all dependencies"
        echo -e "${YELLOW}3.${NC} Wallet management"
        echo -e "${YELLOW}4.${NC} Set up Solana config (Eclipse mainnet)"
        echo -e "${YELLOW}5.${NC} Run Bitz collect (current wallet)"
        echo -e "${YELLOW}6.${NC} Claim Bitz (current wallet)"
        echo -e "${YELLOW}7.${NC} Check Bitz account (current wallet)"
        echo -e "${YELLOW}8.${NC} Start auto mining (current wallet)"
        echo -e "${YELLOW}9.${NC} Start batch mining (all wallets)"
        echo -e "${YELLOW}0.${NC} Exit"
        echo -e "${PURPLE}======================================${NC}"
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) check_all_dependencies; read -p "Press Enter to continue..." ;;
            2) install_all_dependencies; read -p "Press Enter to continue..." ;;
            3) wallet_management ;;
            4) setup_solana_config; read -p "Press Enter to continue..." ;;
            5) run_bitz_collect; read -p "Press Enter to continue..." ;;
            6) claim_bitz; read -p "Press Enter to continue..." ;;
            7) check_bitz_account; read -p "Press Enter to continue..." ;;
            8) auto_mining ;;
            9) batch_mining ;;
            0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}"; sleep 2 ;;
        esac
    done
}

# Start the script
main_menu
