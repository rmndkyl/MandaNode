# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 4 GB
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | 50 GB SSD
Network Bandwidth | 10MB/s 

# Instructions

1. **First thing, run on Screen:**
   ```sh
   screen -S covalent-nodes
   ```

2. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O covalent.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Network3-Nodes/network3.sh && chmod +x covalent.sh && sed -i 's/\r$//' covalent.sh && ./covalent.sh
   ```