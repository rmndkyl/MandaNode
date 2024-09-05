# Setup
1. Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.

# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 2 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 500 MB
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | 50 GB SSD 
Network Bandwidth | 56 Kbps for Download/56 Kbps for Upload 

3. After that, run on Screen:
```python
screen -S sunrise-lightnode
```

# One-click Installation
```shell
wget -O sunrise.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Sunrise-Layer/sunrise.sh && chmod +x sunrise.sh && sed -i 's/\r$//' sunrise.sh && ./sunrise.sh
```
