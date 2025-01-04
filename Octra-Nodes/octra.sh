#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command was successful
check_error() {
    if [ $? -ne 0 ]; then
        log_error "$1"
        exit 1
    fi
}

# Function to create backup
create_backup() {
    if [ -f "hash_id_config.json" ]; then
        backup_file="hash_id_config.json.backup.$(date +%Y%m%d_%H%M%S)"
        cp hash_id_config.json "$backup_file"
        log_success "Backup created: $backup_file"
    fi
}

# Function to check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        log_error "Please run as root (use sudo)"
        exit 1
    fi

    # Check available memory
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 2048 ]; then
        log_warning "Recommended memory is at least 2GB. Current: ${total_mem}MB"
    fi

    # Check available disk space
    free_space=$(df -m / | awk '/^\//{print $4}')
    if [ "$free_space" -lt 5120 ]; then
        log_warning "Recommended free space is at least 5GB. Current: ${free_space}MB"
    fi
}

# Main installation function
install_octra() {
    log_info "Starting Octra Node installation..."

    # Update system packages
    log_info "Updating system packages..."
    apt update && apt upgrade -y
    check_error "Failed to update system packages"

    # Install dependencies
    log_info "Installing required dependencies..."
    apt install -y ocaml-findlib curl wget git build-essential
    check_error "Failed to install dependencies"

    # Set up environment
    log_info "Setting up environment..."
    wget https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Octra-Nodes/env.sh
    check_error "Failed to download environment script"
    
    chmod +x env.sh
    sed -i 's/\r$//' env.sh
    ./env.sh
    check_error "Failed to execute environment script"

    # Configure environment variables
    log_info "Configuring environment variables..."
    if ! grep -q "opam-init" "$HOME/.profile" 2>/dev/null; then
        echo '. "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true' >> "$HOME/.profile"
    fi
    source "$HOME/.profile"

    # Install OCaml packages
    log_info "Installing OCaml packages..."
    opam install -y yojson cohttp-lwt-unix lwt_ppx
    check_error "Failed to install OCaml packages"

    # Download and configure application
    log_info "Downloading configuration file..."
    wget https://raw.githubusercontent.com/rmndkyl/MandaNode/main/Octra-Nodes/config.ml
    check_error "Failed to download configuration file"

    # Compile configuration
    log_info "Compiling configuration..."
    ocamlfind ocamlopt -o config -thread -linkpkg -package yojson,cohttp-lwt-unix,unix,str,lwt_ppx config.ml
    check_error "Failed to compile configuration"

    # Create backup before running config
    create_backup

    # Run configuration
    log_info "Running configuration..."
    ./config
    check_error "Failed to run configuration"

    log_success "Octra Node installation completed successfully!"
    log_warning "IMPORTANT: Make sure to backup your hash_id_config.json file!"
}

# Function to display script usage
show_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  sudo ./install_octra.sh [OPTIONS]"
    echo -e "\n${BLUE}Options:${NC}"
    echo -e "  -h, --help     Show this help message"
    echo -e "  --no-backup    Skip backup creation"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
check_requirements
install_octra
