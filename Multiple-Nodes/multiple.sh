# !/bin/bash

# Display Loader and Logo
echo -e "${BLUE}Loading setup files...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh

echo -e "${BLUE}Displaying LOGO...${NC}"
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 2

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}



#Function to check system type and root privileges
master_fun() {
    echo "Checking system requirements..."

    # Check if the system is Ubuntu
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            echo "This script is designed for Ubuntu. Exiting."
            exit 1
        fi
    else
        echo "Cannot detect operating system. Exiting."
        exit 1
    fi

    # Check if the user is root
    if [ "$EUID" -ne 0 ]; then
        echo "You are not running as root. Please enter root password to proceed."
        sudo -k  # Force the user to enter password
        if sudo true; then
            echo "Switched to root user."
        else
            echo "Failed to gain root privileges. Exiting."
            exit 1
        fi
    else
        echo "You are running as root."
    fi

    echo "System check passed. Proceeding to package installation..."
}


# Function to install dependencies
install_dependency() {
    print_info "<=========== Install Dependency ==============>"
    print_info "Updating and upgrading system packages, and installing curl..."
    sudo apt update && sudo apt upgrade -y && sudo apt install git wget jq curl -y 

    # Call the uni_menu function to display the menu
    master
}



# Function to create a folder and download the file
setup_node() {
    # Define the folder name
    NODE_DIR="/root/multiple"

    # Create the folder if it doesn't exist
    if [ ! -d "$NODE_DIR" ]; then
        echo "Creating directory $NODE_DIR"
        mkdir -p "$NODE_DIR"
    fi

    # Change to the node's directory
    cd "$NODE_DIR" || exit

    # Download the file
    FILE_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
    echo "Downloading file from $FILE_URL"
    wget "$FILE_URL" -O "multipleforlinux.tar"

    tar -xvf multipleforlinux.tar

    # Call the uni_menu function to display the menu
    master
}



# Function to set up the node
node_setup() {
    # Define the paths for `multiple-cli` and `multiple-node`
    NODE_PATH="/root/multiple/multipleforlinux"
    CLI_PATH="/root/multiple/multipleforlinux/multiple-cli"
    NODE_EXEC_PATH="/root/multiple/multipleforlinux/multiple-node"

    print_info "Please wait ..."
    sleep 1 # wait 1 second

    # Grant execute permissions to the `multiple-cli` file
    if [ -f "$CLI_PATH" ]; then
        echo "Granting execute permissions to $CLI_PATH"
        chmod +x "$CLI_PATH"
    else
        echo "File $CLI_PATH does not exist. Please check the path and try again."
    fi

    print_info "Please wait ..."
    sleep 1 # wait 1 second

    # Grant execute permissions to the `multiple-node` file
    if [ -f "$NODE_EXEC_PATH" ]; then
        echo "Granting execute permissions to $NODE_EXEC_PATH"
        chmod +x "$NODE_EXEC_PATH"
    else
        echo "File $NODE_EXEC_PATH does not exist. Please check the path and try again."
    fi

    print_info "Please wait ..."
    sleep 1 # wait 1 second

    # Add `multiple-cli` to PATH
    echo "Adding $NODE_PATH to PATH in /etc/profile"
    echo "PATH=\$PATH:$NODE_PATH" >> /etc/profile

    # Save and apply the changes
    source /etc/profile
    echo "Updated PATH: $PATH"

    print_info "Please wait ..."
    sleep 1 # wait 1 second

    # Change permissions recursively for the folder
    echo "Setting 777 permissions for /root/multiple/multipleforlinux"
    chmod -R 777 /root/multiple/multipleforlinux

    # Call the uni_menu function to display the menu
    master
}




service_node() {
    NODE_PATH="/root/multiple/multipleforlinux/multiple-node"
    LOG_FILE="/root/multiple/multipleforlinux/output.log"

    # Check if the multiple-node executable exists
    if [ -f "$NODE_PATH" ]; then
        echo "Starting the multiple-node..."
        
        # Run the node in the background
        nohup "$NODE_PATH" > "$LOG_FILE" 2>&1 &
        
        # Notify the user
        echo "multiple-node started successfully."
        echo "Logs are being written to $LOG_FILE"
    else
        echo "Error: $NODE_PATH does not exist. Please check the path and ensure the node is set up correctly."
        exit 1
    fi

    # Call the uni_menu function to display the menu
    master
}


account_bind() {
    # Define the path for the working directory and acc.txt file
    WORKING_DIR="/root/multiple/multipleforlinux"
    ACC_FILE="$WORKING_DIR/acc.txt"

    # Ensure the script starts in the working directory
    echo "Changing to working directory: $WORKING_DIR"
    cd "$WORKING_DIR" || { echo "Error: Unable to access $WORKING_DIR. Please check if it exists."; exit 1; }

    print_info "Please wait ..."
    sleep 1 # wait 1 second
    # Create the acc.txt file (if it doesn't exist) and make sure it's empty
    echo "Creating $ACC_FILE..."
    > "$ACC_FILE"  # Clears the file if it exists or creates it if it doesn't

    # Prompt user for identifier and PIN
    echo "Enter your account identifier:"
    read YOUR_IDENTIFIER
    echo "Enter your 6-digit PIN:"
    read YOUR_PIN

    # Save identifier and PIN to acc.txt
    echo "Saving account details to $ACC_FILE..."
    echo "Identifier: $YOUR_IDENTIFIER" >> "$ACC_FILE"
    echo "PIN: $YOUR_PIN" >> "$ACC_FILE"

    echo "Account details saved successfully to $ACC_FILE"

    print_info "Please wait ..."
    sleep 1 # wait 1 second
    # Run the bind command with user input
    echo "Binding the account using multiple-cli..."
    ./multiple-cli bind --bandwidth-download 100 --identifier "$YOUR_IDENTIFIER" --pin "$YOUR_PIN" --storage 2000 --bandwidth-upload 100

    # Check if the binding was successful
    if [ $? -eq 0 ]; then
        echo "Account successfully bound!"
    else
        echo "Error: Failed to bind the account. Check the details and try again."
    fi

    # Call the uni_menu function to display the menu
    master
}



start_node() {
    # Run the start command to start the node service
    echo "Starting the node..."
    /root/multiple/multipleforlinux/multiple-cli start

    # Check if the start command ran successfully
    if [ $? -eq 0 ]; then
        echo "Node started successfully."
    else
        echo "Error: Failed to start the node. Check for any issues."
    fi
    
    # Call the uni_menu function to display the menu
    master
}




node_status() {
    # Run the status command to check the node status
    echo "Fetching node status..."
    /root/multiple/multipleforlinux/multiple-cli status

    # Check if the status command ran successfully
    if [ $? -eq 0 ]; then
        echo "Node status fetched successfully."
    else
        echo "Error: Failed to fetch node status. Check if the node is running."
    fi

    # Call the uni_menu function to display the menu
    master
}



logs() {
    # Run the history command to fetch the node's logs
    echo "Fetching node logs..."
    /root/multiple/multipleforlinux/multiple-cli history

    # Check if the history command ran successfully
    if [ $? -eq 0 ]; then
        echo "Node logs fetched successfully."
    else
        echo "Error: Failed to fetch node logs."
    fi

    # Call the uni_menu function to display the menu
    master
}



node_stop() {
    # Run the stop command to stop the node service
    echo "Stopping the node..."
    /root/multiple/multipleforlinux/multiple-cli stop

    # Check if the stop command ran successfully
    if [ $? -eq 0 ]; then
        echo "Node stopped successfully."
    else
        echo "Error: Failed to stop the node. Check if the node is running."
    fi

    # Call the uni_menu function to display the menu
    master
}



# Function to display menu and prompt user for input
master() {
    print_info "==============================="
    print_info "  Multiple Node Tool Menu      "
    print_info "==============================="
    print_info "1. Install-Dependency"
    print_info "2. Setup-Multiple"
    print_info "3. Node-Setup"
    print_info "4. Service-Start"
    print_info "5. Bind-Node"
    print_info "6. Start-Node"
    print_info "7. Node-Status"
    print_info "8. Check-Logs"
    print_info "9. Stop-Node"
    print_info "10. Exit"
    
    read -p "Enter your choice (1 or 10): " user_choice

    case $user_choice in
        1)
            install_dependency
            ;;
        2)
            setup_node
            ;;
        3) 
            node_setup
            ;;
        4)
            service_node
            ;;
        5)
            account_bind
            ;;
        6)
            start_node
            ;;
        7)
            node_status
            ;;
        8)
            logs
            ;;
        9)
            node_stop
            ;;
        10)
            exit 0  # Exit the script after breaking the loop
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 10 : "
            ;;
    esac
}

# Call the uni_menu function to display the menu
master_fun
master
