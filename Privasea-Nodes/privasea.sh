#!/bin/bash

# Show Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Define colors for output messages
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Function to display success messages
success_message() {
    echo -e "${GREEN}[✔] $1${NC}"
}

# Function to display informational messages
info_message() {
    echo -e "${CYAN}[-] $1...${NC}"
}

# Function to display error messages
error_message() {
    echo -e "${RED}[✘] $1${NC}"
}

# New function to import existing keystore
import_keystore() {
    local import_choice
    
    # Prompt for keystore import
    read -p "Do you want to import an existing keystore? (y/n): " import_choice
    
    if [[ "$import_choice" == "y" ]]; then
        # Ensure configuration directory exists
        mkdir -p "$HOME/privasea/config"
        
        while true; do
            # Prompt for keystore file path
            read -p "Enter the full path to your keystore file: " KEYSTORE_PATH
            
            # Validate keystore file
            if [[ ! -f "$KEYSTORE_PATH" ]]; then
                error_message "Keystore file not found at the specified path."
                read -p "Do you want to try again? (y/n): " retry_choice
                
                if [[ "$retry_choice" != "y" ]]; then
                    return 1
                fi
                continue
            fi
            
            # Check keystore file format
            if [[ ! "$KEYSTORE_PATH" =~ UTC-- ]]; then
                error_message "Invalid keystore file format."
                read -p "Do you want to try again? (y/n): " retry_choice
                
                if [[ "$retry_choice" != "y" ]]; then
                    return 1
                fi
                continue
            fi
            
            # Copy keystore to config directory
            if cp "$KEYSTORE_PATH" "$HOME/privasea/config/wallet_keystore"; then
                success_message "Keystore imported successfully to $HOME/privasea/config/wallet_keystore"
                return 0
            else
                error_message "Failed to copy keystore file."
                return 1
            fi
        done
    fi
    
    return 0
}

# Clear the screen
clear
echo -e "${CYAN}========================================"
echo "   Privasea Acceleration Node Setup"
echo -e "========================================${NC}\n"

# Step 1: Check if Docker is installed
if ! command -v docker &>/dev/null; then
    info_message "Docker not found, starting installation..."
    
    # Install required dependencies
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    # Add Docker repository
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    # Update package index and install Docker
    sudo apt update && sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker

    success_message "Docker successfully installed and started."
else
    success_message "Docker is already installed. Skipping installation."
fi

echo ""

# Step 2: Pull Docker image
info_message "Downloading Docker image"
if docker pull privasea/acceleration-node-beta:latest; then
    success_message "Docker image downloaded successfully."
else
    error_message "Failed to download Docker image."
    exit 1
fi

echo ""

# Step 3: Create configuration directory
info_message "Creating configuration directory"
if mkdir -p "$HOME/privasea/config"; then
    success_message "Configuration directory created successfully."
else
    error_message "Failed to create configuration directory."
    exit 1
fi

echo ""

# Step 4: Keystore Management
info_message "Keystore Management"
if [[ -f "$HOME/privasea/config/wallet_keystore" ]]; then
    info_message "Existing keystore found in configuration directory"
    
    # Prompt for action
    read -p "Do you want to (R)eplace or (K)eep existing keystore? (R/K): " keystore_action
    
    case "${keystore_action,,}" in
        r)
            # Remove existing keystore
            rm "$HOME/privasea/config/wallet_keystore"
            
            # Prompt for generation or import
            read -p "Do you want to (G)enerate a new keystore or (I)mport? (G/I): " keystore_choice
            
            case "${keystore_choice,,}" in
                g)
                    # Generate new keystore
                    info_message "Generating new keystore"
                    if docker run -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
                        success_message "New keystore generated successfully."
                    else
                        error_message "Failed to generate new keystore."
                        exit 1
                    fi
                    ;;
                i)
                    # Import keystore
                    import_keystore || exit 1
                    ;;
                *)
                    error_message "Invalid choice. Exiting."
                    exit 1
                    ;;
            esac
            ;;
        k)
            info_message "Using existing keystore"
            ;;
        *)
            error_message "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    # No existing keystore
    read -p "Do you want to (G)enerate a new keystore or (I)mport? (G/I): " keystore_choice
    
    case "${keystore_choice,,}" in
        g)
            # Generate new keystore
            info_message "Generating new keystore"
            if docker run -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
                success_message "New keystore generated successfully."
            else
                error_message "Failed to generate new keystore."
                exit 1
            fi
            ;;
        i)
            # Import keystore
            import_keystore || exit 1
            ;;
        *)
            error_message "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Rename keystore if generated with UTC-- prefix
if [[ -n "$(ls "$HOME/privasea/config/UTC--"* 2>/dev/null)" ]]; then
    KEYSTORE_FILE=$(ls -t "$HOME/privasea/config/UTC--"* | head -n1)
    mv "$KEYSTORE_FILE" "$HOME/privasea/config/wallet_keystore"
fi

echo ""

# Step 5: Prompt to continue
read -p "Do you want to proceed with running the node? (y/n): " choice
if [[ "$choice" != "y" ]]; then
    echo -e "${CYAN}Process aborted.${NC}"
    exit 0
fi

# Step 6: Request keystore password
info_message "Enter password for keystore (to access the node):"
read -s KEystorePassword
echo ""

# Step 7: Run the Privasea Acceleration Node
info_message "Starting Privasea Acceleration Node"
if docker run -d -v "$HOME/privasea/config:/app/config" \
-e KEYSTORE_PASSWORD="$KEystorePassword" \
privasea/acceleration-node-beta:latest; then
    success_message "Node started successfully."
else
    error_message "Failed to start the node."
    exit 1
fi

echo ""

# Final step: Display completion message
echo -e "${GREEN}========================================"
echo "   Script by LayerAirdrop"
echo -e "========================================${NC}\n"
echo -e "${CYAN}Configuration files are available at:${NC} $HOME/privasea/config"
echo -e "${CYAN}Keystore saved as:${NC} wallet_keystore"
echo -e "${CYAN}Keystore password used:${NC} $KEystorePassword\n"
