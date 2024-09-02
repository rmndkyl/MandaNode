# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 4 GB
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | 50 GB
Network Bandwidth | 10MB/s 

## Persiapan Bahan dulu
- Join Waitlist : https://beta.nesa.ai/
- Register with email & verify

- Signup Hugging Face : https://huggingface.co/
- Register with email & verify
- Login > Go to Profil
- Pilih Settings > Access Token
- Create New Token > Centangin Semua
- Create Token & Copy Api Key


# Instructions

1. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:
   ```sh
screen -S nesa-nodes
   ```

   ```sh
   wget -O setup.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Nesa-Nodes/setup.sh && chmod +x setup.sh && sed -i 's/\r$//' setup.sh && ./setup.sh
   ```
- Pilih Wizardy
- Submit nama node
- Submit Hostname (kalo gk punya langsung enter aja)
- Submit Email (pake email yang udah join whitelist)
- Pilih Miner
- Import Private Key (Pake Leap Wallet)
- Pilih Non-Distributed Miner
- Pilih Model (langsung enter aja)
- Refferal Code (optional)
- Paste Api Key Hugging Face
- Lalu Pilih Yes
- Done. Tinggal nunggu proses sampe selesai

## Perintah Berguna

## Cek Peer ID
```
nano ~/.nesa/identity/node_id.id
```
## Cek Status Node
```
https://node.nesa.ai/nodes/YOUR_PEER_ID
```
## Cek Log Node
```
docker logs orchestrator
```
