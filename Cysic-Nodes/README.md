![image](https://github.com/user-attachments/assets/2faa6f87-2829-4747-98e2-afb730554351)

# Requirements
Ensure your device meets the following minimal specs for a smooth Cysic verifier program installation:

 - CPU: `Single Core`
 - Memory: `512 MB`
 - Disk: `10 GB`
 - Bandwidth: `100 KB/s upload/download`
 - Available OS: `Linux, Windows, Mac`

# Setup
1. Create your own VPS, you can buy from **[Contabo](https://contabo.com/)** or **[DigitalOcean](https://m.do.co/c/5423032133fa)**.

2. After that, run on Screen:
```shell
screen -S cysic-verifier
```

# One-click Installation
```shell
cd $HOME && rm -rf cysic.sh && wget -O cysic.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Cysic-Nodes/cysic.sh && chmod +x cysic.sh && sed -i 's/\r$//' cysic.sh && ./cysic.sh
```
