#!/bin/bash

# Display banner
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y screen
    elif command -v yum &> /dev/null; then
        sudo yum install -y screen
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y screen
    else
        echo "Error: Unable to install screen automatically. Please install it manually."
        exit 1
    fi
    echo "Screen installation complete!"
fi

# Install nexus-cli if not already installed
if ! command -v nexus-network &> /dev/null; then
    echo "Installing nexus-cli..."
    curl https://cli.nexus.xyz/ | sh
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null
    echo "Installation complete!"
fi

# Get node ID from user
echo ""
echo "Please enter your Node ID (digits only, e.g., 7366937):"
read -p "Node ID: " NODE_ID

# Clean input (remove spaces and special characters)
NODE_ID=$(echo "$NODE_ID" | tr -d '[:space:]')

# Validate node ID
if [ -z "$NODE_ID" ]; then
    echo "❌ Error: Node ID cannot be empty."
    echo "Please rerun the script and enter a valid Node ID."
    exit 1
fi

# Ensure only digits are entered
if ! [[ "$NODE_ID" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Node ID should contain digits only."
    echo "Your input: $NODE_ID"
    echo "Please rerun the script and enter a valid Node ID."
    exit 1
fi

echo "✅ Node ID validated: $NODE_ID"

# Check for existing screen session with the same name
SESSION_NAME="nexus_${NODE_ID}"
if screen -list | grep -q "$SESSION_NAME"; then
    echo "Existing session found: $SESSION_NAME"
    read -p "Do you want to reconnect to the existing session? (y/n): " choice
    if [[ $choice == "y" || $choice == "Y" ]]; then
        echo "Reconnecting to existing session..."
        screen -r "$SESSION_NAME"
        exit 0
    else
        echo "Terminating existing session and creating a new one..."
        screen -S "$SESSION_NAME" -X quit 2>/dev/null
    fi
fi

echo "Starting node: $NODE_ID"
echo "Screen session name: $SESSION_NAME"
echo ""
echo "=== Screen Usage Guide ==="
echo "• Detach session: Ctrl+A then D"
echo "• Reattach session: screen -r $SESSION_NAME"
echo "• List sessions: screen -list"
echo "• Stop script: Press Ctrl+C in the session"
echo "==========================="
echo ""

# Run the node inside a detached screen session
screen -dmS "$SESSION_NAME" bash -c "
echo '=== Nexus Node Running ==='
echo 'Node ID: $NODE_ID'
echo 'Session Name: $SESSION_NAME'
echo 'Start Time: \$(date)'
echo ''

# Main loop
while true; do
    echo \"\$(date): Starting node $NODE_ID\"
    nexus-network start --node-id \"$NODE_ID\"
    echo \"\$(date): Node stopped, restarting in 2 hours...\"
    sleep 7200
done
"

echo "✅ Node is now running in a screen session!"
echo ""
echo "📋 Useful commands:"
echo "• Check sessions: screen -list"
echo "• Reconnect to session: screen -r $SESSION_NAME"
echo "• Detach session: Press Ctrl+A then D inside session"
echo "• Stop node: screen -S $SESSION_NAME -X quit"
echo ""
echo "🌐 You can now safely close your SSH connection. The node will keep running in the background!"
