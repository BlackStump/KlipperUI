#!/bin/bash
# This script installs Katapult on Debian

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
        # Directory exists — skip clone
        report_status "Katapult already exists. Skipping Git Clone."
    fi  # <-- this was missing entirely
}

katapult_install() {
    verify_ready
    install_katapult
}
