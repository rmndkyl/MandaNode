# SETUP 
  1. Create [New Repositories](https://github.com/new) on your Github Account and let it Empty.
  2. Each Task must be made into its own repository and should not be mixed together.
  3. Create new files with name `.sh` file below (example : `swisstronik.sh`/`erc20.sh`).
  4. Then copy the codes from your following task and save it.
  5. After all setup is complete, Open Codespaces and Direct into Terminal.
  ![image](https://github.com/user-attachments/assets/e2139d32-ab86-4b16-be49-c6f85b0f91d5)
  ![image](https://github.com/user-attachments/assets/72508f17-cbf5-43e8-b2cb-60334c87542a)

# Swisstronik Deploy
```shell
chmod +x swisstronik.sh && sed -i 's/\r$//' swisstronik.sh && ./swisstronik.sh
```

# Swisstronik ERC-20
```shell
chmod +x erc20.sh && sed -i 's/\r$//' erc20.sh && ./erc20.sh
```

# Swisstronik ERC-721
```shell
chmod +x erc721.sh && sed -i 's/\r$//' erc721.sh && ./erc721.sh
```

# Swisstronik PERC-20
```shell
chmod +x perc20.sh && sed -i 's/\r$//' perc20.sh && ./perc20.sh
```

# Swisstronik PERC-721
```shell
chmod +x perc721.sh && sed -i 's/\r$//' perc721.sh && ./perc721.sh
```
# Note
After everything is complete, push your files with: 
```shell
git add . && git commit -m "feat: initiated the project" && git push origin main
```
