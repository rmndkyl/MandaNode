
#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

prompt() {
    local message="$1"
    read -p "$message" input
    echo "$input"
}

execute_and_prompt() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    eval "$command"
    echo -e "${GREEN}Done.${NC}"
}

echo -e "${YELLOW}Installing Rust...${NC}"
echo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
echo -e "${GREEN}Rust installed: $(rustc --version)${NC}"
echo

echo -e "${YELLOW}Removing Node.js...${NC}"
echo
sudo apt-get remove -y nodejs
echo

echo -e "${YELLOW}Installing NVM and Node.js LTS...${NC}"
echo
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && export NVM_DIR="/usr/local/share/nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"; source ~/.bashrc; nvm install --lts; nvm use --lts
echo -e "${GREEN}Node.js installed: $(node -v)${NC}"
echo

echo -e "${YELLOW}Cloning repository and installing npm dependencies...${NC}"
echo
git clone https://github.com/Eclipse-Laboratories-Inc/eclipse-deposit
cd eclipse-deposit
npm install
echo

echo -e "${YELLOW}Installing Solana CLI...${NC}"
echo
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo -e "${GREEN}Solana CLI installed: $(solana --version)${NC}"
echo

echo -e "${YELLOW}Generating new Solana keypair...${NC}"
echo
solana-keygen new -o ~/my-wallet.json
echo
echo -e "${YELLOW}Save these mnemonic phrases in safe Place.If there will any Airdrop in future, you will be eligible from this wallet so save it${NC}"
echo

read -p "Enter your mneomic phrase: " mnemonic
echo

cat << EOF > secrets.json
{
  "seedPhrase": "$mnemonic"
}
EOF

cat << 'EOF' > derive-wallet.cjs
const { seedPhrase } = require('./secrets.json');
const { HDNodeWallet } = require('ethers');
const fs = require('fs');

const mnemonicWallet = HDNodeWallet.fromPhrase(seedPhrase);
const privateKey = mnemonicWallet.privateKey;

console.log();
console.log('ETHEREUM PRIVATE KEY:', privateKey);
console.log();
console.log('SEND SEPOLIA ETH TO THIS ADDRESS:', mnemonicWallet.address);

fs.writeFileSync('private-key.txt', privateKey, 'utf8');
EOF

if ! npm list ethers &>/dev/null; then
  echo "ethers.js not found. Installing..."
  echo
  npm install ethers
  echo
fi

node derive-wallet.cjs
echo

echo -e "${YELLOW}Configuring Solana CLI...${NC}"
echo
solana config set --url https://testnet.dev2.eclipsenetwork.xyz/
solana config set --keypair ~/my-wallet.json
echo
echo -e "${GREEN}Solana Address: $(solana address)${NC}"
echo

if [ -d "testnet-deposit" ]; then
    execute_and_prompt "Removing testnet-deposit Folder..." "rm -rf testnet-deposit"
fi

read -p "Enter your Solana address: " solana_address
read -p "Enter your Ethereum Private Key: " ethereum_private_key
read -p "Enter the number of times to repeat Transaction (4-5 tx Recommended): " repeat_count
echo

for ((i=1; i<=repeat_count; i++)); do
    echo -e "${YELLOW}Running Bridge Script (Tx $i)...${NC}"
    echo
    node bin/cli.js -k private-key.txt -d "$solana_address" -a 0.01 --sepolia
    echo
    sleep 3
done

echo -e "${RED}It will take 4 mins, Don't do anything, Just Wait${RESET}"
echo

sleep 240

execute_and_prompt "Creating token..." "spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
echo

token_address=$(prompt "Enter your Token Address: ")
echo
execute_and_prompt "Creating token account..." "spl-token create-account $token_address"
echo

execute_and_prompt "Minting token..." "spl-token mint $token_address 10000"
echo
execute_and_prompt "Checking token accounts..." "spl-token accounts"
echo

cd $HOME

echo -e "${YELLOW}Installing @solana/web3.js...${NC}"
echo
npm install @solana/web3.js
echo

ENCRYPTED_KEY=$(cat my-wallet.json)

cat <<EOF > private-key.js
const solanaWeb3 = require('@solana/web3.js');

const byteArray = $ENCRYPTED_KEY;

const secretKey = new Uint8Array(byteArray);

const keypair = solanaWeb3.Keypair.fromSecretKey(secretKey);

console.log("Your Solana Address:", keypair.publicKey.toBase58());
console.log("Solana Wallet's Private Key:", Buffer.from(keypair.secretKey).toString('hex'));
EOF

node private-key.js

echo
echo -e "${GREEN}Save this Private Key in a safe place. If there is any airdrop in the future, you will be eligible from this wallet, so save it.${NC}"
echo
execute_and_prompt "Checking Program Address..." "solana address"
echo
echo -e "${YELLOW}==============================Eclipse Token Creation====================================${NC}"
echo
echo -e "${YELLOW}The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version.${NC}"
echo
echo -e "${YELLOW}Submit Feedback at${NC}: https://docs.google.com/forms/d/e/1FAIpQLSfJQCFBKHpiy2HVw9lTjCj7k0BqNKnP6G1cd0YdKhaPLWD-AA/viewform?pli=1"
echo
