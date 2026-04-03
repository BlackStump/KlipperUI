#!/bin/bash
# This script installs Katapult on Debian

# Constants

# Helper functions
report_status() {
    printf "\n\n###### %s\n" "$1"
}

verify_ready() {
    if [ "$EUID" -eq 0 ]; then
        report_status "This script must not run as root"
        exit 1
    fi
}

install_katapult() {
    report_status "Installing Katapult..."
    KATAPULT_DIR=~/katapult

    # Check if the Katapult directory exists
    if [ ! -d "$KATAPULT_DIR" ]; then
        report_status "Cloning Katapult..."
        cd ~/
        git clone https://github.com/Arksine/katapult.git
        report_status "Katapult installed."
    else
        # Directory exists — check if service is installed
    if [ -e "$KATAPULT_DIR" ]; then
        report_status "Katapult is already exists. Skipping Git Clone."
        
    fi
}

katapult_install() {
    verify_ready
    install_katapult
}

