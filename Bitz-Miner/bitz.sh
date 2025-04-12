#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
    read -p "Do you want to use default location (~/.config/solana/id.json)? (y/n): " use_default
    
    if [[ "$use_default" == "y" || "$use_default" == "Y" ]]; then
        solana-keygen new
    else
        read -p "Enter custom filepath for your keypair (e.g. /path/to/keypair.json): " custom_path
        solana-keygen new -o "$custom_path"
    fi
    
    echo -e "${GREEN}Keypair created successfully.${NC}"
}

# Function to set up Solana config
setup_solana_config() {
    echo -e "${CYAN}Setting Solana config to Eclipse mainnet...${NC}"
    solana config set --url https://mainnetbeta-rpc.eclipse.xyz
    echo -e "${GREEN}Solana config set to Eclipse mainnet.${NC}"
}

# Function to check wallet balance
check_wallet_balance() {
    echo -e "${CYAN}Checking wallet balance...${NC}"
    solana balance
}

# Function to run Bitz collect
run_bitz_collect() {
    echo -e "${CYAN}Running Bitz collect...${NC}"
    bitz collect
}

# Function to claim Bitz
claim_bitz() {
    echo -e "${CYAN}Claiming Bitz...${NC}"
    bitz claim
}

# Function to check Bitz account
check_bitz_account() {
    echo -e "${CYAN}Checking Bitz account...${NC}"
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

# Function for auto-mining
auto_mining() {
    echo -e "${CYAN}Starting Auto Mining...${NC}"
    read -p "Enter interval in minutes between collections (default: 10): " interval
    interval=${interval:-10}
    interval_seconds=$((interval * 60))
    
    echo -e "${GREEN}Auto mining will run every $interval minutes.${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop auto mining.${NC}"
    
    count=0
    while true; do
        count=$((count + 1))
        echo -e "${CYAN}Run #$count - $(date)${NC}"
        bitz collect
        echo -e "${BLUE}Sleeping for $interval minutes...${NC}"
        sleep $interval_seconds
    done
}

# Main menu function
main_menu() {
    clear
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${BLUE}     BITZ MINER AUTOMATION SCRIPT     ${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo -e "${YELLOW}1.${NC} Check dependencies"
    echo -e "${YELLOW}2.${NC} Install all dependencies"
    echo -e "${YELLOW}3.${NC} Create Solana keypair"
    echo -e "${YELLOW}4.${NC} Set up Solana config"
    echo -e "${YELLOW}5.${NC} Check wallet balance"
    echo -e "${YELLOW}6.${NC} Run Bitz collect"
    echo -e "${YELLOW}7.${NC} Claim Bitz"
    echo -e "${YELLOW}8.${NC} Check Bitz account"
    echo -e "${YELLOW}9.${NC} Start auto mining"
    echo -e "${YELLOW}0.${NC} Exit"
    echo -e "${PURPLE}======================================${NC}"
    read -p "Enter your choice [0-9]: " choice
    
    case $choice in
        1) check_all_dependencies; read -p "Press Enter to continue..." ;;
        2) install_all_dependencies; read -p "Press Enter to continue..." ;;
        3) create_solana_keypair; read -p "Press Enter to continue..." ;;
        4) setup_solana_config; read -p "Press Enter to continue..." ;;
        5) check_wallet_balance; read -p "Press Enter to continue..." ;;
        6) run_bitz_collect; read -p "Press Enter to continue..." ;;
        7) claim_bitz; read -p "Press Enter to continue..." ;;
        8) check_bitz_account; read -p "Press Enter to continue..." ;;
        9) auto_mining ;;
        0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}"; sleep 2 ;;
    esac
    
    main_menu
}

# Start the script
main_menu
