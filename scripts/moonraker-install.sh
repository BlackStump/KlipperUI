#!/bin/bash
# This script installs Mooraker on Debian

SYSTEMDIR="/etc/systemd/system"

install_moonraker() {
    report_status "Installing Moonraker..."
    MOONRAKER_DIR=~/moonraker

    # Check if the Moonraker directory exists
    if [ ! -d "$MOONRAKER_DIR" ]; then
        # If not, clone the Moonraker repository
        report_status "Cloning Moonraker..."
        cd ~/
        git clone https://github.com/Arksine/moonraker.git

        # Run the installation script
        ${HOME}/moonraker/scripts/install-moonraker.sh -f -s

        report_status "Moonraker installed."
    else
        # If the directory exists, check for the moonraker.service file
        if [ -e "$SYSTEMDIR/moonraker.service" ]; then
            report_status "Moonraker is already installed. Skipping installation."
        else
            report_status "Existing Moonraker directory found, but it doesn't appear to be installed. Reinstalling..."
            # Re-run the installation script
            cd ~/
            ${HOME}/moonraker/scripts/install-moonraker.sh -f -s
            report_status "Moonraker reinstalled."
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

moonraker_install() {
    verify_ready
    install_moonraker
}
