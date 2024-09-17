#!/bin/bash
log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}
print_green() {
    echo -e "\e[32m$1\e[0m"
}

get_node_info() {
    NODE_ID=$(cat $HOME/.nesa/identity/node_id.id)
    IP_ADDRESS=$(curl -s ifconfig.me)
    print_green "Node ID and IP information retrieved successfully"
}

check_ipfs_status() {
    if docker ps | grep -q ipfs_node; then
        print_green "IPFS is running."
        return 0
    else
        print_green "IPFS is not running."
        return 1
    fi
}

restart_orchestrator() {
    print_green "Restarting Orchestrator..."
    docker stop orchestrator 2>/dev/null
    docker rm orchestrator 2>/dev/null
    docker run -d --name orchestrator --network docker_nesa -v $HOME/.nesa:/root/.nesa ghcr.io/nesaorg/orchestrator:devnet-latest
    print_green "Orchestrator restarted. Waiting for 1 minute before rechecking..."
    sleep 60
}

check_node_status() {
    if ! docker ps | grep -q orchestrator; then
        print_green "Node status: Down (Orchestrator container is not running)"
        return 1
    fi

    local api_status=$(curl -s http://localhost:31333/status | jq -r '.status' 2>/dev/null)
    local log_status=$(docker logs orchestrator --tail 100 2>/dev/null | grep "Node status" | tail -n 1)

    if [[ "$api_status" == "UP" ]] || [[ $log_status == *"UP"* ]]; then
        print_green "Node status: Up"
        return 0
    else
        print_green "Node status: Down or Unknown"
        return 1
    fi
}

add_ipfs_peers() {
    print_green "Adding IPFS peers..."
    docker exec ipfs_node ipfs swarm connect /dns4/node-1.nesa.ai/tcp/4001/p2p/12D3KooWQYBPcvxFnnWzPGEx6JuBnrbBhMvzuQnVmgiRYy6AzwTY || print_green "Failed to connect to node-1"
    docker exec ipfs_node ipfs swarm connect /dns4/node-2.nesa.ai/tcp/4001/p2p/12D3KooWRBYMuSKLbPLMKwwA4V4TEQ3qC4sB3wMhrzGXKfTNHo1t || print_green "Failed to connect to node-2"
    docker exec ipfs_node ipfs swarm connect /dns4/node-3.nesa.ai/tcp/4001/p2p/12D3KooWNMVN9PbKXcoqHjj5QGvXCG9oS7yoTVz1jHbKFoSNhMZV || print_green "Failed to connect to node-3"
    print_green "IPFS peers addition attempt completed."
}

fix_ipfs() {
    print_green "Starting IPFS fix process..."
    
    print_green "Stopping and removing existing IPFS container..."
    docker stop ipfs_node 2>/dev/null
    docker rm ipfs_node 2>/dev/null

    print_green "Cleaning up IPFS volumes..."
    cd ~/.nesa/docker
    docker compose -f compose.community.yml down ipfs
    docker volume rm docker_ipfs-data docker_ipfs-staging

    print_green "Starting IPFS container..."
    docker compose -f compose.community.yml up -d ipfs

    print_green "Configuring CORS for IPFS..."
    docker exec ipfs_node ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://'$IP_ADDRESS':5001", "http://localhost:3000", "http://127.0.0.1:5001", "https://webui.ipfs.io"]'
    docker exec ipfs_node ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'

    print_green "Enabling Pubsub and updating bootstrap nodes..."
    docker exec ipfs_node ipfs config --json Experimental.Pubsub true
    docker exec ipfs_node ipfs bootstrap add --default
    docker exec ipfs_node ipfs bootstrap add /dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN

    print_green "Restarting IPFS container..."
    docker restart ipfs_node

    print_green "Opening firewall ports..."
    sudo ufw allow 5001
    sudo ufw allow 4001

    add_ipfs_peers
}

check_peer_count() {
    local peer_count=$(docker exec ipfs_node ipfs swarm peers | wc -l)
    print_green "Current peer count: $peer_count"
    return $peer_count
}


add_more_peers() {
    print_green "Adding more peers..."
    docker exec ipfs_node ipfs swarm connect /dns4/node-1.nesa.ai/tcp/4001/p2p/12D3KooWQYBPcvxFnnWzPGEx6JuBnrbBhMvzuQnVmgiRYy6AzwTY
    docker exec ipfs_node ipfs swarm connect /dns4/node-2.nesa.ai/tcp/4001/p2p/12D3KooWRBYMuSKLbPLMKwwA4V4TEQ3qC4sB3wMhrzGXKfTNHo1t
    docker exec ipfs_node ipfs swarm connect /dns4/node-3.nesa.ai/tcp/4001/p2p/12D3KooWNMVN9PbKXcoqHjj5QGvXCG9oS7yoTVz1jHbKFoSNhMZV
    docker exec ipfs_node ipfs swarm connect /dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN
    docker exec ipfs_node ipfs swarm connect /dnsaddr/bootstrap.libp2p.io/p2p/QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa
    docker exec ipfs_node ipfs swarm connect /dnsaddr/bootstrap.libp2p.io/p2p/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb
    sleep 10
}

main() {
    print_green "Starting IPFS node check..."
    get_node_info

    if check_ipfs_status; then
        print_green "IPFS is already running. Checking peer connections..."
        check_peer_count
        peer_count=$?
        
        if [ $peer_count -lt 3 ]; then
            print_green "Peer count is low. Adding more peers..."
            add_more_peers
            check_peer_count
        fi
        
        print_green "Current IPFS peers:"
        docker exec ipfs_node ipfs swarm peers
    else
        print_green "IPFS is not running. Starting fix process..."
        fix_ipfs
        if check_ipfs_status; then
            print_green "IPFS has been successfully started. Checking peer connections..."
            check_peer_count
            peer_count=$?
            
            if [ $peer_count -lt 3 ]; then
                print_green "Peer count is low. Adding more peers..."
                add_more_peers
                check_peer_count
            fi
            
            print_green "Current IPFS peers:"
            docker exec ipfs_node ipfs swarm peers
        else
            print_green "Failed to start IPFS. Please check manually."
        fi
    fi

    print_green "Checking node status..."
    if ! check_node_status; then
        print_green "Node is down. Attempting to restart Orchestrator..."
        restart_orchestrator
        print_green "Rechecking node status after restart..."
        check_node_status
    fi

    print_green "IPFS WebUI: http://$IP_ADDRESS:5001/webui"
    print_green "Node status: https://node.nesa.ai/nodes/$NODE_ID"
}

main
