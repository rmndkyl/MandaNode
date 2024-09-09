# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 4 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 8 GB
Operating System | Ubuntu 20.04.2 LTS or higher versions (x86-64)
Storage | 100+ GB
Network Bandwidth | 10MB/s 

# Instructions

1. **First thing, run on Screen:**
```bash
screen -S autonomys-nodes
```

2. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O autonomys.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Autonomys-Nodes/autonomys.sh && chmod +x autonomys.sh && sed -i 's/\r$//' autonomys.sh && ./autonomys.sh
   ```
