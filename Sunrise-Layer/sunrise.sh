#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

set -xe

cd ~
sudo apt update -y
sudo apt install -y jq git build-essential

## go install
wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
# vim ~/.bashrc
# export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
# source ~/.bashrc

git clone https://github.com/SunriseLayer/sunrise-node.git
cd sunrise-node
git checkout v0.13.1-sunrise
make build
sudo make install

# init
sunrise light init --p2p.network private
# Register the service
sudo tee <<EOF >/dev/null /etc/systemd/system/sunrise-light.service
[Unit]                                                               
Description=sunrise-light Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which sunrise) light start --core.ip sunrise-private-2.cauchye.net --p2p.network private
Restart=on-failure
RestartSec=3
LimitNOFILE=1400000

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable sunrise-light
sudo systemctl start sunrise-light && sudo journalctl -u sunrise-light.service -f

echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
echo "================================================================"
echo "Node community Telegram channel: https://t.me/layerairdrop"
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
