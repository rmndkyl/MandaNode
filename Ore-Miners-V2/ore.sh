#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check if the script is running as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as the root user."
    echo "Please try using 'sudo -i' to switch to the root user, then run this script again."
    exit 1
fi

function install_node() {

    # Update system and install necessary packages
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo "Installing necessary tools and dependencies..."
    sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

    # Install Rust and Cargo
    echo "Installing Rust and Cargo..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env

    # Install Solana CLI
    echo "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

    # Check if solana-keygen is in PATH
    if ! command -v solana-keygen &> /dev/null; then
        echo "Adding Solana CLI to PATH"
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Create Solana keypair
    echo "Creating Solana keypair..."
    solana-keygen new --derivation-path m/44'/501'/0'/0' --force | tee solana-keygen-output.txt

    # Display prompt for backup confirmation
    echo "Please ensure you have backed up the mnemonic and private key information shown above."
    echo "Please deposit SOL to the pubkey for gas fees."

    echo "After backing up, enter 'yes' to continue:"

    read -p "" user_confirmation

    if [[ "$user_confirmation" == "yes" ]]; then
        echo "Backup confirmed. Continuing script..."
    else
        echo "Script terminated. Please ensure your information is backed up before running the script."
        exit 1
    fi

    # Install Ore CLI
    echo "Installing Ore CLI..."
    cargo install ore-cli

    # Add Solana and Cargo paths to .bashrc if not already added
    grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
    grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

    # Source changes
    source ~/.bashrc

    # Get user input for RPC address or use default
    read -p "Enter custom RPC address (recommended to use free Quicknode or Alchemy SOL RPC, default: https://api.mainnet-beta.solana.com): " custom_rpc
    RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

    # Get user input for number of threads or use default
    read -p "Enter the number of threads to use for mining (default: 1): " custom_threads
    THREADS=${custom_threads:-1}

    # Get user input for priority fee or use default
    read -p "Enter the priority fee for transactions (default: 1): " custom_priority_fee
    PRIORITY_FEE=${custom_priority_fee:-1}

    # Start mining using screen and Ore CLI
    session_name="ore"
    echo "Starting mining session with the name $session_name ..."

    start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'Process exited unexpectedly, restarting' >&2; sleep 1; done"
    screen -dmS "$session_name" bash -c "$start"

    echo "Mining process started in a background screen session named $session_name."
    echo "Use 'screen -r $session_name' to reconnect to this session."
}

# Recover Solana wallet and start mining
function export_wallet() {
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo "Installing necessary tools and dependencies..."
    sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
    check_and_install_dependencies
    
    echo "Recovering Solana wallet..."
    echo "Enter your mnemonic below, separated by spaces. Blind text input won't display."

    solana-keygen recover 'prompt:?key=0/0' --force

    echo "Wallet recovered."
    echo "Please ensure your wallet has sufficient SOL for transaction fees."

    # Add Solana and Cargo paths to .bashrc if not already added
    grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
    grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

    # Source changes
    source ~/.bashrc

    # Get user input for RPC address or use default
    read -p "Enter custom RPC address (recommended to use free Quicknode or Alchemy SOL RPC, default: https://api.mainnet-beta.solana.com): " custom_rpc
    RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

    # Get user input for number of threads or use default
    read -p "Enter the number of threads to use for mining (default: 1): " custom_threads
    THREADS=${custom_threads:-1}

    # Get user input for priority fee or use default
    read -p "Enter the priority fee for transactions (default: 1): " custom_priority_fee
    PRIORITY_FEE=${custom_priority_fee:-1}

    # Start mining using screen and Ore CLI
    session_name="ore"
    echo "Starting mining session with the name $session_name ..."

    start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'Process exited unexpectedly, restarting' >&2; sleep 1; done"
    screen -dmS "$session_name" bash -c "$start"

    echo "Mining process started in a background screen session named $session_name."
    echo "Use 'screen -r $session_name' to reconnect to this session."
}

function check_and_install_dependencies() {
    if ! command -v cargo &> /dev/null; then
        echo "Rust and Cargo not installed, installing..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source $HOME/.cargo/env
    else
        echo "Rust and Cargo already installed."
    fi

    if ! command -v solana-keygen &> /dev/null; then
        echo "Solana CLI not installed, installing..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    else
        echo "Solana CLI already installed."
    fi

    if ! ore -V &> /dev/null; then
        echo "Ore CLI not installed, installing..."
        cargo install ore-cli
    else
        echo "Ore CLI already installed."
    fi

    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    export PATH="$HOME/.cargo/bin:$PATH"
}

function start() {
    read -p "Enter custom RPC address (recommended to use free Quicknode or Alchemy SOL RPC, default: https://api.mainnet-beta.solana.com): " custom_rpc
    RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

    read -p "Enter the number of threads to use for mining (default: 1): " custom_threads
    THREADS=${custom_threads:-1}

    read -p "Enter the priority fee for transactions (default: 1): " custom_priority_fee
    PRIORITY_FEE=${custom_priority_fee:-1}

    session_name="ore"
    echo "Starting mining session with the name $session_name ..."

    start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'Process exited unexpectedly, restarting' >&2; sleep 1; done"
    screen -dmS "$session_name" bash -c "$start"

    echo "Mining process started in a background screen session named $session_name."
    echo "Use 'screen -r $session_name' to reconnect to this session."
}

function view_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json rewards
}

function claim_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json --priority-fee 50000 claim
}

function check_logs() {
    screen -r ore
}

function multiple() {
#!/bin/bash

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
echo "Installing necessary tools and dependencies..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
check_and_install_dependencies

# Prompt the user for the RPC configuration address
read -p "Please enter the RPC configuration address: " rpc_address

# Ask the user for the number of wallet configuration files to generate
read -p "Please enter the number of wallets you want to run: " count

# Ask the user for the priority fee
read -p "Please enter the transaction priority fee (default is 1): " priority_fee
priority_fee=${priority_fee:-1}

# Ask the user for the number of threads to use
read -p "Please enter the number of threads to use for mining (default is 1): " threads
threads=${threads:-1}

# Base session name
session_base_name="ore"

# Start command template, with variables replacing RPC address, priority fee, and thread count
start_command_template="while true; do ore --rpc $rpc_address --keypair ~/.config/solana/idX.json --priority-fee $priority_fee mine --threads $threads; echo 'Process exited unexpectedly, waiting to restart' >&2; sleep 1; done"

# Ensure the .solana directory exists
mkdir -p ~/.config/solana

# Loop to create configuration files and start mining processes
for (( i=1; i<=count; i++ ))
do
    # Prompt the user for the private key
    echo "Enter the private key for id${i}.json (format should be a JSON array containing 64 digits):"
    read -p "Private key: " private_key

    # Generate the configuration file path
    config_file=~/.config/solana/id${i}.json

    # Write the private key directly into the configuration file
    echo $private_key > $config_file

    # Check if the configuration file was successfully created
    if [ ! -f $config_file ]; then
        echo "Failed to create id${i}.json, please check the private key and try again."
        exit 1
    fi

    # Generate the session name
    session_name="${session_base_name}_${i}"

    # Replace the configuration file name and RPC address in the start command
    start_command=${start_command_template//idX/id${i}}

    # Print starting information
    echo "Starting mining, session name is $session_name ..."

    # Use screen to start the mining process in the background
    screen -dmS "$session_name" bash -c "$start_command"

    # Print mining process startup information
    echo "Mining process has started in the background in the screen session named $session_name."
    echo "Use the command 'screen -r $session_name' to reconnect to this session."
done

}

function check_multiple() {
# Prompt the user to enter the RPC address
echo -n "Please enter the RPC address (e.g., https://api.mainnet-beta.solana.com): "
read rpc_address

# Prompt the user to enter the start and end numbers, separated by a space
echo -n "Please enter the start and end numbers, separated by a space (e.g., for 10 wallet addresses, enter 1 10): "
read -a range

# Get the start and end numbers
start=${range[0]}
end=${range[1]}

# Loop through the range
for i in $(seq $start $end); do
  ore --rpc $rpc_address --keypair ~/.config/solana/id$i.json --priority-fee 1 rewards
done
}

function lonely() {

# Prompt the user to enter the RPC configuration address
read -p "Please enter the RPC configuration address: " rpc_address

# Prompt the user to enter the number of wallet configuration files to generate
read -p "Please enter the number of wallets you want to run: " count

# Prompt the user to enter the priority fee
read -p "Please enter the priority fee for transactions (default is 1): " priority_fee
priority_fee=${priority_fee:-1}

# Prompt the user to enter the number of threads to use for mining
read -p "Please enter the number of threads to use for mining (default is 1): " threads
threads=${threads:-1}

# Base session name
session_base_name="ore"

# Command template to start mining, using variables to replace the RPC address, priority fee, and threads
start_command_template="while true; do ore --rpc $rpc_address --keypair ~/.config/solana/idX.json --priority-fee $priority_fee mine --threads $threads; echo 'Process exited unexpectedly, waiting to restart' >&2; sleep 1; done"

# Ensure the .solana directory exists
mkdir -p ~/.config/solana

# Loop to create configuration files and start the mining process
for (( i=1; i<=count; i++ ))
do
    # Prompt the user to enter the private key
    echo "Enter the private key for id${i}.json (format should be a JSON array containing 64 numbers):"
    read -p "Private key: " private_key

    # Generate the configuration file path
    config_file=~/.config/solana/id${i}.json

    # Write the private key directly to the configuration file
    echo $private_key > $config_file

    # Check if the configuration file was successfully created
    if [ ! -f $config_file ]; then
        echo "Failed to create id${i}.json. Please check the private key and try again."
        exit 1
    fi

    # Generate the session name
    session_name="${session_base_name}_${i}"

    # Replace the placeholders in the start command with actual values
    start_command=${start_command_template//idX/id${i}}

    # Print the starting information
    echo "Starting mining, session name is $session_name ..."

    # Use screen to start the mining process in the background
    screen -dmS "$session_name" bash -c "$start_command"

    # Print information about the mining process
    echo "Mining process has started in a screen session named $session_name."
    echo "Use 'screen -r $session_name' to reconnect to this session."
done
}

function claim_multiple() {
#!/bin/bash

# Prompt the user to enter the RPC address
echo -n "Please enter the RPC address (e.g., https://api.mainnet-beta.solana.com): "
read rpc_address

# Validate the RPC address input
if [[ -z "$rpc_address" ]]; then
  echo "RPC address cannot be empty."
  exit 1
fi

# Prompt the user to enter the priority fee
echo -n "Please enter the priority fee (in lamports, e.g., 500000): "
read priority_fee

# Validate the priority fee input
if ! [[ "$priority_fee" =~ ^[0-9]+$ ]]; then
  echo "Priority fee must be an integer."
  exit 1
fi

# Prompt the user to enter the start and end numbers
echo -n "Please enter the start and end numbers, separated by a space (e.g., for 10 wallets, enter 1 10): "
read -a range

# Get the start and end numbers
start=${range[0]}
end=${range[1]}

# Infinite loop
while true; do
  # Loop through the specified range
  for i in $(seq $start $end); do
    echo "Processing wallet $i with RPC $rpc_address and priority fee $priority_fee"
    ore --rpc $rpc_address --keypair ~/.config/solana/id$i.json --priority-fee $priority_fee claim
  done
  echo "Successfully claimed rewards from wallet $start to $end."
done

}

function rerun_rpc() {

# Prompt the user to enter the RPC address
read -p "Please enter the RPC address: " rpc_address

# Prompt the user to enter the priority fee
read -p "Please enter the priority fee (default is 1): " priority_fee
priority_fee=${priority_fee:-1}

# Prompt the user to enter the number of threads for mining
read -p "Please enter the number of threads to use for mining (default is 1): " threads
threads=${threads:-1}

# Base session name
session_base_name="ore"

# Start command template
start_command_template="while true; do ore --rpc $rpc_address --keypair {} --priority-fee $priority_fee mine --threads $threads; echo 'Process exited abnormally, waiting to restart' >&2; sleep 1; done"

# Automatically find all id*.json files
config_files=$(find ~/.config/solana -name "id*.json")
for config_file in $config_files
do
    # Use jq to read the first five numbers from the file and convert them into a comma-separated string
    key_prefix=$(jq -r '.[0:5] | join(",")' "$config_file")

    # Generate the session name
    session_name="${session_base_name}_[${key_prefix}]"

    # Replace the placeholder in the start command with the config file path
    start_command=$(echo $start_command_template | sed "s|{}|$config_file|g")

    # Print the start information
    echo "Starting mining, session name is $session_name ..."

    # Use screen to start the mining process in the background
    screen -dmS "$session_name" bash -c "$start_command"

    # Print information about the mining process start
    echo "Mining process has been started in the background with screen session named $session_name."
    echo "Use 'screen -r $session_name' to reconnect to this session."
done

}

function benchmark() {
    read -p "Please enter the number of threads to use for mining: " threads
    ore benchmark --threads "$threads"
}

# Display main menu
function main_menu() {
    while true; do
        clear
        echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
        echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
        echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
        echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
        echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
        echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
        echo "============================ Ore V2 Node Installation ===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press Ctrl+C."
        echo "Please choose an option:"
        echo "1. Install a new node (solanakeygen new wallet derivation has a bug, not highly recommended; preferred to use option 7 to import private key)"
        echo "2. Import wallet and run"
        echo "3. Start running separately"
        echo "4. View mining rewards for a single account"
        echo "5. Claim mining rewards for a single account"
        echo "6. Check node status"
        echo "7. (Suitable for first-time installation) Multi-wallet setup on a single machine with environment installation, requires JSON private keys"
        echo "8. Multi-wallet setup on a single machine without environment check, requires JSON private keys"
        echo "9. View rewards for multiple wallets"
        echo "10. Claim rewards for multiple wallets (automatic polling)"
        echo "11. Change RPC and other configurations, and monitor all JSON private key files in /.config/solana with key prefix naming. Please ensure jq is installed, if not, please run apt install jq first."
        echo "12. Performance testing"
        read -p "Please enter an option (1-12): " OPTION

        case $OPTION in
        1) install_node ;;
        2) export_wallet ;;
        3) start ;;
        4) view_rewards ;;
        5) claim_rewards ;;
        6) check_logs ;;
        7) multiple ;;
        8) lonely ;; 
        9) check_multiple ;;
        10) claim_multiple ;; 
        11) rerun_rpc ;; 
        12) benchmark ;;
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display the main menu
main_menu