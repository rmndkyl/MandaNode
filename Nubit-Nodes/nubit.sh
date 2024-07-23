#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root privileges."
    echo "Please try using the 'sudo -i' command to switch to the root user and then run this script again."
    exit 1
fi

# Check and install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is installed"
    else
        echo "Node.js is not installed, installing..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm is installed"
    else
        echo "npm is not installed, installing..."
        sudo apt-get install -y npm
    fi
}

# Check and install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is installed"
    else
        echo "PM2 is not installed, installing..."
        npm install pm2@latest -g
    fi
}

# Node installation function
function install_node() {
    install_nodejs_and_npm
    install_pm2

    echo "Starting Nubit node installation..."

    while [ $# -gt 0 ]; do
        if [[ $1 = "--"* ]]; then
            v="${1/--/}"
            declare "$v"="$2"
            shift
        fi
        shift
    done

    if [ "$(uname -m)" = "arm64" -a "$(uname -s)" = "Darwin" ]; then
        ARCH_STRING="darwin-arm64"
        MD5_NUBIT="0cd8c1dae993981ce7c5c5d38c048dda"
        MD5_NKEY="4045adc4255466e37d453d7abe92a904"
    elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
        ARCH_STRING="darwin-x86_64"
        MD5_NUBIT="7ce3adde1d9607aeebdbd44fa4aca850"
        MD5_NKEY="84bff807aa0553e4b1fac5c5e34b01f1"
    elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
        ARCH_STRING="linux-arm64"
        MD5_NUBIT="9de06117b8f63bffb3d6846fac400acf"
        MD5_NKEY="3b890cf7b10e193b7dfcc012b3dde2a3"
    elif [ "$(uname -m)" = "x86_64" ]; then
        ARCH_STRING="linux-x86_64"
        MD5_NUBIT="650608532ccf622fb633acbd0a754686"
        MD5_NKEY="d474f576ad916a3700644c88c4bc4f6c"
    elif [ "$(uname -m)" = "i386" -o "$(uname -m)" = "i686" ]; then
        ARCH_STRING="linux-x86"
        MD5_NUBIT="9e1f66092900044e5fd862296455b8cc"
        MD5_NKEY="7ffb30903066d6de1980081bff021249"
    fi

    if [ -z "$ARCH_STRING" ]; then
        echo "Unsupported architecture $(uname -s) - $(uname -m)"
        exit 1
    else
        cd $HOME
        FOLDER=nubit-node
        FILE=$FOLDER-$ARCH_STRING.tar
        FILE_NUBIT=$FOLDER/bin/nubit
        FILE_NKEY=$FOLDER/bin/nkey
        if [ -f $FILE ]; then
            rm $FILE
        fi
        OK="N"
        if [ "$(uname -s)" = "Darwin" ]; then
            if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5 -q "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5 -q "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
                OK="Y"
            fi
        else
            if ! command -v tar &> /dev/null; then
                echo "Command tar is not available. Please install and try again"
                exit 1
            fi
            if ! command -v ps &> /dev/null; then
                echo "Command ps is not available. Please install and try again"
                exit 1
            fi
            if ! command -v bash &> /dev/null; then
                echo "Command bash is not available. Please install and try again"
                exit 1
            fi
            if ! command -v md5sum &> /dev/null; then
                echo "Command md5sum is not available. Please install and try again"
                exit 1
            fi
            if ! command -v awk &> /dev/null; then
                echo "Command awk is not available. Please install and try again"
                exit 1
            fi
            if ! command -v sed &> /dev/null; then
                echo "Command sed is not available. Please install and try again"
                exit 1
            fi
            if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5sum "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5sum "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
                OK="Y"
            fi
        fi
        echo "Starting Nubit node..."
        if [ $OK = "Y" ]; then
            echo "MD5 checking passed. Start directly"
        else
            echo "Installation of the latest version of nubit-node is required to ensure optimal performance and access to new features."
            URL=http://nubit.sh/nubit-bin/$FILE
            echo "Upgrading nubit-node ..."
            echo "Download from URL, please do not close: $URL"
            if command -v curl >/dev/null 2>&1; then
                curl -sLO $URL
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- $URL
            else
                echo "Neither curl nor wget are available. Please install one of these and try again"
                exit 1
            fi
            tar -xvf $FILE
            if [ ! -d $FOLDER ]; then
                mkdir $FOLDER
            fi
            if [ ! -d $FOLDER/bin ]; then
                mkdir $FOLDER/bin
            fi
            mv $FOLDER-$ARCH_STRING/bin/nubit $FOLDER/bin/nubit
            mv $FOLDER-$ARCH_STRING/bin/nkey $FOLDER/bin/nkey
            rm -rf $FOLDER-$ARCH_STRING
            rm $FILE
            echo "Nubit-node update complete."
        fi

        sudo cp $HOME/nubit-node/bin/nubit /usr/local/bin
        sudo cp $HOME/nubit-node/bin/nkey /usr/local/bin
        echo "export store=$HOME/.nubit-light-nubit-alphatestnet-1" >> $HOME/.bash_profile

        cat <<EOL > ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "nubit-node",
      script: "./start.sh",
      cwd: "$HOME/nubit-node",
      interpreter: "/bin/bash",
      watch: false,
      env: {
        NODE_ENV: "production"
      },
      error_file: "$HOME/logs/nubit-node-error.log",
      out_file: "$HOME/logs/nubit-node-out.log",
      log_file: "$HOME/logs/nubit-node-combined.log",
      time: true
    }
  ]
};
EOL

        mkdir -p $HOME/logs

        echo "Downloading start.sh script..."
        curl -sL1 https://nubit.sh/start.sh -o $HOME/nubit-node/start.sh
        chmod +x $HOME/nubit-node/start.sh

        echo "Starting nubit node with PM2..."

        pm2 start ecosystem.config.js --env production
    fi

    echo '====================== Installation complete. Please exit the script and run source $HOME/.bash_profile to load the environment variables ==========================='
}

# Check Nubit service status
function check_service_status() {
    pm2 list
}

# Nubit node log query
function view_logs() {
    pm2 logs nubit-node
}

# Check Nubit address
function check_address() {
    nubit state account-address  --node.store $store
}

# Check Nubit public key
function check_pubkey() {
    $HOME/nubit-node/bin/nkey list --p2p.network nubit-alphatestnet-1 --node.type light
}

# Export mnemonic
function export_mnemonic() {
    cat ~/nubit-node/mnemonic.txt
}

# Export pvkey
function export_pvkey() {
    $HOME/nubit-node/bin/nkey export my_nubit_key --unarmored-hex --unsafe --p2p.network nubit-alphatestnet-1 --node.type light
}

# Check Uptime
function check_uptime() {
    $HOME/nubit-node/bin/nubit das sampling-stats --node.store $HOME/.nubit-light-nubit-alphatestnet-1
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
        echo "============================ Nubit Node Installation ===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press Ctrl+C"
        echo "Please select an operation:"
        echo "1. Install Node"
        echo "2. Check Node Synchronization Status"
        echo "3. Check Current Service Status"
        echo "4. View Wallet Address"
        echo "5. View Public Key"
        echo "6. Display Wallet Mnemonic"
        echo "7. Export Private key from Mnemonic"
        echo "8. Check your Uptime, if said 'true' is good."
        read -p "Please enter an option (1-6): " OPTION

        case $OPTION in
        1) install_node ;;
        2) check_service_status ;;
        3) view_logs ;;
        4) check_address ;;
        5) check_pubkey ;;
        6) export_mnemonic ;;
        7) export_pvkey ;;
        8) check_uptime ;;
        *) echo "Invalid option." ;;
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display main menu
main_menu
