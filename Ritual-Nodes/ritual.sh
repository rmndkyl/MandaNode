#!/bin/bash

BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
NC='\033[0m'

# Check for Korean language support
check_korean_support() {
    if locale -a | grep -q "ko_KR.utf8"; then
        return 0  # Korean support is installed
    else
        return 1  # Korean support is not installed
    fi
}

# Korean language check
if check_korean_support; then
    echo -e "${CYAN}Korean language support detected. Skipping installation.${NC}"
else
    echo -e "${CYAN}Korean language support not found. Installing...${NC}"
    sudo apt-get install language-pack-ko -y
    sudo locale-gen ko_KR.UTF-8
    sudo update-locale LANG=ko_KR.UTF-8 LC_MESSAGES=POSIX
    echo -e "${CYAN}Installation completed.${NC}"
fi

# Ritual basic file installation and configuration
install_ritual() {

# Install essential packages
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${CYAN}Updating system...${NC}"
sudo apt update

echo -e "${CYAN}Upgrading packages...${NC}"
sudo apt upgrade -y

echo -e "${CYAN}Removing unused packages...${NC}"
sudo apt autoremove -y

echo -e "${CYAN}Installing necessary packages...${NC}"
sudo apt -qy install curl git jq lz4 build-essential screen

echo -e "${BOLD}${CYAN}Checking for Docker installation...${NC}"
if ! command_exists docker; then
    echo -e "${RED}Docker is not installed. Installing Docker...${NC}"
    sudo apt install docker.io -y
    echo -e "${CYAN}Docker installed successfully.${NC}"
else
    echo -e "${CYAN}Docker is already installed.${NC}"
fi

echo -e "${CYAN}Displaying Docker version...${NC}"
docker version

echo -e "${CYAN}Updating package lists...${NC}"
sudo apt-get update

if ! command_exists docker-compose; then
    echo -e "${RED}Docker Compose is not installed. Installing Docker Compose...${NC}"
    sudo curl -L https://github.com/docker/compose/releases/download/$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
    sudo chmod 755 /usr/bin/docker-compose
    echo -e "${CYAN}Docker Compose installed successfully.${NC}"
else
    echo -e "${CYAN}Docker Compose is already installed.${NC}"
fi

echo -e "${CYAN}Installing Docker Compose CLI plugin...${NC}"
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

echo -e "${CYAN}Making CLI plugin executable...${NC}"
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

echo -e "${CYAN}Displaying Docker Compose version...${NC}"
docker-compose version

# Ritual installation
echo -e "${CYAN}Cloning the Ritual repository...${NC}"
git clone https://github.com/ritual-net/infernet-container-starter

docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
sed -i 's/image: ritualnetwork\/infernet-node:1.3.1/image: ritualnetwork\/infernet-node:1.2.0/' "$docker_yaml"
echo -e "${BOLD}${CYAN}docker-compose.yaml version reverted to 1.2.0.${NC}"

echo -e "${MAGENTA}${BOLD}To start Ritual, run 'screen -S ritual', then 'cd ~/infernet-container-starter && project=hello-world make deploy-container'.${NC}"
echo -e "${MAGENTA}${BOLD}When you see a large green RITUAL message, use Ctrl+A+D to detach.${NC}"
}

install_ritual_2() {

# Prompt the user for a new RPC URL and Private Key
echo -ne "${BOLD}${MAGENTA}Enter the new RPC URL: ${NC}"
read -e rpc_url1

echo -ne "${BOLD}${MAGENTA}Enter the new Private Key (prepend with 0x): ${NC}"
read -e private_key1

# File paths to be modified
json_1=~/infernet-container-starter/deploy/config.json
json_2=~/infernet-container-starter/projects/hello-world/container/config.json

# Create a temporary file
temp_file=$(mktemp)

# Use jq to update RPC URL and Private Key in the configuration and save to a temporary file
jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
    '.chain.rpc_url = $rpc |
     .chain.wallet.private_key = $priv |
     .chain.trail_head_blocks = 3 |
     .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
     .chain.snapshot_sync.sleep = 3 |
     .chain.snapshot_sync.batch_size = 800 |
     .chain.snapshot_sync.starting_sub_id = 160000 |
     .chain.snapshot_sync.sync_period = 30' $json_1 > $temp_file

# Overwrite the original file with the temporary file and delete the temporary file
mv $temp_file $json_1

# Apply the same changes to the second file
jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
    '.chain.rpc_url = $rpc |
     .chain.wallet.private_key = $priv |
     .chain.trail_head_blocks = 3 |
     .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
     .chain.snapshot_sync.sleep = 3 |
     .chain.snapshot_sync.batch_size = 800 |
     .chain.snapshot_sync.starting_sub_id = 160000 |
     .chain.snapshot_sync.sync_period = 30' $json_2 > $temp_file

mv $temp_file $json_2

# Delete the temporary file
rm -f $temp_file

echo -e "${BOLD}${MAGENTA}RPC URL and Private Key have been updated.${NC}"

# File path for Makefile
makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile 

# Use sed to update sender and RPC_URL values
sed -i "s|sender := .*|sender := $private_key1|" "$makefile"
sed -i "s|RPC_URL := .*|RPC_URL := $rpc_url1|" "$makefile"

echo -e "${BOLD}${CYAN}Makefile has been updated.${NC}"

# Update deploy.s.sol
deploy_s_sol=~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol
old_registry="0x663F3ad617193148711d28f5334eE4Ed07016602"
new_registry="0x3B1554f346DFe5c482Bb4BA31b880c1C18412170"

sed -i "s|$old_registry|$new_registry|" "$deploy_s_sol"
echo -e "${CYAN}deploy.s.sol has been updated.${NC}"

# Update docker-compose.yaml
docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
sed -i 's/image: ritualnetwork\/infernet-node:1.2.0/image: ritualnetwork\/infernet-node:1.4.0/' "$docker_yaml"
echo -e "${BOLD}${CYAN}docker-compose.yaml has been updated to 1.4.0.${NC}"

# Restart Docker
echo -e "${CYAN}Stopping Docker containers...${NC}"
cd $HOME/infernet-container-starter/deploy
docker compose down

echo -e "${CYAN}Restarting Docker container for hello-world...${NC}"
docker restart hello-world

# Display Docker status
echo -e "${BOLD}${MAGENTA}Displaying Docker container status:${NC}"
docker ps

echo -e "${BOLD}${MAGENTA}To start, run 'cd ~/infernet-container-starter/deploy && docker compose up' in your terminal.${NC}"
echo -e "${BOLD}${MAGENTA}Once the output appears, do not press any keys. Close the terminal and reopen a new one to log back into Contabo.${NC}"
}

install_ritual_3() {
# Install Foundry
echo -e "${CYAN}Changing directory to $HOME${NC}"
cd $HOME

echo -e "${CYAN}Creating a directory named 'foundry'${NC}"
mkdir foundry

echo -e "${CYAN}Changing directory to $HOME/foundry${NC}"
cd $HOME/foundry

echo -e "${CYAN}Downloading Foundry installation script${NC}"
curl -L https://foundry.paradigm.xyz | bash

export PATH="/root/.foundry/bin:$PATH"

echo -e "${CYAN}Refreshing shell environment${NC}"
source ~/.bashrc

echo -e "${CYAN}Updating Foundry${NC}"
foundryup

echo -e "${CYAN}Changing directory to contracts folder${NC}"
cd ~/infernet-container-starter/projects/hello-world/contracts

echo -e "${CYAN}Removing 'lib' folder${NC}"
rm -rf lib

echo -e "${CYAN}Installing forge-std library${NC}"
forge install --no-commit foundry-rs/forge-std

echo -e "${CYAN}Installing infernet-sdk library${NC}"
forge install --no-commit ritual-net/infernet-sdk

export PATH="/root/.foundry/bin:$PATH"

# Deploy contracts
echo -e "${CYAN}Changing directory to the main infernet folder${NC}"
cd $HOME/infernet-container-starter

echo -e "${CYAN}Deploying contracts for project 'hello-world'${NC}"
project=hello-world make deploy-contracts

# Modify CallContract.s.sol
echo -e "${CYAN}Scroll up to check the logs for deployment information.${NC}"
echo -ne "${CYAN}Enter the exact deployed Sayshello address (e.g., Sayshello:): ${NC}"
read -e says_gm

callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"

echo -e "${CYAN}Modifying CallContract.s.sol at /root/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol${NC}"
sed "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath" | sudo tee "$callcontractpath" > /dev/null

# Finalize contract execution
echo -e "${CYAN}Calling contract for project 'hello-world'${NC}"
project=hello-world make call-contract

echo -e "${BOLD}${MAGENTA}Ritual installation is complete. Great work! (Honestly, I did all the work, didn't I? 😂)${NC}"
}

restart_ritual() {
echo -e "${CYAN}Stopping Docker containers...${NC}"
cd $HOME/infernet-container-starter/deploy
docker compose down

echo -e "${BOLD}${MAGENTA}Displaying Docker container status:${NC}"
docker ps

echo -e "${BOLD}${MAGENTA}To restart, run 'cd ~/infernet-container-starter/deploy && docker compose up' in your terminal.${NC}"
echo -e "${BOLD}${MAGENTA}When the output appears, do not press any keys. Simply close the terminal.${NC}"
}

change_Wallet_Address() {
# Prompt the user to enter a new private key
echo -ne "${BOLD}${MAGENTA}Enter the new Private Key (include 0x prefix): ${NC}"
read -e private_key1

# Paths to the files to be updated
json_1=~/infernet-container-starter/deploy/config.json
json_2=~/infernet-container-starter/projects/hello-world/container/config.json
makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile 

# Create a temporary file
temp_file=$(mktemp)

# Update the private key in the first JSON file using jq
jq --arg priv "$private_key1" \
	'.chain.wallet.private_key = $priv' $json_1 > $temp_file

# Replace the original file with the updated one
mv $temp_file $json_1

# Apply the same changes to the second JSON file
jq --arg priv "$private_key1" \
	'.chain.wallet.private_key = $priv' $json_2 > $temp_file

mv $temp_file $json_2

# Delete the temporary file
rm -f $temp_file

echo -e "${BOLD}${MAGENTA}Private key has been updated in the JSON files.${NC}"

# Update the sender value in the Makefile using sed
sed -i "s|sender := .*|sender := $private_key1|" "$makefile"

echo -e "${BOLD}${MAGENTA}The private key in the Makefile has been updated.${NC}"

# Redeploy the contracts
echo -e "${CYAN}Changing directory to the main infernet folder.${NC}"
cd $HOME/infernet-container-starter

echo -e "${CYAN}Deploying contracts for project 'hello-world'.${NC}"
project=hello-world make deploy-contracts

# Modify CallContract.s.sol
echo -e "${CYAN}Scroll up and review the logs to locate the deployed contract address.${NC}"
echo -ne "${CYAN}Enter the exact deployed Sayshello address: ${NC}"
read -e says_gm

callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"

echo -e "${CYAN}Updating CallContract.s.sol at /root/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol${NC}"
sed "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath" | sudo tee "$callcontractpath" > /dev/null

# Finalize the contract call
echo -e "${CYAN}Calling the contract for project 'hello-world'.${NC}"
project=hello-world make call-contract

echo -e "${BOLD}${MAGENTA}The wallet address change has been completed.${NC}"
}

change_RPC_Address() {
# Prompt the user to input a new RPC URL
echo -ne "${BOLD}${MAGENTA}Enter the new RPC URL: ${NC}"
read -e rpc_url1

# Paths to the files to be updated
json_1=~/infernet-container-starter/deploy/config.json
json_2=~/infernet-container-starter/projects/hello-world/container/config.json
makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile 

# Create a temporary file
temp_file=$(mktemp)

# Update the RPC URL in the first JSON file using jq
jq --arg rpc "$rpc_url1" \
	'.chain.rpc_url = $rpc' $json_1 > $temp_file

# Replace the original file with the updated one
mv $temp_file $json_1

# Apply the same changes to the second JSON file
jq --arg rpc "$rpc_url1" \
	'.chain.rpc_url = $rpc' $json_2 > $temp_file

mv $temp_file $json_2

# Delete the temporary file
rm -f $temp_file

echo -e "${BOLD}${MAGENTA}RPC URL has been updated in the JSON files.${NC}"

# Update the RPC_URL value in the Makefile using sed
sed -i "s|RPC_URL := .*|RPC_URL := $rpc_url1|" "$makefile"

echo -e "${BOLD}${MAGENTA}The RPC URL in the Makefile has been updated.${NC}"

# Restart the necessary Docker containers
echo -e  "${CYAN}Restarting infernet-anvil container...${NC}"
docker restart infernet-anvil

echo -e  "${CYAN}Restarting hello-world container...${NC}"
docker restart hello-world

echo -e  "${CYAN}Restarting infernet-node container...${NC}"
docker restart infernet-node

echo -e  "${CYAN}Restarting deploy-fluentbit-1 container...${NC}"
docker restart deploy-fluentbit-1

echo -e  "${CYAN}Restarting deploy-redis-1 container...${NC}"
docker restart deploy-redis-1

echo -e "${BOLD}${MAGENTA}RPC URL update completed.${NC}"
echo -e "${BOLD}${MAGENTA}If the update doesn't work, try running this command again up to 4 times.${NC}"
}

update_ritual() {
echo -e "${BOLD}${RED}Starting Ritual update (10/31).${NC}"

# Paths to the files to be updated
json_1=~/infernet-container-starter/deploy/config.json
json_2=~/infernet-container-starter/projects/hello-world/container/config.json

# Create a temporary file
temp_file=$(mktemp)

# Update the first JSON file
jq '.chain.snapshot_sync.sleep = 3 |
    .chain.snapshot_sync.batch_size = 9500 |
    .chain.snapshot_sync.starting_sub_id = 170000 |
    .chain.snapshot_sync.sync_period = 5' "$json_1" > "$temp_file"
mv "$temp_file" "$json_1"

# Update the second JSON file
jq '.chain.snapshot_sync.sleep = 3 |
    .chain.snapshot_sync.batch_size = 9500 |
    .chain.snapshot_sync.starting_sub_id = 170000 |
    .chain.snapshot_sync.sync_period = 5' "$json_2" > "$temp_file"
mv "$temp_file" "$json_2"

# Delete the temporary file
rm -f $temp_file

echo -e "${YELLOW}Stopping Docker containers...${NC}"
cd ~/infernet-container-starter/deploy && docker compose down

echo -e "${YELLOW}Now, run the following command to restart Docker:${NC}"
echo -e "${RED}'cd ~/infernet-container-starter/deploy && docker compose up'${NC}${YELLOW}.${NC}"
}

uninstall_ritual() {
# Remove all Ritual-related Docker containers
echo -e "${BOLD}${CYAN}Stopping and removing Ritual Docker containers...${NC}"
docker stop infernet-anvil
docker stop infernet-node
docker stop hello-world
docker stop deploy-redis-1
docker stop deploy-fluentbit-1

docker rm -f infernet-anvil
docker rm -f infernet-node
docker rm -f hello-world
docker rm -f deploy-redis-1
docker rm -f deploy-fluentbit-1

cd ~/infernet-container-starter/deploy && docker compose down

# Remove Ritual Docker images
echo -e "${BOLD}${CYAN}Removing Ritual Docker images...${NC}"
docker image ls -a | grep "infernet" | awk '{print $3}' | xargs docker rmi -f
docker image ls -a | grep "fluent-bit" | awk '{print $3}' | xargs docker rmi -f
docker image ls -a | grep "redis" | awk '{print $3}' | xargs docker rmi -f

# Remove Foundry files
echo -e "${CYAN}Removing Foundry files...${NC}"
rm -rf $HOME/foundry

echo -e "${CYAN}Removing Foundry path from ~/.bashrc...${NC}"
sed -i '/\/root\/.foundry\/bin/d' ~/.bashrc

echo -e "${CYAN}Cleaning Foundry contracts directory...${NC}"
rm -rf ~/infernet-container-starter/projects/hello-world/contracts/lib

echo -e "${CYAN}Running 'forge clean'...${NC}"
forge clean

# Remove Ritual Node files
echo -e "${BOLD}${CYAN}Removing Ritual Node directory (infernet-container-starter)...${NC}"
cd $HOME
sudo rm -rf infernet-container-starter
cd $HOME

echo -e "${BOLD}${CYAN}All Ritual Node-related files have been removed.${NC}"
echo -e "${BOLD}${CYAN}Note: Docker itself has not been removed, as it may be used by other applications.${NC}"
}

# Main Menu
echo && echo -e "${BOLD}${MAGENTA} Ritual Node Automated Installation Script${NC} by CoinLoveMiSun
 ${CYAN}Select the desired option and proceed with execution.${NC}
 ———————————————————————
 ${GREEN} 1. Install Basic Files and Ritual Node (Step 1, v1.4.0) ${NC}
 ${GREEN} 2. Install Ritual Node (Step 2, v1.4.0) ${NC}
 ${GREEN} 3. Install Ritual Node (Step 3, v1.4.0) ${NC}
 ${GREEN} 4. Restart Ritual Node if it has stopped working ${NC}
 ${GREEN} 5. Change the Wallet Address for Ritual Node ${NC}
 ${GREEN} 6. Change the RPC Address for Ritual Node ${NC}
 ${GREEN} 7. Update Ritual Node (as of 10/31) ${NC}
 ${GREEN} 8. Uninstall Ritual Node and remove all related files ${NC}
 ———————————————————————" && echo

# Wait for user input
echo -ne "${BOLD}${MAGENTA} What would you like to do? Enter the corresponding number from the list above: ${NC}"
read -e num

case "$num" in
1)
    install_ritual
    ;;
2)
    install_ritual_2
    ;;
3)
    install_ritual_3
    ;;
4)
    restart_ritual
    ;;
5)
    change_Wallet_Address
    ;;
6)
    change_RPC_Address
    ;;
7)
    update_ritual
    ;;
8)
    uninstall_ritual
    ;;
*)
    echo -e "${BOLD}${RED}Invalid input. Please try again!${NC}"
    ;;
esac