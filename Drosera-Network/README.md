![image](https://github.com/user-attachments/assets/d2dd2f46-4f7a-41a5-9045-f8a48903ab89)

# Drosera Network Node Setup

This repository contains an automated installation script for setting up a Drosera Network node.

## Requirements

- Ubuntu 20.04 or newer
- Minimum 2 CPU cores
- 4GB RAM
- 50GB SSD storage
- EVM wallet with Holesky ETH
- Public IP address (or properly configured port forwarding)

## Quick Start

1. **Run the installation script:**

   ```bash
   cd $HOME && rm -rf drosera.sh && wget -O drosera.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Drosera-Network/drosera.sh && chmod +x drosera.sh && sed -i 's/\r$//' drosera.sh && ./drosera.sh
   ```

   You'll need to provide:
   - Your EVM private key
   - Your EVM wallet address
   - Your GitHub username and email
   - Your server's public IP address

## Post-Installation Steps

After successful installation, you'll need to:

1. Visit https://app.drosera.io/
2. Connect your wallet (the same one used during setup)
3. Go to "Traps Owned" section to check your trap
4. Send Bloom Boost to your trap (deposit some Holesky ETH)
5. Opt-in to connect your operator to the trap

## Monitoring Your Node

Check your node status with:

```bash
journalctl -u drosera.service -f
```

## Common Issues & Troubleshooting

- **Insufficient funds error**: Ensure your wallet has enough Holesky ETH
- **API rate limit (429) errors**: Wait a few minutes and try again
- **Trap not showing in dashboard**: Transaction might still be processing
- **Node service not starting**: Check logs with `systemctl status drosera`

## Security Considerations

- Never share your private key with anyone
- Ensure your server's firewall is properly configured
- Regularly update your system and the node software

## Community Support

Join the Drosera Network Discord for support: https://discord.gg/UXAdpTYjgr

## License

This script is provided under the MIT License.
