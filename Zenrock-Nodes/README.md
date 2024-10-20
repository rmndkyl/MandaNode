# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 4 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 8 GB
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | 100 GB
Network Bandwidth | 10MB/s 

## Instructions

1. Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.

2. After that, run on Screen:
```python
screen -S zenrock-nodes
```
3. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O Zenrock.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Zenrock-Nodes/Zenrock.sh && chmod +x Zenrock.sh && sed -i 's/\r$//' Zenrock.sh && ./Zenrock.sh
   ```

## Useful Tools
### Cek Logs Node
```
sudo journalctl -u zenrock-testnet.service -f --no-hostname -o cat
```
### Start Node
```
sudo systemctl start zenrock-testnet.service
```
### Stop Node
```
sudo systemctl stop zenrock-testnet.service
```
### Cek Status Node
```
sudo systemctl status zenrock-testnet.service
```
### Cek Sinkron Node
```
zenrockd status 2>&1 | jq
```
### Create Wallet
```
zenrockd keys add wallet
```
### Delete Wallet
```
zenrockd keys delete wallet
```
### Cek Saldo Wallet
```
zenrockd q bank balances $(zenrockd keys show wallet -a)
```
### Delegate Token to your self
```
zenrockd tx validation delegate $(zenrockd keys show wallet --bech val -a) 1000000urock --from wallet --chain-id gardia-2 --gas-adjustment 1.4 --gas auto --gas-prices 30urock -y
```
### Delegate Token to My Validator
```
zenrockd tx validation delegate zenvaloper16nhj379jucj8nmqyar6cqs5uezle2ur6ky9pet 400000000urock --from wallet --chain-id gardia-2 --gas-adjustment 1.4 --gas auto --gas-prices 30urock -y
```
### Delete Node
```
cd $HOME
sudo systemctl stop zenrock-testnet.service
sudo systemctl disable zenrock-testnet.service
sudo rm /etc/systemd/system/zenrock-testnet.service
sudo systemctl daemon-reload
rm -f $(which zenrockd)
rm -rf $HOME/.zrchain
```
