#!/bin/bash

# Display a logo
echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -f loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -f logo.sh
sleep 4

# Install necessary packages
echo "Installing necessary packages..."
sudo apt update
sudo apt install -y protobuf-compiler docker.io jq curl iptables build-essential git wget lz4 make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
sudo systemctl start docker
sudo systemctl enable docker
echo "Packages installed successfully."

# Check if the directory exists
if [ -d "nexus-docker" ]; then
  echo "Directory nexus-docker already exists."
else
  mkdir nexus-docker
  echo "Directory nexus-docker created."
fi

# Navigate into the directory
cd nexus-docker

# Ask for Prover ID
read -p "Enter your Prover ID: " prover_id

# Create or replace the Dockerfile with the specified content
cat <<EOL > Dockerfile
FROM ubuntu:latest
# Disable interactive configuration
ENV DEBIAN_FRONTEND=noninteractive

# Update and upgrade the system
RUN apt-get update && apt-get install -y \\
    curl \\
    iptables \\
    iproute2 \\
    jq \\
    nano \\
    git \\
    build-essential \\
    wget \\
    lz4 \\
    make \\
    gcc \\
    automake \\
    autoconf \\
    tmux \\
    htop \\
    nvme-cli \\
    pkg-config \\
    libssl-dev \\
    libleveldb-dev \\
    tar \\
    clang \\
    bsdmainutils \\
    ncdu \\
    unzip \\
    ca-certificates \\
    protobuf-compiler

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:\${PATH}"

# Set up Nexus Prover ID using the user provided value
RUN mkdir -p /root/.nexus && echo "$prover_id" > /root/.nexus/prover-id

# Run the Nexus command and then open a shell
CMD ["bash", "-c", "curl -k https://cli.nexus.xyz/ | sh && nexus run; exec /bin/bash"]
EOL

# Detect existing nexus-docker instances and find the highest instance number
existing_instances=$(docker ps -a --filter "name=nexus-docker-" --format "{{.Names}}" | grep -Eo 'nexus-docker-[0-9]+' | grep -Eo '[0-9]+' | sort -n | tail -1)

# Set the instance number
if [ -z "$existing_instances" ]; then
  instance_number=1
else
  instance_number=$((existing_instances + 1))
fi

# Set the container name
container_name="nexus-docker-$instance_number"

# Create a data directory for the instance
data_dir="/root/nexus-data/$container_name"
mkdir -p "$data_dir"

# Build the Docker image with the specified name
docker build -t $container_name .

# Display the completion message
echo -e "\e[32mSetup is complete. To run the Docker container, use the following command:\e[0m"
echo "docker run -it --name $container_name -v $data_dir:/root/.nexus $container_name"
