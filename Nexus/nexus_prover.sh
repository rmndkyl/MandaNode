#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Comprehensive Nexus Prover installation and setup
install_nexus_prover() {
    echo "Updating and installing necessary packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip cmake -y

    if ! command -v rustc &> /dev/null; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo "Rust is already installed. Updating..."
        rustup update
    fi

    echo "Installing Nexus Prover..."
    sudo curl https://cli.nexus.xyz/install.sh | sh

    echo "Setting file ownership for Nexus..."
    sudo chown -R root:root /root/.nexus

    SERVICE_FILE="/etc/systemd/system/nexus.service"
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "Creating systemd service for Nexus Prover..."
        sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Nexus Network
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/.nexus/network-api/clients/cli
ExecStart=/root/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz
Restart=always
RestartSec=11
LimitNOFILE=65000

[Install]
WantedBy=multi-user.target
EOF
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable nexus.service
    sudo systemctl start nexus.service
    echo "Nexus Prover installation complete."

    echo "Updating Nexus Network API..."
    cd ~/.nexus/network-api
    git fetch --all --tags
    LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
    git checkout $LATEST_TAG
    cargo clean && cargo build --release
    echo "Nexus Network API updated to version $LATEST_TAG."

    echo "Setting up Nexus ZKVM environment..."
    rustup target add riscv32i-unknown-none-elf
    cargo install --git https://github.com/nexus-xyz/nexus-zkvm nexus-tools --tag 'v1.0.0'

    cargo nexus new nexus-project
    cd nexus-project/src
    rm -rf main.rs

    cat <<EOT >> main.rs
#![no_std]
#![no_main]

fn fib(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        _ => fib(n - 1) + fib(n - 2),
    }
}

#[nexus_rt::main]
fn main() {
    let n = 7;
    let result = fib(n);
    assert_eq!(result, 13);
}
EOT
    cd ..

    echo "Running and verifying Nexus program..."
    cargo nexus run
    cargo nexus prove
    cargo nexus verify
    echo "Nexus program run and verification complete."

    if ! systemctl is-active --quiet nexus.service; then
        echo "Nexus service is not running. Starting service..."
        sudo systemctl start nexus.service
    fi
    
    if ! systemctl is-active --quiet nexus.service; then
        echo "Failed to start Nexus service. Checking logs..."
        sudo journalctl -u nexus.service -n 50 --no-pager
    else
        echo "Nexus service is running."
    fi

    echo "Install Nexus Prover process completed."
}

# Check Nexus Prover service logs
check_logs() {
    echo "Checking Nexus service logs..."
    sudo journalctl -u nexus.service -n 50 --no-pager
}

# Check the status of the Nexus Prover service
check_status() {
    echo "Checking Nexus service status..."
    sudo systemctl status nexus.service
}

# Restart the Nexus Prover service
restart_service() {
    echo "Restarting Nexus service..."
    sudo systemctl restart nexus.service
    echo "Nexus service restarted."
}

# Stop and remove Nexus service and installation
delete_nexus_prover() {
    echo "Stopping and removing Nexus service..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
    sudo rm -f /etc/systemd/system/nexus.service
    sudo systemctl daemon-reload
    sudo rm -rf /root/.nexus
    echo "Nexus Prover deleted."
}

# Main menu to manage the script
main_menu() {
    while true; do
        echo "The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version"
        echo "==============================Nexus Prover zkVM Menu===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "1. Install Nexus Prover"
        echo "2. Check Logs"
        echo "3. Check Status"
        echo "4. Restart Service"
        echo "5. Delete Nexus Prover"
        echo "6. Exit"
        echo "==================================="
        read -rp "Select an option (1-6): " choice

        case $choice in
            1) install_nexus_prover ;;
            2) check_logs ;;
            3) check_status ;;
            4) restart_service ;;
            5) delete_nexus_prover ;;
            6) echo "Exiting Nexus Manager."; break ;;
            *) echo "Invalid option. Please select a valid option." ;;
        esac
        echo
    done
}

# Start the main menu
main_menu
