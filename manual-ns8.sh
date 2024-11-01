#!/bin/bash

# Enable error handling
set -e

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check system requirements
check_requirements() {
    log_message "Checking system requirements..."
    
    # Check systemd
    if ! systemctl status >/dev/null 2>&1; then
        log_message "Error: systemd is not running properly"
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_message "Error: No internet connection"
        exit 1
    fi
    
    # Check available memory
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ $total_mem -lt 2048 ]; then
        log_message "Warning: System has less than 2GB RAM"
    fi
}

# Function to prepare system
prepare_system() {
    log_message "Preparing system..."
    
    # Restart critical services
    systemctl restart systemd-dbus
    systemctl restart systemd-resolved
    
    # Clear systemd journals if they're too large
    journalctl --vacuum-time=1d
    
    # Wait for services to stabilize
    sleep 5
}

# Function to install NS8
install_ns8() {
    log_message "Starting NS8 installation..."
    
    # Download NS8 installer
    curl -fsSL https://raw.githubusercontent.com/NethServer/ns8-core/ns8-stable/core/install.sh -o ns8-install.sh
    
    # Make it executable
    chmod +x ns8-install.sh
    
    # Run installer with debug output
    ./ns8-install.sh --debug
    
    # Wait for services to initialize
    log_message "Waiting for NS8 services to initialize..."
    sleep 45
    
    # Check if installation was successful
    if [ -f "/etc/nethserver/api-cli-credentials" ]; then
        log_message "NS8 installation completed successfully"
    else
        log_message "NS8 installation failed"
        exit 1
    fi
}

# Main execution
log_message "Starting NS8 manual installation process..."

# Run steps
check_requirements
prepare_system
install_ns8

log_message "Installation process completed"

# Final checks
if systemctl is-active --quiet api-server; then
    log_message "NS8 API server is running"
else
    log_message "Warning: NS8 API server is not running"
fi

if [ -f "/etc/nethserver/api-cli-credentials" ]; then
    log_message "NS8 credentials file exists"
else
    log_message "Warning: NS8 credentials file is missing"
fi

echo "==================================="
echo "If installation was successful, you can proceed with module installation"
echo "If you see any warnings above, please fix them before proceeding"
echo "==================================="
