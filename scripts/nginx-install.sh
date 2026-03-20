#!/bin/bash
# This script installs nginx on Debian

# Helper functions
report_status() {
    printf "\n\n###### %s\n" "$1"
}

verify_ready() {
    if [ "$EUID" -eq 0 ]; then
        report_status "This script must not run as root"
        exit 1
    fi
    # Check sudo access upfront
    if ! sudo -v &> /dev/null; then
        report_status "This script requires sudo privileges. Please run as a user with sudo access."
        exit 1
    fi
}

check_nginx() {
    if ! command -v nginx &> /dev/null && ! [ -f /usr/sbin/nginx ]; then
        report_status "NGINX is not installed. Attempting to install NGINX..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y nginx
            report_status "Changing home perms for nginx"
            chmod og+x "${HOME}"
        else
            report_status "Unsupported package manager. Please install NGINX manually and run the script again."
            exit 1
        fi
        if ! command -v nginx &> /dev/null && ! [ -f /usr/sbin/nginx ]; then
            report_status "Failed to install NGINX. Please install NGINX manually and run the script again."
            exit 1
        fi
    fi
}

nginx_install() {
    verify_ready
    check_nginx
}
