# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 4 GB
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | 40 GB
Network Bandwidth | 10MB/s 

# T3rn Public Testnet Information
| Network Name     | BRN (Tern) Testnet |
| ------------- | ---------------- |
Rpc URL | https://brn.rpc.caldera.xyz/http
Chain ID | 6636130
Currency Symbol | BRN
Explorer URL | https://brn.explorer.caldera.xyz

## Instructions

1. Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.

2. After that, run on Screen:
```python
screen -S tern-executor
```

3. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

## This is for One-Account(PrivateKeys)(_Still can't accessible_)

   ```sh
   wget -O tern.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Tern-Light-Nodes/tern.sh && chmod +x tern.sh && sed -i 's/\r$//' tern.sh && ./tern.sh
   ```

## This is for Multi-Account(Multi PrivateKeys)

   ```sh
   wget -O tern-multi.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Tern-Light-Nodes/tern-multi.sh && chmod +x tern-multi.sh && sed -i 's/\r$//' tern-multi.sh && ./tern-multi.sh
   ```
