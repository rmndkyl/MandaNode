#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}[ERROR]${NC} $1"
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

    # Clear the line
    printf "\r\033[K"

    return $exit_status
}

RUSTUP_HOME="${HOME}/.rustup"
CARGO_HOME="${HOME}/.cargo"

load_rust_env() {
    info "Loading Rust environment..."
    export RUSTUP_HOME="${RUSTUP_HOME}"
    export CARGO_HOME="${CARGO_HOME}"
    export PATH="${CARGO_HOME}/bin:${PATH}"
    
    if [ -f "${CARGO_HOME}/env" ]; then
        source "${CARGO_HOME}/env" > /dev/null 2>&1
        success "Rust environment loaded"
    else
        warn "Rust environment file not found at ${CARGO_HOME}/env"
    fi
}

install_dependencies() {
    info "Checking system dependencies..."
    
    if command -v apt &>/dev/null; then
        if ! run_with_spinner "Updating package lists" sudo apt update; then
            error "Failed to update package lists"
            exit 1
        fi
        
        if run_with_spinner "Installing build tools" sudo apt install -y build-essential libssl-dev curl; then
            success "Build tools installed"
        else
            error "Failed to install build tools"
            exit 1
        fi
        
    elif command -v yum &>/dev/null; then
        if ! run_with_spinner "Installing development tools" sudo yum groupinstall -y 'Development Tools'; then
            error "Failed to install development tools"
            exit 1
        fi
        
        if ! run_with_spinner "Installing system libraries" sudo yum install -y openssl-devel curl; then
            error "Failed to install system libraries"
            exit 1
        fi
        
    elif command -v dnf &>/dev/null; then
        if ! run_with_spinner "Installing development tools" sudo dnf groupinstall -y 'Development Tools'; then
            error "Failed to install development tools"
            exit 1
        fi
        
        if ! run_with_spinner "Installing system libraries" sudo dnf install -y openssl-devel curl; then
            error "Failed to install system libraries"
            exit 1
        fi
        
    elif command -v pacman &>/dev/null; then
        if ! run_with_spinner "Updating system packages" sudo pacman -Syu --noconfirm; then
            error "Failed to update system packages"
            exit 1
        fi
        
        if ! run_with_spinner "Installing base development tools" sudo pacman -S --noconfirm base-devel openssl curl; then
            error "Failed to install base development tools"
            exit 1
        fi
    else
        error "Unsupported package manager. Install dependencies manually."
        exit 1
    fi
}

install_rust() {
    if command -v rustup &>/dev/null; then
        warn "Rust is already installed."
        read -rp "Reinstall/update Rust? (y/N): " choice
        if [[ "${choice,,}" == "y" ]]; then
            if run_with_spinner "Uninstalling existing Rust" rustup self uninstall -y; then
                success "Existing Rust installation removed"
            else
                error "Failed to uninstall existing Rust"
                exit 1
            fi
        else
            info "Skipping Rust reinstallation."
            return 0
        fi
    fi

    info "Starting Rust installation (this may take a few minutes)..."
    if run_with_spinner "Installing Rust" bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"; then
        success "Rust installed successfully"
    else
        error "Rust installation failed!"
        exit 1
    fi
}

fix_permissions() {
    info "Verifying directory permissions..."
    for dir in "${RUSTUP_HOME}" "${CARGO_HOME}"; do
        if [ -d "${dir}" ]; then
            if [ "$(stat -c %a "${dir}")" -ne 755 ]; then
                if run_with_spinner "Setting permissions for ${dir}" chmod -R 755 "${dir}"; then
                    success "Permissions set for ${dir}"
                else
                    error "Failed to set permissions for ${dir}"
                    exit 1
                fi
            fi
        else
            warn "Directory not found: ${dir}"
        fi
    done
}

update_shell_profile() {
    local shell_profile
    case "$SHELL" in
        */bash)
            shell_profile="${HOME}/.bashrc"
            ;;
        */zsh)
            shell_profile="${HOME}/.zshrc"
            ;;
        *)
            shell_profile="${HOME}/.profile"
            ;;
    esac

    local env_line="source \"${CARGO_HOME}/env\""

    if [ -f "$shell_profile" ] && ! grep -qF "$env_line" "$shell_profile"; then
        if run_with_spinner "Updating shell profile" bash -c "echo -e '\n# Added by Rust setup script\n${env_line}' >> '$shell_profile'"; then
            success "Shell profile updated. New shells will have Rust environment configured."
        else
            warn "Failed to update shell profile. Add 'source ${CARGO_HOME}/env' manually."
        fi
    else
        info "Rust environment setup already present in $shell_profile"
    fi
}

verify_installation() {
    info "Verifying installation..."
    if command -v rustc &>/dev/null && command -v cargo &>/dev/null; then
        rust_version=$(rustc --version 2>/dev/null)
        cargo_version=$(cargo --version 2>/dev/null)
        success "Rust components verified"
        echo -e "${CYAN}${rust_version}${NC}"
        echo -e "${CYAN}${cargo_version}${NC}"
    else
        error "Rust components not found!"
        exit 1
    fi
}

main() {
    info "Starting Rust installation process..."
    install_dependencies
    install_rust
    load_rust_env
    fix_permissions
    verify_installation
    update_shell_profile
    
    success "Rust setup completed successfully!"
}

main
