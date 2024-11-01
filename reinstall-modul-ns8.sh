#!/bin/bash

# Function to check if NS8 is installed
check_ns8_installation() {
    if [ ! -f "/etc/nethserver/api-cli-credentials" ]; then
        echo "NS8 not found. Installing NS8..."
        # Install NS8
        curl -fsSL https://raw.githubusercontent.com/NethServer/ns8-core/ns8-stable/core/install.sh | bash
        
        # Wait for installation to complete and services to start
        echo "Waiting for NS8 services to initialize..."
        sleep 30
        
        # Check again for credentials
        if [ ! -f "/etc/nethserver/api-cli-credentials" ]; then
            echo "NS8 installation failed. Please check your internet connection and try again."
            exit 1
        fi
        
        echo "NS8 installed successfully!"
    else
        echo "NS8 installation found."
    fi
}

# Set correct PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# First check and install NS8 if needed
check_ns8_installation

# Source NS8 environment
source /etc/nethserver/api-cli-credentials

# Function to reinstall a module
reinstall_module() {
    local module=$1
    local instance="${module}1"
    
    echo "Reinstalling $module module..."
    
    # Check if module exists
    if api-cli run module/$instance/get-status &>/dev/null; then
        echo "Found existing $module installation. Removing..."
        
        # Stop the module first
        api-cli run module/$instance/stop-module
        
        # Remove the module
        remove-module --no-preserve $instance
        
        echo "$module removed successfully"
    fi
    
    # Install the module again
    echo "Installing new $module instance..."
    add-module $module
    
    # Return success
    return 0
}

# Function to configure Traefik
configure_traefik() {
    read -p "Enter your domain (e.g., example.com): " DOMAIN
    
    echo "Configuring Traefik..."
    api-cli run module/traefik1/configure-module --data '{
        "host": "'$DOMAIN'",
        "http2https": true,
        "lets_encrypt": true,
        "testing_le": false
    }'
}

# Main menu
while true; do
    echo ""
    echo "NS8 Module Management"
    echo "--------------------"
    echo "1) Install/Reinstall Traefik"
    echo "2) Install/Reinstall Samba"
    echo "3) Install/Reinstall Nextcloud"
    echo "4) Install/Reinstall Mail"
    echo "5) Install/Reinstall Dokuwiki"
    echo "6) Install/Reinstall All modules"
    echo "7) Exit"
    
    read -p "Enter your choice (1-7): " choice
    
    case $choice in
        1)
            reinstall_module traefik
            configure_traefik
            api-cli run module/traefik1/start-module
            ;;
        2)
            reinstall_module samba
            api-cli run module/samba1/start-module
            ;;
        3)
            reinstall_module nextcloud
            api-cli run module/nextcloud1/start-module
            ;;
        4)
            reinstall_module mail
            api-cli run module/mail1/start-module
            ;;
        5)
            reinstall_module dokuwiki
            api-cli run module/dokuwiki1/start-module
            ;;
        6)
            echo "Installing/Reinstalling all modules..."
            reinstall_module traefik
            reinstall_module samba
            reinstall_module nextcloud
            reinstall_module mail
            reinstall_module dokuwiki
            
            # Configure and start all services
            configure_traefik
            api-cli run module/traefik1/start-module
            api-cli run module/samba1/start-module
            api-cli run module/nextcloud1/start-module
            api-cli run module/mail1/start-module
            api-cli run module/dokuwiki1/start-module
            ;;
        7)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1-7."
            ;;
    esac
done
