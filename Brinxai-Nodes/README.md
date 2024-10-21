# Worker Nodes Setup

## System Requirements for Worker Nodes

## Minimum Requirements
To ensure basic functionality of the Worker Node, your system should meet the following minimum specifications:

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 8 VCPU Cores                 |
| **RAM**      | 16 GB RAM                   |
| **Disk**     | 300 GB SSD                 |
| **Port**| 5011 needs to be open (Can be changed to any Port)





# Run the Script
## Instructions

1. Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.

2. **[Register Acount](https://workers.brinxai.com/register.php)**

2. After that, run on Screen:
```python
screen -S brinxai-nodes
```
3. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O Brinxai.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Brinxai-Nodes/Brinxai.sh && chmod +x Brinxai.sh && sed -i 's/\r$//' Brinxai.sh && ./Brinxai.sh
   ```
