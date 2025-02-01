# ZKVERIFY Incentive Testnet Phase 2 - Validator Node Setup Guide

## 🔧 Minimum VPS Requirements
Ensure your server meets the following minimum specifications:

- **CPU Cores:** 1
- **Threads per Core:** 2
- **Clock Speed:** 2.2 GHz
- **Memory:** 2 GiB
- **Bandwidth:** Up to 5 Gigabit
- **Storage:** 150 GB

---

## 🛠 Step 1: Install Dependencies
Update your system and install the required packages:
```sh
sudo apt update && sudo apt install -y docker.io docker-compose jq sed
```

---

## 👤 Step 2: Create a New User & Add to Docker Group

1. Add your current user to the `docker` group:
   ```sh
   sudo usermod -aG docker $USER
   newgrp docker
   ```
2. Create a new user `zkverify` and set a password:
   ```sh
   sudo useradd -m -s /bin/bash zkverify
   sudo passwd zkverify
   ```
3. Add `zkverify` to the `docker` group:
   ```sh
   sudo usermod -aG docker zkverify
   ```

---

## 📂 Step 3: Switch to `zkverify` User
```sh
su - zkverify
cd ~
```

---

## 🔄 Step 4: Clone the Repository
```sh
git clone https://github.com/zkVerify/compose-zkverify-simplified.git
cd compose-zkverify-simplified
```

---

## 🚀 Step 5: Initialize the Node
Run the initialization script:
```sh
./scripts/init.sh
```
Follow the prompts:
- **Select:** `Validator Node`
- **Network:** `Testnet`
- **Create Node Name:** `Yes`
- **Additional Configurations:** `No`
- **Enable Additional Logs:** `No`

---

## ▶️ Step 6: Start the Validator Node
```sh
./scripts/start.sh
```
Choose the following options:
- **Select:** `Validator Node`
- **Network:** `Testnet`

Alternatively, start the node manually using Docker:
```sh
docker compose -f /home/zkverify/compose-zkverify-simplified/deployments/validator-node/testnet/docker-compose.yml up -d
```

---

## 📜 Step 7: Check Node Logs
Monitor the logs to ensure the node is running correctly:
```sh
docker logs -f validator-node
```

---

## 🔐 Step 8: Backup Your Wallet
Retrieve your secret phrase and wallet JSON:
```sh
cat /home/zkverify/compose-zkverify-simplified/deployments/validator-node/testnet/configs/node/secrets/secret_phrase.dat

cat /home/zkverify/compose-zkverify-simplified/deployments/validator-node/testnet/configs/node/secrets/secret.json
```
⚠️ **Store these securely!** They are required to restore your node.

---

## 🔗 Step 9: Import Wallet into Polkadot.js
1. Install the Polkadot.js extension: [Chrome Web Store](https://chromewebstore.google.com/detail/polkadot%7Bjs%7D-extension/mopnmbcafieddcagagdcbnhejhlodfdd)
2. Open the extension and import your wallet using the saved secret phrase.

---

## 💰 Step 10: Claim Faucet Tokens
Claim testnet tokens from the ZKVerify Faucet:
[https://zkverify-faucet.zkverify.io/](https://zkverify-faucet.zkverify.io/)

---

## ⏳ Step 11: Wait for Synchronization & Register Validator
1. Wait until the node is fully synchronized.
2. Register as a validator via Polkadot.js:
   [https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Ftestnet-rpc.zkverify.io#/staking](https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Ftestnet-rpc.zkverify.io#/staking)
3. Follow the official validator guide:
   [https://docs.zkverify.io/tutorials/how_to_run_a_node/run_using_docker/run_new_validator_node/#next-steps](https://docs.zkverify.io/tutorials/how_to_run_a_node/run_using_docker/run_new_validator_node/#next-steps)

---

## ✅ Step 12: Verify Your Validator
Check your validator status on the telemetry dashboard:
[https://testnet-telemetry.zkverify.io/](https://testnet-telemetry.zkverify.io/)

---

## 🎯 Step 13: Complete Galxe Tasks
Complete the required Galxe quests:
[https://app.galxe.com/quest/QzaQxuvgdzSVXmvvcY5HHy/GCRCJtV8PN](https://app.galxe.com/quest/QzaQxuvgdzSVXmvvcY5HHy/GCRCJtV8PN)
- **Quiz Answers:**
  - `A`
  - `A`
  - `D`

---

## 📖 Additional Resources
- [Blog Announcement](https://blog.zkverify.io/posts/phase-2-of-the-zkverify-incentivized-testnet-is-live)
- [Official Documentation](https://docs.zkverify.io/)

---

🎉 **Congratulations! You have successfully set up your ZKVERIFY Validator Node.** 🎉

