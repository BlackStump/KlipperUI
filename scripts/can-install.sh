#!/bin/bash
# This script installs CAN on Debian

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

# Install CAN Service
install_can_service() {
    report_status "Installing CAN system start script..."

    sudo systemctl enable systemd-networkd
    sudo systemctl start systemd-networkd
    sudo systemctl disable systemd-networkd-wait-online.service

    report_status "Installing CAN udev rules..."
    echo -e 'SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*"  ATTR{tx_queue_len}="128"' \
        | sudo tee /etc/udev/rules.d/10-can.rules > /dev/null

    report_status "Installing CAN network config..."
    echo -e "[Match]\nName=can*\n\n[CAN]\nBitRate=1M\n\n[Link]\nRequiredForOnline=no" \
        | sudo tee /etc/systemd/network/25-can.network > /dev/null

    report_status "CAN installation complete."
}

can_install() {
    verify_ready
    install_can_service
}

