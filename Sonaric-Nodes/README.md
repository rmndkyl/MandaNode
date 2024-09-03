# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 4 GB
Operating System | Ubuntu 20.04.2 LTS or higher versions (x86-64)
Storage | 20 GB
Network Bandwidth | 10MB/s 

# Instructions

1. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O sonaric.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Sonaric-Nodes/sonaric.sh && chmod +x sonaric.sh && sed -i 's/\r$//' sonaric.sh && ./sonaric.sh
   ```

# Point Calculation
Points are calculated based on your node's uptime, number of running workloads, and the resources it contributes to the network. While your node is running, it will be attributed points every time it sends a heartbeat to the network.

The amount of points you receive each time your node sends a heartbeat is calculated using the following formula:

`points = (uptime_seconds / 600)*(number_of_workloads + gui_running) * multiplier
multiplier = (if cpus < 2 then 0.1 else 1) * (if has_gpu? then 1.2 else 1)
Where:`
 
  - `uptime_seconds` is the number of seconds between heartbeats.
  - `gui_running` is a value indicating whether the Sonaric GUI is running on your node: 1 if it is running, 0 if it is not.
  - `number_of_workloads` is the number of workloads running on your node.
  - `cpus` is the number of CPU cores available on your machine.
  - `has_gpu` is a boolean value indicating whether your machine has a GPU.
  - `multiplier` is a factor that adjusts the points based on the node configuration.
## Tracking your Points
![image](https://github.com/user-attachments/assets/7dabde5a-5952-4cbb-8d9a-cbb878b4d363)

Your rank on the tracker is determined by the number of points you have accumulated. The more points you have, the higher you will be on the tracker.

See the [Sonaric Tracker](https://tracker.sonaric.xyz/) for more information on how to access the leaderboard and track your progress.


   
   
