
# Worker Nodes Setup

## System Requirements for Worker Nodes

## Minimum Requirements
To ensure basic functionality of the Blockmesh Worker Node, your system should meet the following minimum specifications:

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 2 VCPU Cores                 |
| **RAM**      | 4 GB RAM                   |
| **Disk**     | 50 GB SSD                 |

# Run the Script
## Instructions

1. Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.

2. **[Register Blockmesh Account](https://app.blockmesh.xyz/register?invite_code=LayerAirdrop)**

2. After that, run on Screen:
```python
screen -S blockmesh-nodes
```
3. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O blockmesh.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/refs/heads/main/BlockMesh-Nodes/blockmesh.sh && chmod +x blockmesh.sh && sed -i 's/\r$//' blockmesh.sh && ./blockmesh.sh
   ```
