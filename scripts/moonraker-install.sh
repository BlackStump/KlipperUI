#!/bin/bash
# This script installs Moonraker on Debian

# Constants
SYSTEMDDIR="/etc/systemd/system"

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

install_moonraker() {
    report_status "Installing Moonraker..."
    MOONRAKER_DIR=~/moonraker

    # Check if the Moonraker directory exists
    if [ ! -d "$MOONRAKER_DIR" ]; then
        report_status "Cloning Moonraker..."
        cd ~/
        git clone https://github.com/Arksine/moonraker.git
        ${HOME}/moonraker/scripts/install-moonraker.sh -f -s
        report_status "Moonraker installed."
    else
        # Directory exists — check if service is installed
        if [ -e "$SYSTEMDDIR/moonraker.service" ]; then
            report_status "Moonraker is already installed. Skipping installation."
        else
            report_status "Existing Moonraker directory found, but it doesn't appear to be installed. Reinstalling..."
            cd ~/
            ${HOME}/moonraker/scripts/install-moonraker.sh -f -s
            report_status "Moonraker reinstalled."
        fi
    fi
}

moonraker_install() {
    verify_ready
    install_moonraker
}

moonraker_install
