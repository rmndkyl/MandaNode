#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Script save path
SCRIPT_PATH="$HOME/Allora.sh"

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
        echo "============================ Allora Node Setup ==================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press ctrl + C to quit."
        echo "Please choose an action to perform:"
        echo "1) Deploy node"
        echo "2) View Worker container logs"
        echo "3) View Main logs"
        echo "4) Exit"
        read -p "Enter option: " option
        case $option in
            1) deploy_node;;
            2) view_worker_logs;;
            3) view_main_logs;;
            4) exit 0;;
            *) echo "Invalid option, please try again";;
        esac
        read -p "Press any key to continue..."
    done
}

# Deploy Node
function deploy_node() {
    # Install dependencies
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 python3 python3-pip

    # Check Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        docker version

        # Docker permissions
        sudo groupadd docker || true
        sudo usermod -aG docker $USER
    else
        echo -e "\e[32mDocker is already installed.\e[0m"
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        docker-compose --version
    else
        echo -e "\e[32mDocker Compose is already installed.\e[0m"
    fi

    # Set up Allora Worker Node
    echo -e "\e[33mHave you run this Allora worker node setup before? (yes/no)\e[0m"
    read -r has_run_before

    if [ "$has_run_before" == "yes" ]; then
        cd $HOME && cd basic-coin-prediction-node
        docker compose down -v
        docker container prune -f
        cd $HOME && rm -rf basic-coin-prediction-node
    fi

    # Clone Allora Chain
    git clone https://github.com/allora-network/allora-chain.git && cd allora-chain && make all
    cd $HOME

    # Clone and configure HuggingFace Worker Node
    cd $HOME
    git clone https://github.com/allora-network/allora-huggingface-walkthrough
    cd allora-huggingface-walkthrough
    mkdir -p worker-data
    chmod -R 777 worker-data
    cp config.example.json config.json

    # Request wallet mnemonic
    echo -e "\e[33mPlease enter your wallet mnemonic:\e[0m"
    read -r wallet_phrases

    # Request Coingecko API key
    echo -e "\e[33mPlease enter your Coingecko API key:\e[0m"
    read -r coingecko_api_key

    # Replace wallet mnemonic in config and include topics
    cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "testkey",
        "addressRestoreMnemonic": "$wallet_phrases",
        "alloraHomeDir": "/root/.allorad",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://allora-rpc.testnet.allora.network/",
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 1,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 3,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 3,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 4,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 2,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 5,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 4,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        },
        {
            "topicId": 6,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 2,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 8,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 3,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BNB"
            }
        },
        {
            "topicId": 9,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ARB"
            }
        }
    ]
}
EOF

    # Replace testkey with wallet name
    # wallet_name=$(allorad keys list | grep -o 'testkey')
    # sed -i "s/testkey/$wallet_name/g" config.json

    # If env file doesn't exist, create it
    if [ ! -f /root/allora-huggingface-walkthrough/worker-data/env_file ]; then
        cat <<EOF > /root/allora-huggingface-walkthrough/worker-data/env_file
WALLET_PHRASES="$wallet_phrases"
INFERENCE_ENDPOINT="http://inference:8000"
TOKEN="ETH"
EOF
        echo "Environment file created."
    fi

    # Set correct permissions for worker-data directory
    chmod -R 777 /root/allora-huggingface-walkthrough/worker-data

    # Automatically import Coingecko API key into app.py
    sed -i "s|\"x-cg-demo-api-key\": \".*\"|\"x-cg-demo-api-key\": \"$coingecko_api_key\"|g" app.py

    # Run Huggingface worker node
    chmod +x init.config
    ./init.config
    docker compose up --build -d
}

# View Worker container logs
function view_worker_logs() {
    cd $HOME/allora-huggingface-walkthrough && docker compose logs -f worker
}

# View Main logs
function view_main_logs() {
    cd $HOME/allora-huggingface-walkthrough && docker compose logs -f
}

# Call the main menu function
main_menu
