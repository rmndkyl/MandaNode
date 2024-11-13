# Nodes Setup

## System Requirements for Nodes

## Minimum Requirements
To ensure basic functionality of the Node, your system should meet the following minimum specifications:

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 8 vCPU Cores            |
| **RAM**      | 8 GB RAM               |
| **Disk**     | 100 GB SSD              |

# MAKE SURE PORT THIS BELOW AVAILABLE:
## TCP ports:
 - 8545 (USED BY DILL NODE + STORY PROTOCOL + UNICHAIN)
 - 8546 (USED BY UNICHAIN NODE SEE POST ) 
 - 30303 (USED BY STORY PROTOCOL + UNICHAIN)
 - 9222 (USED BY UNICHAIN)
 - 7300
 - 6060

## UDP ports:
 - 30303 (USED BY STORY PROTOCOL + UNICHAIN)
 
 # Run the Script
 ```shell
 cd $HOME && rm -rf ink.sh && wget -O ink.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/refs/heads/main/Inkonchain-Nodes/ink.sh && chmod +x ink.sh && sed -i 's/\r$//' ink.sh && ./ink.sh
 ```
