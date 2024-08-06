#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as root."
    echo "Please try using 'sudo -i' to switch to the root user and then run this script again."
    exit 1
fi

function install_node() {

# Read and load identity code
read -p "Enter your identity code: " id

# Ask the user for the number of containers they want to create
read -p "Please enter the number of nodes you want to create (maximum of 5 per IP; it's currently recommended to create only 1 node for the highest efficiency): " container_count

# Ask the user for the storage size they want to allocate per node
read -p "Please enter the storage size you want to allocate per node (GB), with a single upper limit of 2TB. After setting, you need to execute 'docker restart <container_name>' to take effect: " storage_gb

# Ask the user for the storage path (optional)
read -p "Please enter the host path for storing node data (press Enter to use the default path titan_storage_$i, incremented by number): " custom_storage_path

apt update

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not detected, installing..."
    apt-get install ca-certificates curl gnupg lsb-release -y
    
    # Install the latest version of Docker
    apt-get install docker.io -y
else
    echo "Docker is already installed."
fi

# Pull Docker image
docker pull nezha123/titan-edge:1.7_amd64

# Create the specified number of containers
for i in $(seq 1 $container_count)
do
    # Check if the user has provided a custom storage path
    if [ -z "$custom_storage_path" ]; then
        # User did not provide a custom path, use the default path
        storage_path="$PWD/titan_storage_$i"
    else
        # User provided a custom path, use the provided path
        storage_path="$custom_storage_path"
    fi

    # Ensure the storage path exists
    mkdir -p "$storage_path"

    # Run the container and set the restart policy to always
    container_id=$(docker run -d --restart always -v "$storage_path:/root/.titanedge/storage" --name "titan$i" --net=host nezha123/titan-edge:1.7_amd64)

    echo "Node titan$i has started, Container ID $container_id"

    sleep 30

    # Modify the config.toml file on the host to set the StorageGB value
    docker exec $container_id bash -c "\
        sed -i 's/^[[:space:]]*#StorageGB = .*/StorageGB = $storage_gb/' /root/.titanedge/config.toml && \
        echo 'The storage space of container titan'$i' has been set to $storage_gb GB'"

    # Enter the container and execute binding and other commands
    docker exec $container_id bash -c "\
        titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
done

echo "==============================All nodes have been set up and started===================================."

}

# Uninstall node function
function uninstall_node() {
    echo "Are you sure you want to uninstall the Titan node program? This will delete all associated data. [Y/N]"
    read -r -p "Please confirm: " response

    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Starting to uninstall node program..."
            for i in {1..5}; do
                sudo docker stop "titan$i" && sudo docker rm "titan$i"
            done
            for i in {1..5}; do 
                rmName="storage_titan_$i"
                rm -rf "$rmName"
            done
            echo "Node program uninstalled successfully."
            ;;
        *)
            echo "Uninstall operation canceled."
            ;;
    esac
}

# Main menu
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
        echo "To exit the script, press Ctrl + C on your keyboard."
        echo "Please select an operation:"
        echo "1. Install Node"
        echo "2. Uninstall Node"
        read -p "Enter option (1-2): " OPTION

        case $OPTION in
        1) install_node ;;
        2) uninstall_node ;;
        *) echo "Invalid option." ;;
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display main menu
main_menu
