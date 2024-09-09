#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

echo "Updating package list and upgrading installed packages..."
sudo apt update && sudo apt upgrade -y
if [ $? -ne 0 ]; then
  echo "Error updating and upgrading packages. Exiting..."
  exit 1
fi

# Fungsi untuk menampilkan menu utama
main_menu() {
	echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
	echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
	echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
	echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
	echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
	echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Autonomys Node Installation ===================================="
	echo "Node community Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
	echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "1. Install Autonomys Node"
    echo "2. Start Node & Farmer"
    echo "3. Stop Node & Farmer"
    echo "4. Enable Node & Farmer"
    echo "5. Disable Node & Farmer"
    echo "6. Check Node & Farmer Status"
    echo "7. View Node & Farmer Logs"
    echo "8. Check Rewards"
    echo "9. Uninstall Node"
    echo "0. Exit"
    echo "-----------------------------------"
    read -p "Choose an option [0-9]: " option

    case $option in
        1) install_node ;;
        2) start_node ;;
        3) stop_node ;;
        4) enable_node ;;
        5) disable_node ;;
        6) check_status ;;
        7) view_logs ;;
        8) check_rewards ;;
        9) uninstall_node ;;
        0) exit 0 ;;
        *) echo "Invalid option"; main_menu ;;
    esac
}

# Fungsi untuk instalasi node
install_node() {
echo "Installing required packages..."
sudo apt install curl wget tar build-essential jq unzip -y
if [ $? -ne 0 ]; then
  echo "Error installing packages. Exiting..."
  exit 1
fi

read -p "Enter your reward address: " REWARD_ADDRESS
read -p "Enter your node port (default 30333): " NODE_PORT
NODE_PORT=${NODE_PORT:-30333}
read -p "Enter your DNS port (default 30433): " DNS_PORT
DNS_PORT=${DNS_PORT:-30433}
read -p "Enter your farmer port (default 30533): " FARMER_PORT
FARMER_PORT=${FARMER_PORT:-30533}
read -p "Enter your plot size (default 100G): " PLOT_SIZE
PLOT_SIZE=${PLOT_SIZE:-100G}

if ! id -u subspace &>/dev/null; then
  sudo useradd -m -p ! -s /sbin/nologin -c "" subspace
  echo "User 'subspace' created."
else
  echo "User 'subspace' already exists."
fi

sudo su subspace -s /bin/bash << 'EOF'
mkdir -p ~/.local/bin ~/.local/share
wget -O ~/.local/bin/subspace-node https://github.com/autonomys/subspace/releases/download/gemini-3h-2024-sep-03/subspace-node-ubuntu-x86_64-skylake-gemini-3h-2024-sep-03
wget -O ~/.local/bin/subspace-farmer https://github.com/autonomys/subspace/releases/download/gemini-3h-2024-sep-03/subspace-farmer-ubuntu-x86_64-skylake-gemini-3h-2024-sep-03
chmod +x ~/.local/bin/subspace-node
chmod +x ~/.local/bin/subspace-farmer
exit
EOF

sudo tee /etc/systemd/system/subspace-node.service > /dev/null << EOF
[Unit]
Description=Subspace Node
Wants=network.target
After=network.target

[Service]
User=subspace
Group=subspace
ExecStart=/home/subspace/.local/bin/subspace-node \\
          run \\
          --name subspace \\
          --base-path /home/subspace/.local/share/subspace-node \\
          --chain gemini-3h \\
          --farmer \\
          --listen-on /ip4/0.0.0.0/tcp/$NODE_PORT \\
          --dsn-listen-on /ip4/0.0.0.0/tcp/$DNS_PORT
KillSignal=SIGINT
Restart=always
RestartSec=10
Nice=-5
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/subspace-farmer.service > /dev/null << EOF
[Unit]
Description=Subspace Farmer
Wants=network.target
After=network.target
Wants=subspace-node.service
After=subspace-node.service

[Service]
User=subspace
Group=subspace
ExecStart=/home/subspace/.local/bin/subspace-farmer \\
          farm \\
          --reward-address $REWARD_ADDRESS \\
          --listen-on /ip4/0.0.0.0/tcp/$FARMER_PORT \\
          path=/home/subspace/.local/share/subspace-farmer,size=$PLOT_SIZE
KillSignal=SIGINT
Restart=always
RestartSec=10
Nice=-5
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now subspace-node subspace-farmer

echo "Subspace Node and Farmer installed and running successfully!"
main_menu
}

# Fungsi untuk memulai node dan farmer
start_node() {
    sudo systemctl start subspace-node
    sudo systemctl start subspace-farmer
    echo "Node and Farmer started."
    main_menu
}

# Fungsi untuk menghentikan node dan farmer
stop_node() {
    sudo systemctl stop subspace-node
    sudo systemctl stop subspace-farmer
    echo "Node and Farmer stopped."
    main_menu
}

# Fungsi untuk mengaktifkan node dan farmer pada startup
enable_node() {
    sudo systemctl enable subspace-node
    sudo systemctl enable subspace-farmer
    echo "Node and Farmer enabled on startup."
    main_menu
}

# Fungsi untuk menonaktifkan node dan farmer pada startup
disable_node() {
    sudo systemctl disable subspace-node
    sudo systemctl disable subspace-farmer
    echo "Node and Farmer disabled on startup."
    main_menu
}

# Fungsi untuk memeriksa status node dan farmer
check_status() {
    echo "Node Status:"
    sudo systemctl status subspace-node
    echo "Farmer Status:"
    sudo systemctl status subspace-farmer
    main_menu
}

# Fungsi untuk melihat log node dan farmer
view_logs() {
    echo "1. View Node Logs"
    echo "2. View Farmer Logs"
    read -p "Choose an option [1-2]: " log_option

    case $log_option in
        1) sudo journalctl -f -o cat -u subspace-node ;;
        2) sudo journalctl -f -o cat -u subspace-farmer ;;
        *) echo "Invalid option"; view_logs ;;
    esac
    main_menu
}

# Fungsi untuk memeriksa reward dari farmer
check_rewards() {
    sudo journalctl -o cat -u subspace-farmer --since="1 hour ago" | grep -i "Successfully signed reward hash" | wc -l
    main_menu
}

# Fungsi untuk menghapus node dan farmer
uninstall_node() {
    sudo systemctl stop subspace-node && sudo systemctl stop subspace-farmer
    sudo systemctl disable subspace-node && sudo systemctl disable subspace-farmer
    sudo rm /etc/systemd/system/subspace-node.service /etc/systemd/system/subspace-farmer.service
    sudo userdel -r subspace
    sudo rm -rf /home/subspace/.local/bin/subspace-node /home/subspace/.local/bin/subspace-farmer /home/subspace/.local/share/subspace-node /home/subspace/.local/share/subspace-farmer
    sudo systemctl daemon-reload
    echo "Node and Farmer uninstalled."
    main_menu
}

# Panggil fungsi main_menu untuk memulai script
main_menu
