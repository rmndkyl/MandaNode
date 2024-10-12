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