# VPS Requirements
```bash
RAM: 16 GB
CPU: 8 cores
Disk: 300 GB SSD NVMe
Bandwidth: 500 MB/s
```

__You can purchase a VPS from__:

- [Contabo](https://contabo.com/en/vps/) (Credit Card/PayPal)
- [DigitalOcean](https://m.do.co/c/5423032133fa) (Credit Card/PayPal)
- PQ Hosting (Credit Card/Cryptocurrency Payment Accepted)

# Wallet Setup and Faucet Request
- Download the Fearless Wallet Extension
- Create a new wallet
- Join the Analog Discord
- Request faucet in the 🚰| faucet channel using the following command:
```bash
!faucet your..analog..wallet..address..here
```

# Deployment
Open Termius / Putty

- Copy and paste the following command:
```bash
wget -O analog.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Analog-Timechain/analog.sh && chmod +x analog.sh && sed -i 's/\r$//' analog.sh && ./analog.sh
```
- You can check the Analog node logs using this command:
```bash
docker logs analog
```
# Validator Setup
- Visit: [This site](https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Frpc.testnet.analog.one#/staking/actions)
- Click on the Validator option in the top right corner
- Select your Analog wallet in the stash account section and keep the other details as default
- Click the Next button
- Enter your rotate key in the keys from rotatekeys section
- You can write 1 to 10 in the reward commission percentage section
- Then click the Bond & Validate button
# Whitelist Form Submission
Submit this Form with the appropriate details and wait for approval from the Analog team
