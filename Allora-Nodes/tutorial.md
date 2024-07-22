# Minimum Specs
• CPU 1 Core => Recommended 2 Core

• RAM 2 GB => Recommended 4 GB

• SSD 50 GB => Recommended 100GB

# Setup
1. Create a wallet on Keplr Wallet.
2. [Connect HERE](https://app.allora.network/points/overview) and copy your addy.
3. Claim ALLO faucet in [HERE](https://faucet.edgenet.allora.network/).
4. Run our One Click Installation script:
```shell
wget https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Allora-Nodes/allora.sh && sed -i 's/\r$//' allora.sh && chmod +x allora.sh && ./allora.sh
```
5. Select "Import Wallet", then paste your mnemonic.
6. After its running, check it by [THIS](https://t.me/layerairdropdiskusi/28164) command.
```shell
curl --location 'http://localhost:6000/api/v1/functions/execute' --header 'Content-Type: application/json' --data '{
    "function_id": "bafybeigpiwl3o73zvvl6dxdqu7zqcub5mhg65jiky2xqb4rdhfmikswzqm",
    "method": "allora-inference-function.wasm",
    "parameters": null,
    "topic": "4",
    "config": {
        "env_vars": [
            {
                "name": "BLS_REQUEST_PATH",
                "value": "/api"
            },
            {
                "name": "ALLORA_ARG_PARAMS",
                "value": "BTC"
            }
        ],
        "number_of_nodes": -1,
        "timeout": 2
    }
}'
```
8. If the result is `200`, it works. If the result is `408`, the team still fix the bug.
9. Done ✅
