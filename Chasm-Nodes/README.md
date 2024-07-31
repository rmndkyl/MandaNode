
# Chasm Network Node Installation Guide

This guide provides instructions on how to set up a Chasm Network Node using a provided bash script. Follow the steps below to get your node up and running.

## Prerequisites

### Server Specifications

| Specification   | Minimum            | Suggested         |
|-----------------|--------------------|-------------------|
| **vCPU**        | 1                  | 2                 |
| **RAM**         | 1GB                | 4GB               |
| **Disk**        | 20GB Disk          | 50GB SSD          |
| **IP**          | Static IP          | Static IP         |

Ensure your server meets these specifications before proceeding with the installation.

## Preparation Steps

1. **Mint Your Scout and Get Keys**

   - Navigate to the [Chasm Minting Page](https://scout.chasm.net/private-mint).
   - Complete the minting process by paying a fee of 0.025 $MNT for gas.
   - After minting, click the button labeled "_mint(scout)".
   - Record the `SCOUT_UID` and `WEBHOOK_API_KEY` values provided.

2. **Obtain Your Groq API Key**

   - Visit the [Groq Console](https://console.groq.com/keys).
   - Generate and save your Groq API Key for later use.

## Installation Steps

1. **Download the Installation Script**

   Download the installation script using the following command:

   ```bash
   curl -O https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Chasm-Nodes/chasm_wizard.sh
   ```

2. **Run the Script**

   Make the script executable and run it:

   ```bash
   chmod +x chasm_wizard.sh
   ./chasm_wizard.sh
   ```

3. **Follow the Prompts**

   The script will prompt you for the following information:
   - **SCOUT_NAME**: Enter a name for your scout.
   - **SCOUT_UID**: Provide your Scout UID.
   - **WEBHOOK_API_KEY**: Provide your Webhook API Key.
   - **GROQ_API_KEY**: Provide your Groq API Key.
   - **OPENROUTER_API_KEY** (optional): Provide if you have one.
   - **OPENAI_API_KEY** (optional): Provide if you have one.
   - **WEBHOOK_URL**: Enter your server's IP address and port.

4. **Verify the Installation**

   After completing the setup, verify the node is functioning correctly:
   - Test the node by running:
     ```bash
     curl localhost:3001
     ```
     You should see an "Ok" response.
   - Check for errors with:
     ```bash
     source ./.env
     curl -X POST          -H "Content-Type: application/json"          -H "Authorization: Bearer $WEBHOOK_API_KEY"          -d '{"body":"{"model":"gemma2-9b-it","messages":[{"role":"system","content":"You are a helpful assistant."}]}"}'          $WEBHOOK_URL
     ```

## Handling Specific Errors

![scout-error](https://github.com/user-attachments/assets/5ceb5ebd-482e-44a0-9f85-b272924f3778)


If you encounter specific issues, such as a network-related error, follow these steps:


1. **Register and Get Ngrok Token**

   - Head over to the [Ngrok Signup Page](https://dashboard.ngrok.com/signup).
   - Once registered, go to the "Your Authtoken" section.
   - Click "Show Authtoken" and copy the token provided.

2. **Install Ngrok**

   Run the following command to install Ngrok:
   ```bash
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok
   ```

3. **Setup Ngrok**

   - Create a new screen session:
     ```bash
     screen -S ngrok
     ```
   - Start Ngrok with the following command, replacing `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` with your actual Authtoken:
     ```bash
     docker run --net=host -it -e NGROK_AUTHTOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ngrok/ngrok:latest http 3001
     ```
   - After starting, Ngrok will display a forwarding URL. Copy this URL.
  
   ![ngrok-url](https://github.com/user-attachments/assets/1db66772-807b-45f9-9c59-7cb710d01c49)


5. **Update .env File**

   - Reattach to your main screen session (or create a new one if necessary), then navigate to your project directory:
     ```bash
     cd chasm
     ```
   - Open the `.env` file for editing:
     ```bash
     nano .env
     ```
   - Replace the `WEBHOOK_URL` value with the forwarding URL you copied. Save the file with `CTRL + X`, press `Y`, and then press `Enter`.

6. **Restart the Scout Node**

   - Stop and remove the existing Docker container:
     ```bash
     docker stop scout && docker rm scout
     ```
   - Pull the latest Docker image and restart the node:
     ```bash
     docker pull johnsonchasm/chasm-scout
     docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout johnsonchasm/chasm-scout
     ```

## Additional Information

- **GitHub Repository**: For more details, visit the [GitHub repository](https://github.com/rmndkyl/MandaNode/tree/main/Chasm-Nodes).
- **Support**: If you encounter any issues, please open an issue on the GitHub repository.

# Credited By Layer Airdrop
[Telegram Channel](https://t.me/layerairdrop)

[Telegram Group](https://t.me/layerairdropdiskusi)