#!/bin/bash

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

tput reset
tput civis

show_orange() {
    echo -e "\e[33m$1\e[0m"
}

show_blue() {
    echo -e "\e[34m$1\e[0m"
}

show_green() {
    echo -e "\e[32m$1\e[0m"
}

show_red() {
    echo -e "\e[31m$1\e[0m"
}

exit_script() {
    show_red "Script stopped"
    echo
    exit 0
}

incorrect_option() {
    echo
    show_red "Invalid option. Please choose from the available options."
    echo
}

process_notification() {
    local message="$1"
    show_orange "$message"
    sleep 1
}

run_commands() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        echo
        show_green "Success"
        echo
    else
        sleep 1
        echo
        show_red "Fail"
        echo
    fi
}

check_rust_version() {
    if command -v rustc &> /dev/null; then
        INSTALLED_RUST_VERSION=$(rustc --version | awk '{print $2}')
        show_orange "Installed Rust version: $INSTALLED_RUST_VERSION"
    else
        INSTALLED_RUST_VERSION=""
        show_blue "Rust not installed"
    fi
    echo
}

install_or_update_rust() {
    if [ -z "$INSTALLED_RUST_VERSION" ]; then
        process_notification "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
        show_green "Rust installed."
    elif [ "$INSTALLED_RUST_VERSION" != "$LATEST_RUST_VERSION" ]; then
        process_notification "Updating Rust"
        rustup update
        show_green "Rust updated."
    else
        show_green "Rust is already the latest version ($LATEST_RUST_VERSION)."
    fi
    echo
}

print_logo() {
    echo
    show_orange "  _______  .______       __       ___ " && sleep 0.2
    show_orange " |       \ |   _  \     |  |     /   \ " && sleep 0.2
    show_orange " |  .--.  ||  |_)  |    |  |    /  ^  \ " && sleep 0.2
    show_orange " |  |  |  ||      /     |  |   /  /_\  \ " && sleep 0.2
    show_orange " |  '--'  ||  |\  \----.|  |  /  _____  \ " && sleep 0.2
    show_orange " |_______/ | _|  ._____||__| /__/     \__\ " && sleep 0.2
    echo
    sleep 1
}

while true; do
    print_logo
    show_green "------ MAIN MENU ------ "
    echo "1. Preparation"
    echo "2. Installation"
    echo "3. Tuning"
    echo "4. Operational Menu"
    echo "5. Logs"
    echo "6. Delete"
    echo "7. Exit"
    echo
    read -p "Select option: " option

    case $option in
        1)
            # PREPARATION
            process_notification "Starting preparation..."
            run_commands "cd $HOME && sudo apt update && sudo apt upgrade -y && apt install screen"

            process_notification "Checking Rust..."
            sleep 2
            install_or_update_rust

            process_notification "Installing Ollama..."
            run_commands "curl -fsSL https://ollama.com/install.sh | sh"
            echo
            show_green "$(ollama --version)"
            echo
            show_green "--- PREPARATION COMPLETED ---"
            echo
            ;;
        2)
            # INSTALLATION
            process_notification "Installation..."
            run_commands "curl -fsSL https://dria.co/launcher | bash > /dev/null 2>&1"
            show_green "--- INSTALLED ---"
            echo
            ;;
        3)
            # TUNING
            echo
            while true; do
                show_green "------ TUNING MENU ------ "
                echo "1. Wallet, Port, Models, API"
                echo "2. Referral code"
                echo "3. Exit"
                echo
                read -p "Choose: " option
                echo
                case $option in
                    1)
                        dkn-compute-launcher settings
                        ;;
                    2)
                        dkn-compute-launcher referrals
                        ;;
                    3)
                        break
                        ;;
                    *)
                        incorrect_option
                        ;;
                esac
            done
            ;;
        4)
            # OPERATIONAL
            echo
            while true; do
                show_green "------ OPERATIONAL MENU ------ "
                echo "1. Start"
                echo "2. Stop"
                echo "3. Update"
                echo "4. Exit"
                echo
                read -p "Select option: " option
                echo
                case $option in
                    1)
                        process_notification "Starting..."
                        screen -dmS dria bash -c "cd $HOME/ && dkn-compute-launcher start"
                        ;;
                    2)
                        process_notification "Stopping..."
                        run_commands "screen -r dria -X quit"
                        ;;
                    3)
                        cd $HOME/
                        dkn-compute-launcher update
                        ;;
                    4)
                        break
                        ;;
                    *)
                        incorrect_option
                        ;;
                esac
            done
            ;;
        5)
            # LOGS
            process_notification "Connecting..." && sleep 2
            cd $HOME && screen -r dria
            ;;
        6)
            # DELETE
            process_notification "Deleting..."
            echo
            while true; do
                read -p "Delete node? (yes/no): " option
                case "$option" in
                    yes|y|Y|Yes|YES)
                        process_notification "Stopping..."
                        run_commands "screen -r dria -X quit"
                        run_commands "dkn-compute-launcher uninstall"
                        show_green "--- NODE DELETED ---"
                        break
                        ;;
                    no|n|N|No|NO)
                        process_notification "Cancel"
                        echo ""
                        break
                        ;;
                    *)
                        incorrect_option
                        ;;
                esac
            done
            ;;
        7)
            exit_script
            ;;
        *)
            incorrect_option
            ;;
    esac
done
