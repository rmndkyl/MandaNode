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

# Get node ID
echo ""
echo "Please enter your Node ID (digits only, e.g., 7366937):"
read -p "Node ID: " NODE_ID

# Clean and validate
NODE_ID=$(echo "$NODE_ID" | tr -d '[:space:]')
if [ -z "$NODE_ID" ]; then
    echo "❌ Error: Node ID cannot be empty."
    exit 1
fi
if ! [[ "$NODE_ID" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Node ID must be numeric. You entered: $NODE_ID"
    exit 1
fi

echo "✅ Node ID validated: $NODE_ID"

# Check for existing screen session
SESSION_NAME="nexus_${NODE_ID}"
if screen -list | grep -q "$SESSION_NAME"; then
    echo "Existing session found: $SESSION_NAME"
    read -p "Do you want to reconnect to it? (y/n): " choice
    if [[ $choice == "y" || $choice == "Y" ]]; then
        echo "Reconnecting..."
        screen -r "$SESSION_NAME"
        exit 0
    else
        echo "Killing existing session and creating new one..."
        screen -S "$SESSION_NAME" -X quit 2>/dev/null
    fi
fi

echo "Launching node: $NODE_ID"
echo "Screen session: $SESSION_NAME"
echo ""
echo "=== Screen Usage Guide ==="
echo "• Detach session: Ctrl+A then D"
echo "• Reattach: screen -r $SESSION_NAME"
echo "• List sessions: screen -list"
echo "• Stop script: Ctrl+C inside session"
echo "==========================="
echo ""

# Launch inside screen with PATH fix
screen -dmS "$SESSION_NAME" bash -c '
export PATH="$HOME/.nexus/bin:$PATH"
echo "=== Nexus Node Running ==="
echo "Node ID: '"$NODE_ID"'"
echo "Session Name: '"$SESSION_NAME"'"
echo "Start Time: $(date)"
echo ""

while true; do
    echo "$(date): Starting node '"$NODE_ID"'"
    nexus-network start --node-id "'"$NODE_ID"'"
    echo "$(date): Node stopped. Restarting in 2 hours..."
    sleep 7200
done
'

echo "✅ Node is now running in a screen session!"
echo ""
echo "📋 Common commands:"
echo "• Check sessions: screen -list"
echo "• Reconnect: screen -r $SESSION_NAME"
echo "• Detach: Ctrl+A then D"
echo "• Stop node: screen -S $SESSION_NAME -X quit"
echo ""
echo "🌐 You can now safely close SSH — the node will keep running!"
