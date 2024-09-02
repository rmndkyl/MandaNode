# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 2 GB
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | 40 GB SSD
Network Bandwidth | 10MB/s 

# Instructions

1. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:
   ```sh
screen -S waku-nodes
   ```

   ```sh
   wget -O waku.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Waku-Nodes/waku.sh && chmod +x waku.sh && sed -i 's/\r$//' waku.sh && ./waku.sh
   ```