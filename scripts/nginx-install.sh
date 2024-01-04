#!/bin/bash
# This script installs nginx on Debian

# Function to check if NGINX is installed, and install if missing
check_nginx() {
    if ! command -v nginx &> /dev/null; then
        report_status "NGINX is not installed. Attempting to install NGINX..."

        # Check if the system uses apt (Debian-based systems)
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y nginx
            report_status "changing home perms for nginx"
            chmod og+x "${HOME}"
        else
            # Add additional package managers and commands for other systems as needed
            report_status "Unsupported package manager. Please install NGINX manually and run the script again."
            exit 1
        fi

        # Check again after attempting installation
        if ! command -v nginx &> /dev/null; then
            report_status "Failed to install NGINX. Please install NGINX manually and run the script again."
            exit 1
        fi
    fi
}

# Helper functions
report_status() {
    printf "\n\n###### %s\n" "$1"
}

verify_ready() {
    if [ "$EUID" -eq 0 ]; then
        report_status "This script must not run as root"
        exit -1
    fi
}

nginx_install() {
verify_ready
check_nginx
}
