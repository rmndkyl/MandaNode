#!/usr/bin/env bash
set -euo pipefail

# Show Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Check if running with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with root privileges."
  exit 1
fi

# Define constants
MIN_DOCKER_VERSION="20.10"
MIN_COMPOSE_VERSION="1.29.2"
AZTEC_CLI_URL="https://install.aztec.network"
DATA_DIR="$(pwd)/data"

# Function: Print information
print_info() {
  echo "$1"
}

# Function: Check if command exists
check_command() {
  command -v "$1" &> /dev/null
}

# Function: Compare version numbers
version_ge() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

# Function: Install package
install_package() {
  local pkg=$1
  print_info "Installing $pkg..."
  apt-get install -y "$pkg"
}

# Update apt sources (only once)
update_apt() {
  if [ -z "${APT_UPDATED:-}" ]; then
    print_info "Updating apt sources..."
    apt-get update
    APT_UPDATED=1
  fi
}

# Check and install Docker
install_docker() {
  if check_command docker; then
    local version
    version=$(docker --version | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
    if version_ge "$version" "$MIN_DOCKER_VERSION"; then
      print_info "Docker is already installed, version $version, meets requirements (>= $MIN_DOCKER_VERSION)."
      return
    else
      print_info "Docker version $version is too low (required >= $MIN_DOCKER_VERSION), will reinstall..."
    fi
  else
    print_info "Docker not found, installing..."
  fi

  update_apt
  install_package "apt-transport-https ca-certificates curl gnupg-agent software-properties-common"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  update_apt
  install_package "docker-ce docker-ce-cli containerd.io"
}

# Check and install Docker Compose
install_docker_compose() {
  if check_command docker-compose; then
    local version
    version=$(docker-compose --version | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
    if version_ge "$version" "$MIN_COMPOSE_VERSION"; then
      print_info "Docker Compose is already installed, version $version, meets requirements (>= $MIN_COMPOSE_VERSION)."
      return
    else
      print_info "Docker Compose version $version is too low (required >= $MIN_COMPOSE_VERSION), will reinstall..."
    fi
  else
    print_info "Docker Compose not found, installing..."
  fi

  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

# Check and install Node.js
install_nodejs() {
  if check_command node; then
    print_info "Node.js is already installed."
    return
  fi

  print_info "Node.js not found, installing latest version..."
  curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
  update_apt
  install_package nodejs
}

# Install Aztec CLI
install_aztec_cli() {
  print_info "Installing Aztec CLI and preparing alpha testnet..."
  if ! curl -sL "$AZTEC_CLI_URL" | bash; then
    echo "Aztec CLI installation failed."
    exit 1
  fi

  export PATH="$HOME/.aztec/bin:$PATH"
  if ! check_command aztec-up; then
    echo "Aztec CLI installation failed, aztec-up command not found."
    exit 1
  fi

  aztec-up alpha-testnet
}

# Validate URL format (simple check if it starts with http:// or https://)
validate_url() {
  local url=$1
  local name=$2
  if [[ ! "$url" =~ ^https?:// ]]; then
    echo "Error: $name format invalid, must start with http:// or https://."
    exit 1
  fi
}

# Main logic
main() {
  # Install dependencies
  install_docker
  install_docker_compose
  install_nodejs
  install_aztec_cli

  # Get user input
  print_info "Instructions for obtaining RPC URLs:"
  print_info "  - L1 Execution Client (EL) RPC URL:"
  print_info "    1. Get Sepolia RPC (http://xxx) from https://dashboard.alchemy.com/"
  print_info ""
  print_info "  - L1 Consensus (CL) RPC URL:"
  print_info "    1. Get Sepolia RPC (http://xxx) from https://drpc.org/"
  print_info ""

  read -p " L1 Execution Client (EL) RPC URL: " ETH_RPC
  read -p " L1 Consensus (CL) RPC URL: " CONS_RPC
  read -p " Validator Private Key: " VALIDATOR_PRIVATE_KEY
  BLOB_URL="" # Skip Blob Sink URL by default

  # Validate input
  validate_url "$ETH_RPC" "L1 Execution Client (EL) RPC URL"
  validate_url "$CONS_RPC" "L1 Consensus (CL) RPC URL"
  if [ -z "$VALIDATOR_PRIVATE_KEY" ]; then
    echo "Error: Validator private key cannot be empty."
    exit 1
  fi

  # Get public IP
  print_info "Getting public IP..."
  PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
  print_info "    → $PUBLIC_IP"

  # Generate .env file
  print_info "Generating .env file..."
  cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
DATA_DIRECTORY="/data"
LOG_LEVEL="debug"
EOF

  if [ -n "$BLOB_URL" ]; then
    echo "BLOB_SINK_URL=\"$BLOB_URL\"" >> .env
  fi

  # Set BLOB_FLAG
  BLOB_FLAG=""
  if [ -n "$BLOB_URL" ]; then
    BLOB_FLAG="--sequencer.blobSinkUrl \$BLOB_SINK_URL"
  fi

  # Generate docker-compose.yml file
  print_info "Generating docker-compose.yml file..."
  cat > docker-compose.yml <<EOF
version: "3.8"
services:
  node:
    image: aztecprotocol/aztec:0.85.0-alpha-testnet.5
    network_mode: host
    environment:
      - ETHEREUM_HOSTS=\${ETHEREUM_HOSTS}
      - L1_CONSENSUS_HOST_URLS=\${L1_CONSENSUS_HOST_URLS}
      - P2P_IP=\${P2P_IP}
      - VALIDATOR_PRIVATE_KEY=\${VALIDATOR_PRIVATE_KEY}
      - DATA_DIRECTORY=\${DATA_DIRECTORY}
      - LOG_LEVEL=\${LOG_LEVEL}
      - BLOB_SINK_URL=\${BLOB_SINK_URL:-}
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer $BLOB_FLAG'
    volumes:
      - $DATA_DIR:/data
EOF

  # Create data directory
  mkdir -p "$DATA_DIR"

  # Start node
  print_info "Starting Aztec full node (docker-compose up -d)..."
  if ! docker-compose up -d; then
    echo "Failed to start Aztec node, please check docker-compose logs."
    exit 1
  fi

  # Completion
  print_info "Installation and startup complete!"
  print_info "  - View logs: docker-compose logs -f"
  print_info "  - Data directory: $DATA_DIR"
}

# Execute main logic
main
