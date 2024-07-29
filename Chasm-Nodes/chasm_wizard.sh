#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

sudo apt-get update && sudo apt get upgrade -y
sudo apt-get install -y ca-certificates curl ufw

if ! command -v ufw &> /dev/null; then
    echo -e "\e[31mThere was an issue installing 'ufw'. Please install 'ufw' manually and then rerun this script.\e[0m"
    echo -e "\e[32mTo install 'ufw', use the following command:\e[0m"
    echo -e "\e[32msudo apt-get install ufw\e[0m"
    exit 1
fi

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\e[33mPlease enter the required information:\e[0m"
read -p $'\e[33mEnter SCOUT_NAME: \e[0m' SCOUT_NAME
read -p $'\e[33mEnter SCOUT_UID: \e[0m' SCOUT_UID
read -p $'\e[33mEnter WEBHOOK_API_KEY: \e[0m' WEBHOOK_API_KEY
read -p $'\e[33mEnter GROQ_API_KEY: \e[0m' GROQ_API_KEY
read -p $'\e[33mEnter OPENROUTER_API_KEY (optional): \e[0m' OPENROUTER_API_KEY
read -p $'\e[33mEnter OPENAI_API_KEY (optional): \e[0m' OPENAI_API_KEY
read -p $'\e[33mEnter WEBHOOK_URL (including http:// and port like : http://x.x.x.x:3001/): \e[0m' WEBHOOK_URL

mkdir chasm
cd chasm

cat <<EOF > .env
PORT=3001
LOGGER_LEVEL=debug

# Chasm
ORCHESTRATOR_URL=https://orchestrator.chasm.net
SCOUT_NAME=$SCOUT_NAME
SCOUT_UID=$SCOUT_UID
WEBHOOK_API_KEY=$WEBHOOK_API_KEY
WEBHOOK_URL=$WEBHOOK_URL

# Chosen Provider (groq, openai)
PROVIDERS=groq
MODEL=gemma2-9b-it
GROQ_API_KEY=$GROQ_API_KEY

# Optional
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY

NODE_ENV=production
EOF

sudo ufw allow 3001
docker pull johnsonchasm/chasm-scout
docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout johnsonchasm/chasm-scout

echo -e "\e[32mInstallation completed successfully!\e[0m"
echo -e "\e[31m██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░\e[0m"
echo -e "\e[31m██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗\e[0m"
echo -e "\e[31m██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝\e[0m"
echo -e "\e[31m██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░\e[0m"
echo -e "\e[31m███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░\e[0m"
echo -e "\e[31m╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░\e[0m"
echo -e "\e[32mScript and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions\e[0m"
echo -e "\e[31m============================ Chasm Node Automation ====================================\e[0m"
echo -e "\e[31mNode community Telegram channel: https://t.me/layerairdrop\e[0m"
echo -e "\e[31mNode community Telegram group: https://t.me/layerairdropdiskusi\e[0m"
echo -e "\e[31mIf UFW is enable please ensure your SSH port is open to access your server.\e[0m"