### Server Specifications

| Specification   | Minimum            | Suggested         |
|-----------------|--------------------|-------------------|
| **vCPU**        | 6                  | 8                 |
| **RAM**         | 16GB               | 32GB              |
| **Disk**        | 1TB Disk           | 1TB SSD           |
| **IP**          | Static IP          | Static IP         |

# Setup
1. Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.

2. After that, run on Screen:
```python
screen -S symphony
```
3. Run the command below

# One-Click Installation

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O symphony.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Symphony-Nodes/symphony.sh && chmod +x symphony.sh && sed -i 's/\r$//' symphony.sh && ./symphony.sh
   ```
