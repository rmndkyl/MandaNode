# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 6 Cores
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 32 GB
Operating System | Ubuntu 18.04 or later LTS
Storage | 240 GB

Also, we need to make sure the following requirements are met:

 - Allow incoming connections on port 26656

 - Have a static IP address

 - Have access to the root user

__You can purchase a VPS from__:

- [Contabo](https://contabo.com/en/vps/) (Credit Card/PayPal)
- [DigitalOcean](https://m.do.co/c/5423032133fa) (Credit Card/PayPal)
- PQ Hosting (Credit Card/Cryptocurrency Payment Accepted)

# One-click Installation
```shell
wget https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Empeiria-Nodes/empeiria.sh && chmod +x empeiria.sh && sed -i 's/\r$//' empeiria.sh && ./empeiria.sh