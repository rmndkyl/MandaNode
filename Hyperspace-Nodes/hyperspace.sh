#!/bin/bash

wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 2

echo "Updating the system before setup..."
sudo apt update -y && sudo apt upgrade -y

# Check for required utilities and install if missing
if ! command -v figlet &> /dev/null; then
    echo "figlet not found. Installing..."
    sudo apt update && sudo apt install -y figlet
fi

if ! command -v whiptail &> /dev/null; then
    echo "whiptail not found. Installing..."
    sudo apt update && sudo apt install -y whiptail
fi

# Define colors for convenience
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
PINK="\e[35m"
NC="\e[0m"

install_dependencies() {
    echo -e "${GREEN}Installing required packages...${NC}"
    sudo apt update && sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip screen
}

# Display welcome text with figlet
echo -e "${RED}$(figlet -w 150 -f standard "LayerAirdrop")${NC}"

echo "===================================================================================================================================="
echo "Welcome! Installing necessary libraries, meanwhile subscribe to our Telegram channel"
echo ""
echo "Channel: https://t.me/layerairdrop (only official account)$"
echo "===================================================================================================================================="

echo ""

# Define loading animation function
animate_loading() {
    for ((i = 1; i <= 5; i++)); do
        printf "\r${GREEN}Loading menu${NC}."
        sleep 0.3
        printf "\r${GREEN}Loading menu${NC}.."
        sleep 0.3
        printf "\r${GREEN}Loading menu${NC}..."
        sleep 0.3
        printf "\r${GREEN}Loading menu${NC}"
        sleep 0.3
    done
    echo ""
}

# Call animation function
animate_loading
echo ""

# Function to install the node
install_node() {
  echo 'Starting installation...'

  read -p "Enter your private key: " PRIVATE_KEY
  echo $PRIVATE_KEY > $HOME/my.pem

  session="hyperspacenode"

  cd $HOME

  sudo apt-get update -y && sudo apt-get upgrade -y
  sudo apt-get install wget make tar screen nano libssl3-dev build-essential unzip lz4 gcc git jq -y

  if [ -d "$HOME/.aios" ]; then
    sudo rm -rf "$HOME/.aios"
    aios-cli kill
  fi
  
  if screen -list | grep -q "\.${session}"; then
    screen -S hyperspacenode -X quit
  else
    echo "Session ${session} not found."
  fi

  while true; do
    curl -s https://download.hyper.space/api/install | bash | tee $HOME/hyperspacenode_install.log

    if ! grep -q "Failed to parse version from release data." $HOME/hyperspacenode_install.log; then
        echo "Client script installed."
        break
    else
        echo "Client installation server unavailable, retrying in 30 seconds..."
        sleep 30
    fi
  done

  rm hyperspacenode_install.log

  export PATH=$PATH:$HOME/.aios
  source ~/.bashrc

  eval "$(cat ~/.bashrc | tail -n +10)"

  screen -dmS hyperspacenode bash -c '
    echo "Starting script execution in screen session"

    aios-cli start

    exec bash
  '

  while true; do
    aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee $HOME/hyperspacemodel_download.log

    if grep -q "Download complete" $HOME/hyperspacemodel_download.log; then
        echo "Model installed."
        break
    else
        echo "Model installation server unavailable, retrying in 30 seconds..."
        sleep 30
    fi
  done

  rm hyperspacemodel_download.log

  aios-cli hive import-keys $HOME/my.pem
  aios-cli hive login
  aios-cli hive connect
}

# Function to check node status
  screen -S hyperspacenode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt


# Function to check node points
  aios-cli hive points

# Function to restart the node
restart_node() {
  session="hyperspacenode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "aios-cli start --connect\n"
    echo "Node restarted."
  else
    echo "Session ${session} not found."
  fi
}

# Function to remove the node
  read -p 'If you are sure you want to remove the node, enter any letter (CTRL+C to exit): ' checkjust

  echo 'Starting node removal...'

  screen -S hyperspacenode -X quit
  aios-cli kill
  aios-cli models remove hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
  sudo rm -rf $HOME/.aios

  echo 'Node removed.'


# Main menu
CHOICE=$(whiptail --title "Action Menu" \
    --menu "Select an action:" 15 50 6 \
    "1" "Install node" \
    "2" "Check node status" \
    "3" "Check node points" \
    "4" "Remove node" \
    "5" "Restart node" \
    "6" "Exit" \
    3>&1 1>&2 2>&3)

case $CHOICE in
    1) 
        install_node
        ;;
    2) 
        check_status
        ;;
    3) 
        check_points
        ;;
    4) 
        remove_node
        ;;
    5)
        restart_node
        ;;
    6)
        echo -e "${CYAN}Exiting program.${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting program.${NC}"
        ;;
esac
