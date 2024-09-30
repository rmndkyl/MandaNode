#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/Eclipse.sh"

echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Ensure the script is run as root
if [ "$(id -u)" -ne "0" ]; then
  echo "Please run this script as the root user or using sudo."
  exit 1
fi

deploy_environment() {
    install_solana() {
        if ! command -v solana &> /dev/null; then
            echo "Solana not found. Installing Solana..."
            sh -c "$(curl -sSfL https://release.solana.com/v1.18.18/install)"
            if ! grep -q 'solana' ~/.bashrc; then
                echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
                echo "Solana has been added to the PATH in .bashrc. Please restart the terminal or run 'source ~/.bashrc' to apply the changes."
            fi
            export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        else
            echo "Solana is already installed."
        fi
    }

    setup_wallet() {
        KEYPAIR_DIR="$HOME/solana_keypairs"
        mkdir -p "$KEYPAIR_DIR"

        echo "Do you want to use an existing wallet or create a new one?"
        PS3="Please enter your choice (1 or 2): "
        options=("Use existing wallet" "Create new wallet")
        select opt in "${options[@]}"; do
            case $opt in
                "Use existing wallet")
                    echo "Restoring from existing wallet..."
                    KEYPAIR_PATH="$KEYPAIR_DIR/eclipse-import.json"
                    solana-keygen recover -o "$KEYPAIR_PATH" --force
                    if [[ $? -ne 0 ]]; then
                        echo "Failed to restore the existing wallet. Exiting."
                        exit 1
                    fi
                    break
                    ;;
                "Create new wallet")
                    echo "Creating a new wallet..."
                    KEYPAIR_PATH="$KEYPAIR_DIR/eclipse-new.json"
                    solana-keygen new -o "$KEYPAIR_PATH" --force
                    if [[ $? -ne 0 ]]; then
                        echo "Failed to create a new wallet. Exiting."
                        exit 1
                    fi
                    break
                    ;;
                *) echo "Invalid option. Please try again." ;;
            esac
        done

        solana config set --keypair "$KEYPAIR_PATH"
        echo "Wallet setup complete!"
    }

    setup_network() {
        echo "Do you want to deploy on the Mainnet or Testnet?"
        PS3="Please enter your choice (1 or 2): "
        network_options=("Mainnet" "Testnet")
        select network_opt in "${network_options[@]}"; do
            case $network_opt in
                "Mainnet")
                    echo "Setting up Mainnet..."
                    NETWORK_URL="https://mainnetbeta-rpc.eclipse.xyz"
                    break
                    ;;
                "Testnet")
                    echo "Setting up Testnet..."
                    NETWORK_URL="https://testnet.dev2.eclipsenetwork.xyz"
                    break
                    ;;
                *) echo "Invalid option. Please try again." ;;
            esac
        done

        echo "Configuring Solana..."
        solana config set --url "$NETWORK_URL"
        echo "Network setup complete!"
    }

    # Execute steps
    install_solana
    setup_wallet
    setup_network
}

create_spl_and_operations() {
    echo "Creating SPL token..."

    if ! solana config get | grep -q "Keypair Path:"; then
        echo "Error: No keypair set in Solana configuration. Exiting."
        exit 1
    fi

    spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
    if [[ $? -ne 0 ]]; then
        echo "Failed to create SPL token. Exiting."
        exit 1
    fi

    read -p "Please enter the token address you obtained above: " TOKEN_ADDRESS
    read -p "Please enter your token symbol (e.g., ZUNXBT): " TOKEN_SYMBOL
    read -p "Please enter your token name (e.g., Zenith Token): " TOKEN_NAME
    read -p "Please enter your token metadata URL: " METADATA_URL

    echo "Initializing token metadata..."
    spl-token initialize-metadata "$TOKEN_ADDRESS" "$TOKEN_NAME" "$TOKEN_SYMBOL" "$METADATA_URL"
    if [[ $? -ne 0 ]]; then
        echo "Failed to initialize token metadata. Exiting."
        exit 1
    fi

    echo "Creating token account..."
    spl-token create-account "$TOKEN_ADDRESS"
    if [[ $? -ne 0 ]]; then
        echo "Failed to create token account. Exiting."
        exit 1
    fi

    echo "Minting tokens..."
    spl-token mint "$TOKEN_ADDRESS" 10000
    if [[ $? -ne 0 ]]; then
        echo "Failed to mint tokens. Exiting."
        exit 1
    fi

    echo "Token operations completed successfully!"
}

private_key_conversion() {
    read -p "Please enter your private key (e.g., [content]): " private_key
    echo "private_key = $private_key" > sol.py
    echo "hex_key = ''.join(format(x, '02x') for x in private_key)" >> sol.py
    echo "print(hex_key)" >> sol.py

    echo "Running python3 sol.py..."
    python3 sol.py
    echo "Press any key to return to the main menu."
    read -n 1 -s
}

main_menu() {
    while true; do
        clear
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
        echo "============================ Eclipse Deployment Menu ================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press ctrl+c."
        echo "Please select an operation to perform:"
        echo "1) Deploy environment"
        echo "2) Create SPL token and perform operations"
        echo "3) Private key conversion"
        echo "4) Exit"

        read -p "Please enter your choice (1-4): " choice
        case $choice in
            1) deploy_environment ;;
            2) create_spl_and_operations ;;
            3) private_key_conversion ;;
            4) echo "Exiting script." ; exit 0 ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done
}

main_menu
