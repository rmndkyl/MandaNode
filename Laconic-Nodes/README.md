![image](https://github.com/user-attachments/assets/e75ee3c7-a5a5-45a8-b5d1-7455297c745f)
-----
# Setup
* Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.
* Visit [Laconic Wallet](https://wallet.laconic.com/) and create a wallet. Save the mnemonic!
* Register for the testnet at [Website](https://loro-signup.laconic.com/) and follow the registration steps provided in the follow-up email. Registration closes at 7:00 UTC on August 14.
* Bookmark the LORO testnet repo.

### Prerequisites

| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 8 GB
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | 200 GB
Network Bandwidth | 1MB/s
* Testnet genesis file and peer node address
* Mnemonic from the wallet app
* Participant onboarded in Stage 0
* Stage 1 has started


# One-click Installation
### Get into root first
```bash
sudo -i
```
### Then run code below
```shell
wget -O setup.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Laconic-Nodes/setup.sh && chmod +x setup.sh && sed -i 's/\r$//' setup.sh && ./setup.sh
```
