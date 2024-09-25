# Hardware Requirements
| Hardware | Requirement |
| ------------- | ---------------- |
Cpu | No Requirement
Architecture | x86-64 (x64, x86_64, AMD64, ve Intel 64)
Memory | No Requirement
Operating System | Ubuntu 22.04.2 LTS or higher versions (x86-64)
Storage | No Requirement
Network Bandwidth | No Requirement

# Instructions

1. **Create Screen First:**
 ```bash
screen -S infinit-deploy
 ```

2. **Download and run the setup script:**

Open your terminal and execute the following command to download and run the script:

   ```sh
   wget -O infinit.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Infinit-Contract-Deploy/infinit.sh && chmod +x infinit.sh && sed -i 's/\r$//' infinit.sh && ./infinit.sh
   ```
 ### When the first Prompt appears, refer to this one:
 - Project Root Directory : `/root/infinit`
 - Chain : `[Testnet] Holesky`
 - Protocol Module : `Uniswap V3`

 ![image](https://github.com/user-attachments/assets/a0207efd-8860-4eba-8ebc-6db422590e55)

 ### Then, you have to create an new wallet and it will prompt you to input **Account ID**,
 - Account ID : `the names of your wallet`
 - Password : `input your password either`
 - Fill in your Created Address with 0.1 ETH (Holesky)
 - After your wallet created, just copy-paste like on picture below
 ![image](https://github.com/user-attachments/assets/ba007929-4f12-4781-8cb9-69430aea5ed6)

 ### Don't forget to backup your privatekeys

 ![image](https://github.com/user-attachments/assets/38f6e00c-68a5-45e2-a262-ed279d5feb71)

 ### Lastly, when the prompt appears, just refer to this:
 - Do you want to simulate the transactions to estimate the gas cost? `no`
 - Confirm execution? `yes`
   
 ![image](https://github.com/user-attachments/assets/fd373393-6d26-4607-aa12-c14cf4530247)

