#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

BOLD="\033[1m"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}Updating System Dependencies...${NC}"
echo
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
echo

echo -e "${BLUE}Adding Docker's official GPG key...${NC}"
echo
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo

echo -e "${BLUE}Adding Docker repository to Apt sources...${NC}"
echo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
echo

echo -e "${BLUE}Installing Docker packages...${NC}"
echo
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose
echo

echo -e "${BLUE}Verifying Docker installation...${NC}"
echo
sudo docker run hello-world
echo

echo -e "${BLUE}Pulling Analog Timechain Docker image...${NC}"
echo
docker pull analoglabs/timechain
echo

echo -e "${BLUE}Setting NODE_NAME variable...${NC}"
echo
read -p "Give a name to your node: " NODE_NAME
echo "export NODE_NAME=\"$NODE_NAME\"" >> ~/.bash_profile
source ~/.bash_profile
echo
echo -e "${BLUE}You need to remember your Node Name as you have to submit your node name in the whitelist form ${NC}"
echo

echo -e "${BLUE}Running Analog Timechain Docker container...${NC}"
echo
docker run -d --name analog -p 9944:9944 -p 30303:30303 analoglabs/timechain \
    --base-path /data \
    --rpc-external \
    --unsafe-rpc-external \
    --rpc-cors all \
    --name $NODE_NAME \
    --telemetry-url="wss://telemetry.analog.one/submit 9" \
    --rpc-methods Unsafe
echo

echo -e "${BLUE}Installing websocat...${NC}"
sudo wget -qO /usr/local/bin/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
sudo chmod a+x /usr/local/bin/websocat
echo

echo -e "${BLUE}Checking websocat version...${NC}"
echo
websocat --version
if [ $? -ne 0 ]; then
    echo "websocat installation failed or not found in PATH."
    exit 1
fi
echo

sleep 5

sudo apt-get install jq

sleep 2

echo -e "${BLUE}Rotating keys using websocat...${NC}"
echo
RESPONSE=$(echo '{"id":1,"jsonrpc":"2.0","method":"author_rotateKeys","params":[]}' | websocat -n1 -B 99999999 ws://127.0.0.1:9944)
if [ $? -ne 0 ]; then
    echo "Failed to rotate keys using websocat."
    exit 1
fi
KEY=$(echo $RESPONSE | jq -r '.result')
echo -e "Your rotate key is: ${GREEN}$KEY${NC}"
echo

echo -e "${BLUE}Script Execution Completed !!${NC}"
echo -e "${BLUE}██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░${NC}"
echo -e "${BLUE}██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗${NC}"
echo -e "${BLUE}██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝${NC}"
echo -e "${BLUE}██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░${NC}"
echo -e "${BLUE}███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░${NC}"
echo -e "${BLUE}╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░${NC}"
echo -e "${BLUE}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${NC}"
echo -e "${BLUE}============================ Analog Node Automation ====================================${NC}"
echo -e "${BLUE}Node community Telegram channel: https://t.me/layerairdrop${NC}"
echo -e "${BLUE}Node community Telegram group: https://t.me/layerairdropdiskusi${NC}"