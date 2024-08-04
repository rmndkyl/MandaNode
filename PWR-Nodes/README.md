# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | 1 vCPU
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | 1 GB
Operating System | Ubuntu 18.04 or later LTS
Storage | 25  GB

Also, we need to make sure the following requirements are met:

 - Allow incoming connections on Open TCP Ports: 8231, 8085 | Open UDP Port: 7621

 - Have a static IP address

 - Have access to the root user

__You can purchase a VPS from__:

- [Contabo](https://contabo.com/en/vps/) (Credit Card/PayPal)
- [DigitalOcean](https://m.do.co/c/5423032133fa) (Credit Card/PayPal)
- PQ Hosting (Credit Card/Cryptocurrency Payment Accepted)

# One-click Installation
```shell
wget -O pwr.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/PWR-Nodes/pwr.sh && chmod +x pwr.sh && sed -i 's/\r$//' pwr.sh && ./pwr.sh