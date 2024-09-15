#!/bin/bash

# Showing Logo
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

_ROOT="$(pwd)" && cd "$(dirname "$0")" && ROOT="$(pwd)"
PJROOT="$ROOT"
DILL_DIR="$PJROOT/dill"

download=1
if [ $# -ge 1 ]; then
    download=$1
fi

version="v1.0.3"
function launch_dill() {
    
    # Detect operating system type
    os_type=$(uname)   # Darwin or Linux
    chip=$(uname -m)
    
    dill_darwin_file="dill-$version-darwin-arm64.tar.gz"
    dill_linux_file="dill-$version-linux-amd64.tar.gz"
    DILL_DARWIN_ARM64_URL="https://dill-release.s3.ap-southeast-1.amazonaws.com/$version/$dill_darwin_file"
    DILL_LINUX_AMD64_URL="https://dill-release.s3.ap-southeast-1.amazonaws.com/$version/$dill_linux_file"

    if [ "$os_type" == "Darwin" ]; then
        if [ "$chip" == "arm64" ]; then
            echo "Supported system: OS type: $os_type, Chip: $chip"
            if [ "$download" != "0" ]; then
                curl -O $DILL_DARWIN_ARM64_URL
                tar -zxvf $dill_darwin_file
            fi
        else
            echo "Unsupported system: OS type: $os_type, Chip: $chip"
            exit 1
        fi
    else
        if [ "$chip" == "x86_64" ] && [ -f /etc/os-release ]; then
            if ! grep -qi "flags.*:.*adx" /proc/cpuinfo; then
                echo "Warning: The CPU lacks the required instruction set extension (adx) and may not run properly."
                echo "You may still attempt to run it. Press any key to continue..."
                read -n 1 -s -r
            fi

            source /etc/os-release
            if [ "$ID" == "ubuntu" ]; then
                major_version=$(echo $VERSION_ID | cut -d. -f1)
                if [ $major_version -ge 20 ]; then
                    echo "Supported system: OS: $ID $VERSION_ID, Chip: $chip"; echo""
                    if [ "$download" != "0" ]; then
                        curl -O $DILL_LINUX_AMD64_URL
                        tar -zxvf $dill_linux_file
                    fi
                else
                    echo "Unsupported system: OS: $ID $VERSION_ID (requires Ubuntu 20.04 or later)"
                    exit 1
                fi
            else
                echo "Unsupported system: OS type: $os_type, Chip: $chip, $ID $VERSION_ID"
                exit 1
            fi
        else
            echo "Unsupported system: OS type: $os_type, Chip: $chip"
            exit 1
        fi
    fi
    
    $DILL_DIR/1_launch_dill_node.sh
}

function add_validator() {
    $DILL_DIR/2_add_validator.sh
}

function main_menu() {
    clear
    echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
    echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
    echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
    echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
    echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
    echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
    echo "----------------------------------------"
    echo "         Dill Node Management           "
    echo "----------------------------------------"
    echo "  1. Launch a new Dill node             "
    echo "  2. Add a validator to an existing node"
    echo "----------------------------------------"
    
    while true; do
        read -p "Please select an option [1 or 2] (default is 1): " purpose
        purpose=${purpose:-1}  # Set default choice to 1
        case "$purpose" in
            "1")
                launch_dill
                break
                ;;
            "2")
                add_validator
                break 
                ;;
            *)
                echo ""
                echo "[Error] '$purpose' is not a valid option."
                ;;
        esac
    done
}

# Run the main menu function
main_menu
