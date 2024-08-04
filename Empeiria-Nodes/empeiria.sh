#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to display the logo
display_logo() {
  echo -e '\e[40m\e[32m'
  echo -e '██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░'
  echo -e '██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗'
  echo -e '██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝'
  echo -e '██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░'
  echo -e '███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░'
  echo -e '╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░'
  echo -e '\e[0m'

  echo -e "\nScript and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions\n"
  echo -e "\n============================ Empeiria Node Automation ====================================\n"
  echo -e "\nNode community Telegram channel: https://t.me/layerairdrop\n"
  echo -e "\nNode community Telegram group: https://t.me/layerairdropdiskusi\n"
}

# Function to print green text
printGreen() {
  echo -e "\e[32m$1\e[0m"
}

# Function to print a line
printLine() {
  echo "--------------------------------------"
}

# Function to install Empeiria node
install_node() {
  read -p "Create a name for your wallet: " WALLET
  echo 'export WALLET='$WALLET
  read -p "Create a name for your node (MONIKER): " MONIKER
  echo 'export MONIKER='$MONIKER
  read -p "Enter the port for the node to run on: " PORT
  echo 'export PORT='$PORT

  # Set variables
  echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
  echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
  echo "export EMPED_CHAIN_ID="empe-testnet-2"" >> $HOME/.bash_profile
  echo "export EMPED_PORT="$PORT"" >> $HOME/.bash_profile
  source $HOME/.bash_profile

  printLine
  echo -e "Node Name (MONIKER): \e[1m\e[32m$MONIKER\e[0m"
  echo -e "Wallet:           \e[1m\e[32m$WALLET\e[0m"
  echo -e "Chain ID:        \e[1m\e[32m$EMPED_CHAIN_ID\e[0m"
  echo -e "PORT: \e[1m\e[32m$EMPED_PORT\e[0m"
  printLine
  sleep 1

  printGreen "1. Installing Go..." && sleep 1
  # Install Go if needed
  cd $HOME
  VER="1.22.3"
  wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
  rm "go$VER.linux-amd64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source $HOME/.bash_profile
  [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

  echo $(go version) && sleep 1

  source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

  printGreen "4. Installing binary file..." && sleep 1
  # Download binary file
  cd $HOME
  curl -LO https://github.com/empe-io/empe-chain-releases/raw/master/v0.1.0/emped_linux_amd64.tar.gz
  tar -xvf emped_linux_amd64.tar.gz 
  mv emped ~/go/bin

  printGreen "5. Configuring and initializing the application..." && sleep 1
  # Configure and initialize the application
  emped config node tcp://localhost:${EMPED_PORT}657
  emped config keyring-backend os
  emped config chain-id empe-testnet-2
  emped init $MONIKER --chain-id empe-testnet-2
  sleep 1
  echo done

  printGreen "6. Downloading genesis and addrbook..." && sleep 1
  # Download genesis and addrbook
  wget -O $HOME/.empe-chain/config/genesis.json https://server-5.itrocket.net/testnet/empeiria/genesis.json
  wget -O $HOME/.empe-chain/config/addrbook.json  https://server-5.itrocket.net/testnet/empeiria/addrbook.json
  sleep 1
  echo done

  printGreen "7. Adding seed, peer, configuring custom ports, pruning, and minimum gas price..." && sleep 1
  # Configure seed and peer
  SEEDS="20ca5fc4882e6f975ad02d106da8af9c4a5ac6de@empeiria-testnet-seed.itrocket.net:28656"
  PEERS="03aa072f917ed1b79a14ea2cc660bc3bac787e82@empeiria-testnet-peer.itrocket.net:28656,004e2924efb660169e27d55518909b24f902dd48@155.133.27.170:26656,7f777a33fc94dfdade513c161a0bafbb0cfc2025@213.199.45.86:43656,5faa12744223fd0aea91970e405d69731ff35fed@62.169.17.9:43656,33cfcfa07ad55331d40fb7bcda010b0156328647@149.102.144.171:43656,3e30e4b87bdd45e9715b0bbf02c9930d820a3158@164.132.168.149:26656,bb15883943a2f31b1ca73247a1b0526a5778f23a@135.181.94.81:26656,e058f20874c7ddf7d8dc8a6200ff6c7ee66098ba@65.109.93.124:29056,0340080d68f88eb6944bd79c86abd3c9794eb0a0@65.108.233.73:13656,45bdc8628385d34afc271206ac629b07675cd614@65.21.202.124:25656,a9cf0ffdef421d1f4f4a3e1573800f4ee6529773@136.243.13.36:29056,878d0e8b9741adc865823e4f69554712e35236b9@91.227.33.18:13656,66ac611ba87753e92f1e5d792a2b19d4c5080f32@188.40.73.112:22656"
  sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
         -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
         $HOME/.empe-chain/config/config.toml

  # Configure custom ports in app.toml
  sed -i.bak -e "s%:1317%:${EMPED_PORT}317%g;
  s%:8080%:${EMPED_PORT}080%g;
  s%:9090%:${EMPED_PORT}090%g;
  s%:9091%:${EMPED_PORT}091%g" $HOME/.empe-chain/config/app.toml

  # Configure custom ports in config.toml
  sed -i.bak -e "s%:26658%:${EMPED_PORT}658%g;
  s%:26657%:${EMPED_PORT}657%g;
  s%:6060%:${EMPED_PORT}060%g;
  s%:26656%:${EMPED_PORT}656%g;
  s%:26660%:${EMPED_PORT}660%g" $HOME/.empe-chain/config/config.toml

  # Pruning configuration
  pruning="custom"
  pruning_keep_recent="100"
  pruning_keep_every="0"
  pruning_interval="50"
  sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.empe-chain/config/app.toml
  sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.empe-chain/config/app.toml
  sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.empe-chain/config/app.toml
  sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.empe-chain/config/app.toml

  # Minimum gas price configuration
  sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.001uempe"/g' $HOME/.empe-chain/config/app.toml

  # Enable Prometheus
  sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.empe-chain/config/config.toml

  printGreen "8. Starting the service..." && sleep 1
  # Start the service
  sudo tee /etc/systemd/system/emped.service > /dev/null <<EOF
[Unit]
Description=emped
After=network-online.target

[Service]
User=$USER
ExecStart=$(which emped) start --home $HOME/.empe-chain
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

  emped tendermint unsafe-reset-all --home $HOME/.empe-chain
  sudo systemctl daemon-reload
  sudo systemctl enable emped
  sudo systemctl restart emped
  sudo journalctl -u emped -f -o cat
}

# Display the logo
display_logo

# Install Empeiria node
install_node