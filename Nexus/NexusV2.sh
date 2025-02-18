#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Display a logo
echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -f loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -f logo.sh
sleep 4

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

task() {
    echo -e "${MAGENTA}[TASK]${NC} $1"
}

run_with_spinner() {
    local msg="$1"
    shift
    local cmd=("$@")
    local pid
    local spin_chars='🕘🕛🕒🕡'
    local delay=0.1
    local i=0

    "${cmd[@]}" > /dev/null 2>&1 &
    pid=$!

    printf "${MAGENTA}[TASK]${NC} %s...  " "$msg"

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${MAGENTA}[TASK]${NC} %s... ${CYAN}%s${NC}" "$msg" "${spin_chars:$i:1}"
        sleep "$delay"
    done

    wait "$pid"
    local exit_status=$?

    printf "\r\033[K"
    return $exit_status
}

# Install required packages
task "Installing system dependencies..."
run_with_spinner "Updating packages" sudo apt-get update
run_with_spinner "Installing dependencies" sudo apt-get install -y curl wget build-essential pkg-config libssl-dev unzip git-all

# Install Rust
task "Checking Rust installation"
if ! command -v rustc &> /dev/null; then
    info "Rust not found. Installing..."
    curl -sSL https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Rust-Installer/rust.sh | bash || error "Failed to install Rust"
    source "$HOME/.cargo/env" || warn "Failed to source cargo environment"
else
    success "Rust is already installed"
fi

# Install Protocol Buffers
task "Installing Protocol Buffers"
if ! command -v protoc &> /dev/null; then
    (
        run_with_spinner "Downloading protoc" wget -q https://github.com/protocolbuffers/protobuf/releases/download/v21.5/protoc-21.5-linux-x86_64.zip || exit 1
        run_with_spinner "Extracting protoc" unzip -o protoc-21.5-linux-x86_64.zip -d protoc || exit 1
        sudo rm -rf /usr/local/include/google 2>/dev/null
        run_with_spinner "Installing protoc" sudo mv protoc/bin/protoc /usr/local/bin/ && sudo mv protoc/include/* /usr/local/include/
    ) || error "Protocol Buffers installation failed"
    rm -rf protoc* 2>/dev/null
else
    success "Protocol Buffers already installed"
fi

# Verify systemd
task "Checking systemd"
if ! command -v systemctl &> /dev/null; then
    error "systemd is required but not installed"
fi

# Nexus setup
NEXUS_HOME="$HOME/.nexus"
REPO_PATH="$NEXUS_HOME/network-api"
export NONINTERACTIVE=1

task "Setting up Nexus"
[ -d "$NEXUS_HOME" ] || mkdir -p "$NEXUS_HOME"

if [ -d "$REPO_PATH" ]; then
    run_with_spinner "Updating repository" git -C "$REPO_PATH" stash && git -C "$REPO_PATH" fetch --tags
else
    run_with_spinner "Cloning repository" git clone https://github.com/nexus-xyz/network-api "$REPO_PATH"
fi

latest_tag=$(git -C "$REPO_PATH" describe --tags $(git -C "$REPO_PATH" rev-list --tags --max-count=1))
run_with_spinner "Checking out latest tag" git -C "$REPO_PATH" checkout "$latest_tag"

# Create systemd service
task "Configuring systemd service"
SERVICE_FILE="/etc/systemd/system/nexus.service"
USER=$(whoami)
CARGO_PATH="$HOME/.cargo/bin/cargo"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Nexus Node Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$REPO_PATH/clients/cli
ExecStart=$CARGO_PATH run --release -- --start --beta
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

run_with_spinner "Reloading systemd" sudo systemctl daemon-reload
run_with_spinner "Enabling service" sudo systemctl enable nexus
run_with_spinner "Starting service" sudo systemctl start nexus

success "Installation completed successfully!"
echo -e "Run ${CYAN}journalctl -u nexus.service -f -n 50${NC} to check the service status"
