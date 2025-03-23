# layeredge-cli Node setup guide
How to run layeredge light node on vps

Follow these steps to set up and run your LayerEdge CLI Light Node efficiently.

---

## Hardware requirements:

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | atleast 4 Cores         |
| **RAM**      | 4 - 8 GB                |
| **Disk**     | 100  GB  SSD            |

---

### Rerun from here

```
sudo systemctl stop lightnode.service
sudo systemctl disable lightnode.service
rm -rf light-node
rm -rf /etc/systemd/system/lightnode.service
```

### Step 1: Install Required Dependencies

```
sudo apt update && sudo apt upgrade
sudo apt install nano screen build-essential gcc
```

### Install Go
```
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
source .bash_profile
go version
```
### Install Rust
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

Risc0 Toolchain: If not installed, run:

```
curl -L risczero.com/install | bash

source "/root/.bashrc"

rzup install

source "/root/.bashrc"

sudo apt install cargo

```

### Step 2: Clone the Light Node Repository

```
git clone https://github.com/Layer-Edge/light-node
cd light-node
```

### Step 3: Configure Environment Variables

Set up the required environment variables in your terminal session or add them to a .env file:

```
nano .env
```

```
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='cli-node-private-key'
```

Replace with your privatkey without 0x

### Step 4: Start the Merkle Service

Before running the Light Node, start the Merkle service:

```
screen -S rsic
```

```
cd $HOME/light-node/risc0-merkle-service
cargo build && cargo run
```

Press CTRL + A + D

Wait until the Merkle service is fully initialized before proceeding.

### Step 5: Build and Run the LayerEdge Light Node

```
screen -S lightnode
```
```
cd $HOME/light-node
go build
./light-node
```

Press CTRL + A + D

### create service file for automation

```
sudo nano /etc/systemd/system/lightnode.service
```
```
[Unit]
Description=LayerEdge Light Node
After=network.target

[Service]
User=root
WorkingDirectory=/root/light-node
ExecStart=/root/light-node/light-node
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
EnvironmentFile=/root/light-node/.env

[Install]
WantedBy=multi-user.target
```


```
sudo systemctl daemon-reload
sudo systemctl enable lightnode.service
sudo systemctl start lightnode.service
sudo systemctl status lightnode.service
```

**check logs**

```
sudo journalctl -fu lightnode.service
```

Ensure that the Light Node is running independently and correctly connected to the Merkle service.

**Fetch Points via CLI**
``` 
https://light-node.layeredge.io/api/cli-node/points/{walletAddress}
```
Replace {walletAddress} with your actual CLI wallet address.

### Configure Wallet to dashboard

- Visit : https://dashboard.layeredge.io/ 
- If you don't have an account create one (Code :  YLoguJPr )
- To link your CLI node with the dashboard for analytics:
- Connect your wallet
- Link your CLI node’s Public Key

---

## ☕️ Traktir kopinya & Thanks for Supporting us :
- https://sociabuzz.com/layerairdrop/tribe
- https://saweria.co/LayerAirdrop
- https://trakteer.id/layerairdrop/tip

# Credited By Layer Airdrop
[Telegram Channel](https://t.me/layerairdrop)

[Telegram Group](https://t.me/layerairdropdiskusi)
