#!/bin/bash
# This script installs Klipper on Debian
# Install Klipper-mcu startup script
# Constants
SYSTEMDDIR="/etc/systemd/system"

install_can_service() {
    echo "Installing CAN system start script..."

    # Check if the Klipper service file already exists
    if [ -e "$SYSTEMDDIR/systemd-networkd.service" ]; then
        echo "Networkd service already installed. Skipping installation."
        return
    fi
    sudo systemctl enable systemd-networkd
    sudo systemctl start systemd-networkd
    sudo systemctl disable systemd-networkd-wait-online.service
    echo -e 'SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*"  ATTR{tx_queue_len}="128"' | sudo tee /etc/udev/rules.d/10-can.rules > /dev/null
    echo -e "[Match]\nName=can*\n\n[CAN]\nBitRate=1M\n\n[Link]\nRequiredForOnline=no" | sudo tee /etc/systemd/network/25-can.network > /dev/null
}

install_can_service
