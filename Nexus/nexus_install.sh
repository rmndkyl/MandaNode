#!/bin/bash
set -e

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

BASE_CONTAINER_NAME="nexus-node"
IMAGE_NAME="nexus-node:latest"
LOG_DIR="/root/nexus_logs"

# Check if Docker is installed
function check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker not detected, installing..."
        apt update
        apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        apt update
        apt install -y docker-ce
        systemctl enable docker
        systemctl start docker
    fi
}

# Check if Node.js/npm/pm2 are installed
function check_pm2() {
    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        echo "Node.js/npm not detected, installing..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    if ! command -v pm2 >/dev/null 2>&1; then
        echo "PM2 not detected, installing..."
        npm install -g pm2
    fi
}

# Build Docker image function
function build_image() {
    WORKDIR=$(mktemp -d)
    cd "$WORKDIR"

    cat > Dockerfile <<EOF
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PROVER_ID_FILE=/root/.nexus/node-id

RUN apt-get update && apt-get install -y \
    curl \
    screen \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Auto-download and install latest nexus-network
RUN curl -sSL https://cli.nexus.xyz/ | NONINTERACTIVE=1 sh \
    && ln -sf /root/.nexus/bin/nexus-network /usr/local/bin/nexus-network

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
EOF

    cat > entrypoint.sh <<EOF
#!/bin/bash
set -e

PROVER_ID_FILE="/root/.nexus/node-id"

if [ -z "\$NODE_ID" ]; then
    echo "Error: NODE_ID environment variable not set"
    exit 1
fi

echo "\$NODE_ID" > "\$PROVER_ID_FILE"
echo "Using node-id: \$NODE_ID"

if ! command -v nexus-network >/dev/null 2>&1; then
    echo "Error: nexus-network not installed or unavailable"
    exit 1
fi

screen -S nexus -X quit >/dev/null 2>&1 || true

echo "Starting nexus-network node..."
screen -dmS nexus bash -c "nexus-network start --node-id \$NODE_ID &>> /root/nexus.log"

sleep 3

if screen -list | grep -q "nexus"; then
    echo "Node started in background."
    echo "Log file: /root/nexus.log"
    echo "Use 'docker logs \$CONTAINER_NAME' to view logs"
else
    echo "Node startup failed, please check logs."
    cat /root/nexus.log
    exit 1
fi

tail -f /root/nexus.log
EOF

    docker build -t "$IMAGE_NAME" .

    cd -
    rm -rf "$WORKDIR"
}

# Start container (mount host log file)
function run_container() {
    local node_id=$1
    local container_name="${BASE_CONTAINER_NAME}-${node_id}"
    local log_file="${LOG_DIR}/nexus-${node_id}.log"

    if docker ps -a --format '{{.Names}}' | grep -qw "$container_name"; then
        echo "Old container $container_name detected, removing first..."
        docker rm -f "$container_name"
    fi

    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Ensure host log file exists and has write permissions
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
        chmod 644 "$log_file"
    fi

    docker run -d --name "$container_name" -v "$log_file":/root/nexus.log -e NODE_ID="$node_id" "$IMAGE_NAME"
    echo "Container $container_name started!"
}

# Stop and uninstall container, image, and delete logs
function uninstall_node() {
    local node_id=$1
    local container_name="${BASE_CONTAINER_NAME}-${node_id}"
    local log_file="${LOG_DIR}/nexus-${node_id}.log"

    echo "Stopping and removing container $container_name..."
    docker rm -f "$container_name" 2>/dev/null || echo "Container doesn't exist or already stopped"

    if [ -f "$log_file" ]; then
        echo "Deleting log file $log_file ..."
        rm -f "$log_file"
    else
        echo "Log file doesn't exist: $log_file"
    fi

    echo "Node $node_id uninstalled successfully."
}

# Display all running nodes
function list_nodes() {
    echo "Current node status:"
    echo "------------------------------------------------------------------------------------------------------------------------"
    printf "%-6s %-20s %-10s %-10s %-10s %-20s %-20s\n" "No." "Node ID" "CPU Usage" "Memory" "Mem Limit" "Status" "Created"
    echo "------------------------------------------------------------------------------------------------------------------------"
    
    local all_nodes=($(get_all_nodes))
    for i in "${!all_nodes[@]}"; do
        local node_id=${all_nodes[$i]}
        local container_name="${BASE_CONTAINER_NAME}-${node_id}"
        local container_info=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" $container_name 2>/dev/null)
        
        if [ -n "$container_info" ]; then
            # Parse container info
            IFS=',' read -r cpu_usage mem_usage mem_limit mem_perc <<< "$container_info"
            local status=$(docker ps -a --filter "name=$container_name" --format "{{.Status}}")
            local created_time=$(docker ps -a --filter "name=$container_name" --format "{{.CreatedAt}}")
            
            # Format memory display
            mem_usage=$(echo $mem_usage | sed 's/\([0-9.]*\)\([A-Za-z]*\)/\1 \2/')
            mem_limit=$(echo $mem_limit | sed 's/\([0-9.]*\)\([A-Za-z]*\)/\1 \2/')
            
            # Display node info
            printf "%-6d %-20s %-10s %-10s %-10s %-20s %-20s\n" \
                $((i+1)) \
                "$node_id" \
                "$cpu_usage" \
                "$mem_usage" \
                "$mem_limit" \
                "$(echo $status | cut -d' ' -f1)" \
                "$created_time"
        else
            # If container doesn't exist or isn't running
            local status=$(docker ps -a --filter "name=$container_name" --format "{{.Status}}")
            local created_time=$(docker ps -a --filter "name=$container_name" --format "{{.CreatedAt}}")
            if [ -n "$status" ]; then
                printf "%-6d %-20s %-10s %-10s %-10s %-20s %-20s\n" \
                    $((i+1)) \
                    "$node_id" \
                    "N/A" \
                    "N/A" \
                    "N/A" \
                    "$(echo $status | cut -d' ' -f1)" \
                    "$created_time"
            fi
        fi
    done
    echo "------------------------------------------------------------------------------------------------------------------------"
    echo "Tips:"
    echo "- CPU Usage: Shows container CPU usage percentage"
    echo "- Memory: Shows container current memory usage"
    echo "- Mem Limit: Shows container memory usage limit"
    echo "- Status: Shows container running status"
    echo "- Created: Shows container creation time"
    read -p "Press any key to return to menu"
}

# Get all running node IDs
function get_running_nodes() {
    docker ps --filter "name=${BASE_CONTAINER_NAME}" --filter "status=running" --format "{{.Names}}" | sed "s/${BASE_CONTAINER_NAME}-//"
}

# Get all node IDs (including stopped ones)
function get_all_nodes() {
    docker ps -a --filter "name=${BASE_CONTAINER_NAME}" --format "{{.Names}}" | sed "s/${BASE_CONTAINER_NAME}-//"
}

# View node logs
function view_node_logs() {
    local node_id=$1
    local container_name="${BASE_CONTAINER_NAME}-${node_id}"
    
    if docker ps -a --format '{{.Names}}' | grep -qw "$container_name"; then
        echo "Please select log viewing mode:"
        echo "1. Raw logs (may contain color codes)"
        echo "2. Clean logs (remove color codes)"
        read -rp "Please choose (1-2): " log_mode

        echo "Viewing logs, press Ctrl+C to exit log view"
        if [ "$log_mode" = "2" ]; then
            docker logs -f "$container_name" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/\x1b\[?25l//g' | sed 's/\x1b\[?25h//g'
        else
            docker logs -f "$container_name"
        fi
    else
        echo "Container not running, please install and start node first (option 1)"
        read -p "Press any key to return to menu"
    fi
}

# Batch start multiple nodes
function batch_start_nodes() {
    echo "Please enter multiple node-ids, one per line, empty line to finish:"
    echo "(After finishing input, press Enter, then press Ctrl+D to end input)"
    
    local node_ids=()
    while read -r line; do
        if [ -n "$line" ]; then
            node_ids+=("$line")
        fi
    done

    if [ ${#node_ids[@]} -eq 0 ]; then
        echo "No node-id entered, returning to main menu"
        read -p "Press any key to continue"
        return
    fi

    echo "Starting to build image..."
    build_image

    echo "Starting to launch nodes..."
    for node_id in "${node_ids[@]}"; do
        echo "Starting node $node_id ..."
        run_container "$node_id"
        sleep 2  # Add brief delay to avoid starting too many containers simultaneously
    done

    echo "All nodes started successfully!"
    read -p "Press any key to return to menu"
}

# Select node to view
function select_node_to_view() {
    local all_nodes=($(get_all_nodes))
    
    if [ ${#all_nodes[@]} -eq 0 ]; then
        echo "No nodes currently available"
        read -p "Press any key to return to menu"
        return
    fi

    echo "Please select node to view:"
    echo "0. Return to main menu"
    for i in "${!all_nodes[@]}"; do
        local node_id=${all_nodes[$i]}
        local container_name="${BASE_CONTAINER_NAME}-${node_id}"
        local status=$(docker ps -a --filter "name=$container_name" --format "{{.Status}}")
        if [[ $status == Up* ]]; then
            echo "$((i+1)). Node $node_id [Running]"
        else
            echo "$((i+1)). Node $node_id [Stopped]"
        fi
    done

    read -rp "Please enter option (0-${#all_nodes[@]}): " choice

    if [ "$choice" = "0" ]; then
        return
    fi

    if [ "$choice" -ge 1 ] && [ "$choice" -le ${#all_nodes[@]} ]; then
        local selected_node=${all_nodes[$((choice-1))]}
        view_node_logs "$selected_node"
    else
        echo "Invalid option"
        read -p "Press any key to continue"
    fi
}

# Batch stop and uninstall nodes
function batch_uninstall_nodes() {
    local all_nodes=($(get_all_nodes))
    
    if [ ${#all_nodes[@]} -eq 0 ]; then
        echo "No nodes currently available"
        read -p "Press any key to return to menu"
        return
    fi

    echo "Current node status:"
    echo "----------------------------------------"
    echo "No.   Node ID              Status"
    echo "----------------------------------------"
    for i in "${!all_nodes[@]}"; do
        local node_id=${all_nodes[$i]}
        local container_name="${BASE_CONTAINER_NAME}-${node_id}"
        local status=$(docker ps -a --filter "name=$container_name" --format "{{.Status}}")
        if [[ $status == Up* ]]; then
            printf "%-6d %-20s [Running]\n" $((i+1)) "$node_id"
        else
            printf "%-6d %-20s [Stopped]\n" $((i+1)) "$node_id"
        fi
    done
    echo "----------------------------------------"

    echo "Please select nodes to delete (multiple selection allowed, enter numbers separated by spaces):"
    echo "0. Return to main menu"
    
    read -rp "Please enter options (0 or numbers separated by spaces): " choices

    if [ "$choices" = "0" ]; then
        return
    fi

    # Convert input options to array
    read -ra selected_choices <<< "$choices"
    
    # Validate input and execute uninstall
    for choice in "${selected_choices[@]}"; do
        if [ "$choice" -ge 1 ] && [ "$choice" -le ${#all_nodes[@]} ]; then
            local selected_node=${all_nodes[$((choice-1))]}
            echo "Uninstalling node $selected_node ..."
            uninstall_node "$selected_node"
        else
            echo "Skipping invalid option: $choice"
        fi
    done

    echo "Batch uninstall completed!"
    read -p "Press any key to return to menu"
}

# Delete all nodes
function uninstall_all_nodes() {
    local all_nodes=($(get_all_nodes))
    
    if [ ${#all_nodes[@]} -eq 0 ]; then
        echo "No nodes currently available"
        read -p "Press any key to return to menu"
        return
    fi

    echo "Warning: This operation will delete all nodes!"
    echo "Currently there are ${#all_nodes[@]} nodes:"
    for node_id in "${all_nodes[@]}"; do
        echo "- $node_id"
    done
    
    read -rp "Are you sure you want to delete all nodes? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        read -p "Press any key to return to menu"
        return
    fi

    echo "Starting to delete all nodes..."
    for node_id in "${all_nodes[@]}"; do
        echo "Uninstalling node $node_id ..."
        uninstall_node "$node_id"
    done

    # Delete /root/nexus_scripts directory
    if [ -d "/root/nexus_scripts" ]; then
        echo "Deleting /root/nexus_scripts directory..."
        rm -rf "/root/nexus_scripts"
    else
        echo "/root/nexus_scripts directory doesn't exist"
    fi

    echo "All nodes deleted successfully!"
    read -p "Press any key to return to menu"
}

# Batch node rotation startup
function batch_rotate_nodes() {
    check_pm2
    echo "Please enter multiple node-ids, one per line, empty line to finish:"
    echo "(After finishing input, press Enter, then press Ctrl+D to end input)"
    
    local node_ids=()
    while read -r line; do
        if [ -n "$line" ]; then
            node_ids+=("$line")
        fi
    done

    if [ ${#node_ids[@]} -eq 0 ]; then
        echo "No node-id entered, returning to main menu"
        read -p "Press any key to continue"
        return
    fi

    # Set number of nodes to start every two hours
    read -rp "Please enter number of nodes to start every two hours (default: half of ${#node_ids[@]}, rounded up): " nodes_per_round
    if [ -z "$nodes_per_round" ]; then
        nodes_per_round=$(( (${#node_ids[@]} + 1) / 2 ))
    fi

    # Validate input
    if ! [[ "$nodes_per_round" =~ ^[0-9]+$ ]] || [ "$nodes_per_round" -lt 1 ] || [ "$nodes_per_round" -gt ${#node_ids[@]} ]; then
        echo "Invalid number of nodes, please enter a number between 1 and ${#node_ids[@]}"
        read -p "Press any key to return to menu"
        return
    fi

    # Calculate how many groups needed
    local total_nodes=${#node_ids[@]}
    local num_groups=$(( (total_nodes + nodes_per_round - 1) / nodes_per_round ))
    echo "Nodes will be divided into $num_groups groups for rotation"

    # Directly delete old rotation processes
    echo "Stopping old rotation processes..."
    pm2 delete nexus-rotate 2>/dev/null || true

    echo "Starting to build image..."
    build_image

    # Create startup script directory
    local script_dir="/root/nexus_scripts"
    mkdir -p "$script_dir"

    # Create startup script for each group
    for ((group=1; group<=num_groups; group++)); do
        cat > "$script_dir/start_group${group}.sh" <<EOF
#!/bin/bash
set -e

# Stop and remove all existing containers
docker ps -a --filter "name=${BASE_CONTAINER_NAME}" --format "{{.Names}}" | xargs -r docker rm -f

# Start group ${group} nodes
EOF
    done

    # Add nodes to corresponding startup scripts
    for i in "${!node_ids[@]}"; do
        local node_id=${node_ids[$i]}
        local container_name="${BASE_CONTAINER_NAME}-${node_id}"
        local log_file="${LOG_DIR}/nexus-${node_id}.log"
        
        # Calculate which group the node belongs to
        local group_num=$(( i / nodes_per_round + 1 ))
        if [ $group_num -gt $num_groups ]; then
            group_num=$num_groups
        fi
        
        # Ensure log directory and file exist
        mkdir -p "$LOG_DIR"
        # If log file is a directory, delete it first
        if [ -d "$log_file" ]; then
            rm -rf "$log_file"
        fi
        # Create log file if it doesn't exist
        if [ ! -f "$log_file" ]; then
            touch "$log_file"
            chmod 644 "$log_file"
        fi

        # Add to corresponding group startup script
        echo "echo \"[$(date '+%Y-%m-%d %H:%M:%S')] Starting node $node_id ...\"" >> "$script_dir/start_group${group_num}.sh"
        echo "docker run -d --name $container_name -v $log_file:/root/nexus.log -e NODE_ID=$node_id $IMAGE_NAME" >> "$script_dir/start_group${group_num}.sh"
        echo "sleep 30" >> "$script_dir/start_group${group_num}.sh"
    done

    # Create rotation script
    cat > "$script_dir/rotate.sh" <<EOF
#!/bin/bash
set -e

while true; do
EOF

    # Add each group startup command to rotation script
    for ((group=1; group<=num_groups; group++)); do
        # Calculate current group node count
        local start_idx=$(( (group-1) * nodes_per_round ))
        local end_idx=$(( group * nodes_per_round ))
        if [ $end_idx -gt $total_nodes ]; then
            end_idx=$total_nodes
        fi
        local current_group_nodes=$(( end_idx - start_idx ))

        cat >> "$script_dir/rotate.sh" <<EOF
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting group ${group} nodes (${current_group_nodes} nodes)..."
    bash "$script_dir/start_group${group}.sh"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for 2 hours..."
    sleep 7200

EOF
    done

    # Complete rotation script
    echo "done" >> "$script_dir/rotate.sh"

    # Set script permissions
    chmod +x "$script_dir"/*.sh

    # Start rotation script with pm2
    pm2 start "$script_dir/rotate.sh" --name "nexus-rotate"
    pm2 save

    echo "Node rotation started!"
    echo "Total $total_nodes nodes, divided into $num_groups groups"
    echo "Each group starts $nodes_per_round nodes (last group may have fewer), rotating every 2 hours"
    echo "Use 'pm2 status' to view running status"
    echo "Use 'pm2 logs nexus-rotate' to view rotation logs"
    echo "Use 'pm2 stop nexus-rotate' to stop rotation"
    read -p "Press any key to return to menu"
}

# Set up scheduled log cleanup task (clean every 2 days, keep only last 2 days of logs)
function setup_log_cleanup_cron() {
    local cron_job="0 3 */2 * * find $LOG_DIR -type f -name 'nexus-*.log' -mtime +2 -delete"
    # Check if same cron job already exists
    (crontab -l 2>/dev/null | grep -v -F "$cron_job"; echo "$cron_job") | crontab -
    echo "Set up automatic cleanup task to run every 2 days, keeping only last 2 days of logs."
}

# Main menu
setup_log_cleanup_cron
while true; do
    clear
    echo "Script written by Hahahaha, Twitter @ferdie_jhovie, free and open source, don't trust paid versions"
    echo "If you have issues, contact Twitter, this is the only official account"
    echo "========== Nexus Multi-Node Management =========="
    echo "1. Install and start new node"
    echo "2. Show all node status"
    echo "3. Batch stop and uninstall specific nodes"
    echo "4. View specific node logs"
    echo "5. Batch node rotation startup"
    echo "6. Delete all nodes"
    echo "7. Exit"
    echo "=============================================="

    read -rp "Please enter option (1-7): " choice

    case $choice in
        1)
            check_docker
            read -rp "Please enter your node-id: " NODE_ID
            if [ -z "$NODE_ID" ]; then
                echo "Node-id cannot be empty, please select again."
                read -p "Press any key to continue"
                continue
            fi
            echo "Starting to build image and start container..."
            build_image
            run_container "$NODE_ID"
            read -p "Press any key to return to menu"
            ;;
        2)
            list_nodes
            ;;
        3)
            batch_uninstall_nodes
            ;;
        4)
            select_node_to_view
            ;;
        5)
            check_docker
            batch_rotate_nodes
            ;;
        6)
            uninstall_all_nodes
            ;;
        7)
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "Invalid option, please re-enter."
            read -p "Press any key to continue"
            ;;
    esac
done
